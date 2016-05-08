package Alambic::Model::Alambic;

use warnings;
use strict;

use Alambic::Model::Config;
use Alambic::Model::Project;
use Alambic::Model::RepoDB;
use Alambic::Model::RepoFS;
use Alambic::Model::Plugins;

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
                     get_repo_db
                     create_project
                     get_project
                     get_projects_list
                     run_project
                     delete_project
                   );  

my $config;
my $repodb;
my $repofs;
my $plugins;

# Create a new Alambic object.
sub new { 
    my ($class, $config_opt) = @_;

    $config = Alambic::Model::Config->new($config_opt);
    my $pg_alambic = $config->get_pg_alambic();
    $repodb = Alambic::Model::RepoDB->new($pg_alambic);
    $repofs = Alambic::Model::RepoFS->new();
    $plugins = Alambic::Model::Plugins->new();
    
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
	$config->set_name($name);
    }

    return $config->get_name();
}

# Get or set the instance description.
sub instance_desc($) {
    my ($self, $desc) = @_;
    
    if (scalar @_ > 1) {
	$config->set_desc($desc);
    }

    return $config->get_desc();
}

# Get the postgresql configuration for alambic.
sub instance_pg_alambic() {
    return $config->get_pg_alambic();
}

# Get the postgresql configuration for minion.
sub instance_pg_minion() {
    return $config->get_pg_minion();
}

# Get boolean to check if the alambic db can be used.
sub is_db_ok() {
    return $repodb->is_db_ok();
}

# Get boolean to check if the minion db information is defined.
sub is_db_m_ok() {
    my $pg_minion = $config->get_pg_minion();
    return ( defined($pg_minion) && $pg_minion =~ m!^postgres! ) ? 1 : 0;
}


# Return the Plugins.pm object for this instance.
sub get_plugins() {
    return $plugins;
}


# Return the RepoDB.pm object for this instance.
sub get_repo_db() {
    return $repodb;
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
    # $ret == 2 means the insert did work.
    if ( $ret == 0 ) {
	return 0;
    }

    my $project = Alambic::Model::Project->new($id, $name);
    $project->desc($desc);
    $project->active($active);

    return $project;
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


# Get a pointer to the project identified by its id.
sub _get_project($) {
    my ($id) = @_;

    my $project_conf = $repodb->get_project_conf($id);

    if (not defined($project_conf)) { return undef }
    
    my $project_data = $repodb->get_project_last_run($id);
    
    my $project = Alambic::Model::Project->new( $id, $project_conf->{'name'}, 
						$project_conf->{'plugins'}, 
						$project_data );
    $project->active( $project_conf->{'is_active'} );
    
    return $project;
}


# Get a hash ref of all project ids with their names.
#
# Params
#  - id the project id.
# Returns
#  - $projects = {
#      "modeling.sirius" => "Sirius",
#      "tools.cdt" => "CDT",
#    }
sub get_projects_list() {

    my $projects_list = {};
    if ( $repodb->is_db_ok() ) {
	$projects_list = $repodb->get_projects_list();
    }
    
    return $projects_list;
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
#      "recs" => {'rec1' => 'value1'},
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
    my $values = $project->run_plugins();
    
    my $ret = $repodb->add_project_run($project_id, $run, 
			     $values->{'metrics'}, 
			     $values->{'indicators'}, 
			     $values->{'attributes'}, 
			     $values->{'recs'});

    return $ret;
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
