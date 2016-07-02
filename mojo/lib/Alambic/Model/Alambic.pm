package Alambic::Model::Alambic;

use warnings;
use strict;

use Alambic::Model::Project;
use Alambic::Model::RepoDB;
use Alambic::Model::RepoFS;
use Alambic::Model::Plugins;
use Alambic::Model::Wizards;
use Alambic::Model::Models;

use Mojo::JSON qw (decode_json encode_json);
use Data::Dumper;
use POSIX;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw( 
                     init
                     backup
                     restore
                     instance_name
                     instance_desc
                     instance_pg_alambic
                     instance_pg_minion
                     is_db_ok
                     is_db_m_ok
                     get_plugins
                     get_models
                     get_repo_db
                     get_wizards
                     create_project
                     get_project
                     get_projects_list
                     add_project_plugin
                     del_project_plugin
                     get_project_hist
                     get_project_last_run
                     get_project_run
                     run_project
                     run_plugins
                     run_qm
                     run_posts
                     run_globals
                     delete_project
                   );  

my $config;
my $repodb;
my $repofs;
my $plugins;
my $wizards;
my $models;


# Create a new Alambic object.
sub new { 
    my ($class, $config_opt) = @_;

    $config = $config_opt;
    my $pg_alambic = $config->{'conf_pg_alambic'};
    $repodb = Alambic::Model::RepoDB->new($pg_alambic);
    $repofs = Alambic::Model::RepoFS->new();
    $plugins = Alambic::Model::Plugins->new();
    $wizards = Alambic::Model::Wizards->new();

    # If the database is not initialised, then init it.
    if (not &is_db_ok()) { 
	print "### ###################\n";
	print "### &init( ! \n";
	print "### ###################\n";
	&init();
    }
	
    # Retrieve all metrics definition to initialise Models.pm
    my $metrics = $repodb->get_metrics();
    my $attributes = $repodb->get_attributes();
    my $qm = $repodb->get_qm();
    $models = Alambic::Model::Models->new($metrics, $attributes, $qm, $plugins->get_conf_all());
    
    return bless {}, $class;
}


# Deletes and re-creates tables in the database.
# Use with caution.
sub init() {
    $repodb->init_db();
}


# Creates a backup of the Alambic DB
sub backup() {
    return $repodb->backup_db();
}


# Restore a backup into the Alambic DB
sub restore($) {
    my ($self, $file_sql) = @_;
    
    $repodb->restore_db($file_sql);
}


# Get or set the instance name.
sub instance_name($) {
    my ($self, $name) = @_;
    
    if (scalar @_ > 1) {
	$repodb->name($name);
    }

    return $repodb->name();
}

# Get or set the instance description.
sub instance_desc($) {
    my ($self, $desc) = @_;
    
    if (scalar @_ > 1) {
	$repodb->desc($desc);
    }

    return $repodb->desc();
}

# Get the postgresql configuration for alambic.
sub instance_pg_alambic() {
    return $config->{'conf_pg_alambic'};
}

# Get the postgresql configuration for minion.
sub instance_pg_minion() {
    return $config->{'conf_pg_minion'};
}

# Get boolean to check if the alambic db can be used.
sub is_db_ok() {
    return $repodb->is_db_ok();
}

# Get boolean to check if the minion db information is defined.
sub is_db_m_ok() {
    my $pg_minion = $config->{'conf_pg_minion'};
    return ( defined($pg_minion) && $pg_minion =~ m!^postgres! ) ? 1 : 0;
}


# Return the Plugins.pm object for this instance.
sub get_plugins() {
    return $plugins;
}


# Return the Models.pm object for this instance.
sub get_models() {
    return $models;
}


# Return the RepoDB.pm object for this instance.
sub get_repo_db() {
    return $repodb;
}

# Return the RepoDB.pm object for this instance.
sub get_wizards() {
    return $wizards;
}


# Create a project with no plugin.
#
# Params
#  - id the project id.
#  - name the name of the project.
#  - desc the description of the project.
#  - active boolean (TRUE|FALSE) is the project active.
# Returns
#  - Project object.
sub create_project($$) {
    my $self = shift;
    my $id = shift;
    my $name = shift;
    my $desc = shift;
    my $active = shift || 0;

    my $ret = $repodb->set_project_conf( $id, $name, $desc, $active, {} );
    # $ret == 0 means the insert didn't work.
    if ( $ret == 0 ) {
	return 0;
    }

    my $project = Alambic::Model::Project->new( $id, $name );
    $project->desc($desc);
    $project->active($active);

    return $project;
}


# Create a project from a wizard.
#
# Params
#  - wizard the wizard id.
#  - id the project id.
# Returns
#  - Project object.
sub create_project_from_wizard($$) {
    my $self = shift;
    my $wiz_id = shift;
    my $project_id = shift;
    my $conf = shift;
    
    my $ret_wiz = $wizards->get_wizard($wiz_id)->run_wizard($project_id, $conf);
    my $project = $ret_wiz->{'project'};
    
    my $ret = $repodb->set_project_conf( $project_id, $project->name(), $project->desc(), 0, $project->get_plugins() );
    # $ret == 0 means the insert didn't work.
    if ( $ret == 0 ) {
	return undef;
    }

    return $ret_wiz;
}


# Get a Project object from its id.
# The project is populated with data (metrics, attributes, recs) 
# if available.
#
# Params
#  - id the id of the project to be retrieved.
sub get_project($) {
    my ($self, $project_id) = @_;
    return &_get_project($project_id);
}


# set properties of a project from its id.
#
# Params
#  - id the id of the project to be set.
#  - name the name of the project to be set.
#  - desc the desc of the project to be set.
#  - active the is_active flag of the project to be set.
#  - plugins the plugins conf of the project to be set.
sub set_project($) {
    my $self = shift;
    my $project_id = shift || '';
    my $name = shift || '';
    my $desc = shift || '';
    my $active = shift || '';
    my $plugins = shift || {};

    my $project = $repodb->get_project_conf($project_id);
    
    if ($name !~ m!^$!) { $project->{'name'} = $name }
    if ($desc !~ m!^$!) { $project->{'desc'} = $desc }
    if ($active !~ m!^$!) { $project->{'active'} = $active }
    if (ref($plugins) =~ m!^HASH$! && scalar keys %$plugins > 1) { $project->{'plugins'} = $plugins }

    $repodb->set_project_conf( $project_id, $project->{'name'}, 
			       $project->{'desc'}, $project->{'active'}, 
			       $project->{'plugins'});
}


# Get a pointer to the project identified by its id.
sub _get_project($) {
    my ($id) = @_;

    my $project_conf = $repodb->get_project_conf($id);
    if (not defined($project_conf)) { return undef }
    
    my $project_data = $repodb->get_project_last_run($id);

    my $project = Alambic::Model::Project->new( $id, $project_conf->{'name'},
						$project_conf->{'is_active'}, 
						$project_conf->{'last_run'},
						$project_conf->{'plugins'}, 
						$project_data );
    $project->desc( $project_conf->{'desc'} );
    
    return $project;
}


# Get a hash ref of all project ids with their names.
#
# Params
#  - is_active (1|0) list only active projects?
# Returns
#  - $projects = {
#      "modeling.sirius" => "Sirius",
#      "tools.cdt" => "CDT",
#    }
sub get_projects_list() {
    my $self = shift;
    my $is_active = shift || '';
    
    my $projects_list = {};
    if ( $repodb->is_db_ok() ) {
	if ($is_active) {
	    $projects_list = $repodb->get_active_projects_list();
	} else {
	    $projects_list = $repodb->get_projects_list();
	}
    }
    
    return $projects_list;
}


# Add or set a plugin to the project configuration.
#
# Params
#  - project_id the project id.
#  - plugin_id the plugin id.
#  - plugin_conf a hash ref for the plugin configuration.
sub add_project_plugin() {
    my ($self, $project_id, $plugin_id, $project_conf) = @_;

    my $conf = $repodb->get_project_conf($project_id);

    # Add plugin conf to the hash of all plugins conf
    $conf->{'plugins'}->{$plugin_id} = $project_conf;

    $repodb->set_project_conf($project_id, 
			      $conf->{'name'}, 
			      $conf->{'desc'}, 
			      $conf->{'is_active'},
			      $conf->{'plugins'});
    
    return 1;
}


# Delete a plugin from the project configuration.
#
# Params
#  - project_id the project id.
#  - plugin_id the plugin id.
sub del_project_plugin() {
    my ($self, $project_id, $plugin_id) = @_;

    my $conf = $repodb->get_project_conf($project_id);

    # Add plugin conf to the hash of all plugins conf
    delete $conf->{'plugins'}->{$plugin_id};

    $repodb->set_project_conf($project_id, 
			      $conf->{'name'}, 
			      $conf->{'desc'}, 
			      $conf->{'is_active'},
			      $conf->{'plugins'});
    
    return 1;
}


sub get_project_hist($) {
    my $self = shift;
    my $project_id = shift;

    return $repodb->get_project_all_runs($project_id);
    
}

sub get_project_last_run($) {
    my $self = shift;
    my $project_id = shift;

    return $repodb->get_project_last_run($project_id);
}

sub get_project_run($$) {
    my $self = shift;
    my $project_id = shift;
    my $run_id = shift;

    return $repodb->get_project_run($project_id, $run_id);
}


# Run a full analysis on a project: plugins, qm, post plugins.
#
# Params
#  - id the project id.
# Returns
#  - $ret = {
#      "metrics" => {'metric1' => 'value1'},
#      "indicators" => {'ind1' => 'value1'},
#      "attributes" => {'attr1' => 'value1'},
#      "attributes_conf" => {'attr1' => 'value1'},
#      "infos" => {'info1' => 'value1'},
#      "recs" => ['rec1' => 'value1'],
#      "log" => ['log entry'],
#    }
sub run_project($) {
    my ($self, $project_id) = @_;

    my $time_start = time;
    my $run = {
	'timestamp' => strftime( "%Y-%m-%d %H:%M:%S\n", localtime($time_start) ),
	'delay' => 0,
	'user' => 'none',
    };

    my $project = &_get_project($project_id);
    my $values = $project->run_project($models);
    
    my $ret = $repodb->add_project_run($project_id, $run,
			     $values->{'info'}, 
			     $values->{'metrics'}, 
			     $values->{'inds'}, 
			     $values->{'attrs'}, 
			     $values->{'attrs_conf'}, 
			     $values->{'recs'});

    return $values;
}


# Run a full analysis on a project: plugins, qm, post plugins.
#
# Params
#  - id the project id.
# Returns
#  - $ret = {
#      "cdata" => [ {'author' => 'so', 'mesg' => 'value1'} ],
#      "metrics" => {'metric1' => 'value1'},
#      "indicators" => {'ind1' => 'value1'},
#      "attributes" => {'attr1' => 'value1'},
#      "attributes_conf" => {'attr1' => 'value1'},
#      "infos" => {'info1' => 'value1'},
#      "recs" => ['rec1' => 'value1'],
#      "log" => ['log entry'],
#    }
sub run_plugins($) {
    my ($self, $project_id) = @_;

    my $time_start = time;
    my $run = {
	'timestamp' => strftime( "%Y-%m-%d %H:%M:%S\n", localtime($time_start) ),
	'delay' => 0,
	'user' => 'none',
    };

    my $project = &_get_project($project_id);
    my $values = $project->run_plugins();

    return $values;
}


# Compute indicators and populate the quality model.
#
# Params
#  - id the project id.
# Returns
#  - $ret = {
#      "metrics" => {'metric1' => 'value1'},
#      "indicators" => {'ind1' => 'value1'},
#      "attributes" => {'attr1' => 'value1'},
#      "attributes_conf" => {'attr1' => 'value1'},
#      "log" => ['log entry'],
#    }
sub run_qm($) {
    my ($self, $project_id) = @_;

    my $time_start = time;
    my $run = {
	'timestamp' => strftime( "%Y-%m-%d %H:%M:%S\n", localtime($time_start) ),
	'delay' => 0,
	'user' => 'none',
    };

    my $project = &_get_project($project_id);
    my $values = $project->run_qm($models);
    return $values;
}


# Run all post plugins for the project.
#
# Params
#  - id the project id.
# Returns
#  - $ret = {
#      "metrics" => {'metric1' => 'value1'},
#      "indicators" => {'ind1' => 'value1'},
#      "attributes" => {'attr1' => 'value1'},
#      "attributes_conf" => {'attr1' => 'value1'},
#      "infos" => {'info1' => 'value1'},
#      "recs" => ['rec1' => 'value1'],
#      "log" => ['log entry'],
#    }
sub run_posts($) {
    my ($self, $project_id) = @_;

    my $time_start = time;
    my $run = {
	'timestamp' => strftime( "%Y-%m-%d %H:%M:%S\n", localtime($time_start) ),
	'delay' => 0,
	'user' => 'none',
    };

    my $project = &_get_project($project_id);
    my $values = $project->run_posts($models);

    return $values;
}


sub run_globals() {

}


sub delete_project($) {
    my ($self, $project_id) = @_;

    $repodb->delete_project($project_id);
    $repofs->delete_project($project_id);

    return 1;
}


1;
