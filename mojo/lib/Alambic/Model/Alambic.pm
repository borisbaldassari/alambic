package Alambic::Model::Alambic;

use warnings;
use strict;

#use Alambic::Model::Config;
use Alambic::Model::Project;
use Alambic::Model::RepoDB;

use Mojo::JSON qw (decode_json encode_json);
use Data::Dumper;
use POSIX;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw( 
                     create_project
                     run_project
                   );  

#my $config;
my $repodb;

# Create a new Alambic object.
sub new { 
    my ($class, $args) = @_;

#    $config = Alambic::Model::Config->new();
    $repodb = Alambic::Model::RepoDB->new();

    # my $projects_list = $repodb->get_projects_list();
    # foreach my $project (keys %{$projects_list}) {
    # 	my $project = $repodb->get_project_info($project);
    # }
    
    return bless {}, $class;
}

sub init() {
    $repodb->init_db();
}


# Create or set a project with only id and name set.
sub set_project($$) {
    my ($self, $id, $name) = @_;

    my $ret = $repodb->set_project_conf( $id, $name, '', {} );
    # $ret == 2 means the insert did work.
    if ( $ret == 0 ) {
	return 0;
    }

    return Alambic::Model::Project->new($id, $name);
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
    
    return $project;
}


# Get a hash ref of all project ids with their names.
sub get_projects_list() {
    my $projects_list = $repodb->get_projects_list();
    return $projects_list;
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
			     $values->{'questions'}, 
			     $values->{'attributes'}, 
			     $values->{'recs'});

    return $ret;
}



1;
