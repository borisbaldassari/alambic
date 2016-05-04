package Alambic::Model::Alambic;

use warnings;
use strict;

use Alambic::Model::Config;
use Alambic::Model::Project;
use Alambic::Model::RepoDB;
use Alambic::Model::Plugins;

use Mojo::JSON qw (decode_json encode_json);
use Data::Dumper;
use POSIX;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw( 
                     init
                     instance_name
                     instance_desc
                     instance_pg_alambic
                     instance_pg_minion
                     is_db_ok
                     is_db_m_ok
                     get_plugins
                     get_project
                     get_projects_list
                     create_project
                     run_project
                   );  

my $config;
my $repodb;
my $plugins;

# Create a new Alambic object.
sub new { 
    my ($class, $config_opt) = @_;

    $config = Alambic::Model::Config->new($config_opt);
    my $pg_alambic = $config->get_pg_alambic();
    $repodb = Alambic::Model::RepoDB->new($pg_alambic);
    $plugins = Alambic::Model::Plugins->new();
    
    return bless {}, $class;
}


# Deletes and re-creates tables in the database.
# Use with caution.
sub init() {
    $repodb->init_db();
}

sub instance_name($) {
    my ($self, $name) = @_;
    
    if (scalar @_ > 1) {
	$config->set_name($name);
    }

    return $config->get_name();
}

sub instance_desc($) {
    my ($self, $desc) = @_;
    
    if (scalar @_ > 1) {
	$config->set_desc($desc);
    }

    return $config->get_desc();
}

sub instance_pg_alambic() {
    return $config->get_pg_alambic();
}

sub instance_pg_minion() {
    return $config->get_pg_minion();
}

sub is_db_ok() {
    return $repodb->is_db_ok();
}

sub is_db_m_ok() {
    my $pg_minion = $config->get_pg_minion();
    return ( defined($pg_minion) && $pg_minion =~ m!^postgres! ) ? 1 : 0;
}


sub get_plugins() {
    return $plugins;
}

sub get_project($) {
    my ($self, $project_id) = @_;
    return &_get_project($project_id);
}


# Get a pointer to the project identified by its id.
sub _get_project($) {
    my ($id) = @_;

    my $project_conf = $repodb->get_project_conf($id);
    my $project_data = $repodb->get_project_last_run($id);

    my $project = Alambic::Model::Project->new( $id, $project_conf->{'name'}, 
						$project_conf->{'plugins'}, 
						$project_data );
    $project->active( $project_conf->{'is_active'} );
    
    return $project;
}


# Get a hash ref of all project ids with their names.
sub get_projects_list() {

    my $projects_list = {};
    if ( $repodb->is_db_ok() ) {
	$projects_list = $repodb->get_projects_list();
    }
    
    return $projects_list;
}


# Create a project with only id and name set.
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

    return Alambic::Model::Project->new($id, $name);
}

# Run a full analysis on a project: plugins, post plugins, globals.
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



1;
