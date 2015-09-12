package Alambic::Model::Projects;
use Scalar::Util 'weaken';

use Mojo::Base -base;

use Mojo::JSON qw(decode_json encode_json);

use warnings;
use strict;
use Data::Dumper;

my %projects;
my %projects_names;

my %attributes;
my %questions;
my %metrics;


# Constructor
sub new {
  my $class = shift;
  my $app = shift;

  my $hash = {app => $app};
  weaken $hash->{app};
  return bless $hash, $class;
}

sub read_all_files() { 
    my $self = shift;

    $self->{app}->log->debug("[Model::Projects] Creating new Alambic::Model::Projects.pm class.");

    my $config = $self->{app}->config;
    my $models = $self->{app}->models;

    my $dir_data = $config->{'dir_data'};
    
    %attributes = $models->get_attributes();
    %questions = $models->get_questions();
    %metrics = $models->get_metrics();

    # Read metrics for projects
    $self->{app}->log->info( "[Model::Projects] Reading all projects metrics from [$dir_data]." );
    my @projects_metrics = <$dir_data/*/*_metrics.json>;
    foreach my $project (@projects_metrics) {
        $project =~ m!.*[\/](.*?)_metrics.json!;
        my $id = $1;
        my $json_project = &read_project_data($project);
        $projects{$id}{'metrics'} = $json_project->{'children'};
    }

    # Read attributes for projects
    $self->{app}->log->info( "[Model::Projects] Reading all projects attributes from [$dir_data]." );
    my @projects_attrs = <$dir_data/*/*_attributes.json>;
    foreach my $project (@projects_attrs) {
        $project =~ m!.*[\/](.*?)_attributes.json!;
        my $id = $1;
        my $json_project = &read_project_data($project);
        $projects{$id}{'attrs'} = $json_project->{'children'};
    }

    # Read attributes_confidence for projects
    $self->{app}->log->info( "[Model::Projects] Reading all projects attrs_conf from [$dir_data]." );
    my @projects_attrs_conf = <$dir_data/*/*_attributes_confidence.json>;
    foreach my $project (@projects_attrs_conf) {
        $project =~ m!.*[\/](.*?)_attributes_confidence.json!;
        my $id = $1;
        my $json_project = &read_project_data($project);
        $projects{$id}{'attrs_conf'} = $json_project->{'children'};
    }

    # Read questions for projects
    $self->{app}->log->info( "[Model::Projects] Reading all projects questions from [$dir_data]." );
    my @projects_questions = <$dir_data/*/*_questions.json>;
    foreach my $project (@projects_questions) {
        $project =~ m!.*[\/](.*?)_questions.json!;
        my $id = $1;
        my $json_project = &read_project_data($project);
        $projects{$id}{'questions'} = $json_project->{'children'};
    }

    # Read questions_confidence for projects
    $self->{app}->log->info( "[Model::Projects] Reading all projects questions confidence from [$dir_data]." );
    my @projects_questions_conf = <$dir_data/*/*_questions_confidence.json>;
    foreach my $project (@projects_questions_conf) {
        $project =~ m!.*[\/](.*?)_questions_confidence.json!;
        my $id = $1;
        my $json_project = &read_project_data($project);
        $projects{$id}{'questions_conf'} = $json_project->{'children'};
    }

    # Read indicators for projects
    $self->{app}->log->info( "[Model::Projects] Reading all projects indicators from [$dir_data]." );
    my @projects_inds = <$dir_data/*/*_indicators.json>;
    foreach my $project (@projects_inds) {
        $project =~ m!.*[\/](.*?)_indicators.json!;
        my $id = $1;
        my $json_project = &read_project_data($project);
        $projects{$id}{'indicators'} = $json_project->{'children'};
    }

    # Read violations for projects
    $self->{app}->log->info( "[Model::Projects] Reading all projects violations from [$dir_data]." );
    my @projects_probs = <$dir_data/*/*_violations.json>;
    foreach my $project (@projects_probs) {
        $project =~ m!.*[\/](.*?)_violations.json!;
        my $id = $1;
        my $json_project = &read_project_data($project);
        foreach my $rule (@{$json_project->{'children'}}) {
            $projects{$id}{'violations'}{$rule->{'name'}} = $rule;
        }
    }

    # Read PMI info for projects
    $self->{app}->log->info( "[Model::Projects] Reading all projects PMI data from [$dir_data]." );
    my @projects_pmi = <$dir_data/*/*_pmi.json>;
    foreach my $project (@projects_pmi) {
        $project =~ m!.*[\/](.*?)_pmi.json!;
        my $id = $1;
        my $json_project = &read_project_data($project);
        $projects{$id}{'pmi'} = $json_project->{'projects'}->{$id};
        $projects_names{$id} = $json_project->{'projects'}->{$id}->{'title'};
    }

    # Read comments for projects
    $self->{app}->log->info( "[Model::Projects] Reading all projects comments from [$dir_data]." );
    my @projects_comments = <$dir_data/*/*_comments.json>;
    foreach my $project (@projects_comments) {
        $project =~ m!.*[\/](.*?)_comments.json!;
        my $id = $1;
        my $json_project = &read_project_data($project);
        $projects{$id}{'comments'} = $json_project;
    }

}

sub read_project_data($) {
    my $file = shift;

    my $json;
    do { 
        local $/;
        open my $fh, '<', $file or die "Could not open data file [$file].\n";
        $json = <$fh>;
        close $fh;
    };
    my $metrics = decode_json($json);

    return $metrics;
}


# Recursive function to populate the quality model with information from 
# external files (metrics/questions/attributes definition). 
# Params:
#   $qm a ref to an array of children
#   $attrs a ref to hash of values for attributes
#   $questions a ref to hash of values for questions
#   $metrics a ref to hash of values for metrics
#   $inds a ref to hash of indicators for metrics
sub populate_qm($$$$$) {
    my $qm = shift;
    my $l_attrs = shift;
    my $l_questions = shift;
    my $l_metrics = shift;
    my $l_inds = shift;

    foreach my $child (@{$qm}) {
        my $mnemo = $child->{"mnemo"};
        
        if ($child->{"type"} =~ m!attribute!) {
            $child->{"name"} = $attributes{$mnemo}{"name"};
            $child->{"ind"} = $l_attrs->{$mnemo};
        } elsif ($child->{"type"} =~ m!concept!) {
            $child->{"name"} = $questions{$mnemo}{"name"};
            $child->{"ind"} = $l_questions->{$mnemo};
        } elsif ($child->{"type"} =~ m!metric!) {
            $child->{"name"} = $metrics{$mnemo}{"name"};
            $child->{"value"} = eval sprintf("%.1f", $l_metrics->{$mnemo} || 0);
            $child->{"ind"} = $l_inds->{$mnemo};
        } else { 
            print( "[Model::Projects] WARN: cannot recognize type " . $child->{"type"} . "." ); 
        }
        
        if ( exists($child->{"children"}) ) {
            &populate_qm($child->{"children"}, $l_attrs, $l_questions, $l_metrics, $l_inds);
        }
    }
}


sub list_projects() {
    my @projects = keys %projects ;
    return @projects;
}

sub get_all_projects() {
    return %projects;
}

sub get_project_name_by_id($) {
    my $self = shift;
    my $project_id = shift;

    return $projects_names{$project_id};
}

sub get_project_metrics($) {
    my $self = shift;
    my $project_id = shift;

    return $projects{$project_id}{'metrics'};
}

sub get_project_indicators($) {
    my $self = shift;
    my $project_id = shift;

    return $projects{$project_id}{'indicators'};
}

sub get_project_all_values($) {
    my $self = shift;
    my $project_id = shift;

    my %model = $self->{app}->models->get_model();

    # Create a rich version of the quality model with all info on nodes.
    &populate_qm($model{"children"}, $projects{$project_id}{'attrs'}, $projects{$project_id}{'questions'}, $projects{$project_id}{'metrics'}, $projects{$project_id}{'indicators'});

    return %model;
}

sub get_project_attrs($) {
    my $self = shift;
    my $project_id = shift;

    return $projects{$project_id}{'attrs'};
}

sub get_project_attrs_conf($) {
    my $self = shift;
    my $project_id = shift;

    return $projects{$project_id}{'attrs_conf'};
}

sub get_project_questions($) {
    my $self = shift;
    my $project_id = shift;

    return $projects{$project_id}{'questions'};
}

sub get_project_questions_conf($) {
    my $self = shift;
    my $project_id = shift;

    return $projects{$project_id}{'questions_conf'};
}

sub get_project_violations($) {
    my $self = shift;
    my $project_id = shift;

    return $projects{$project_id}{'violations'};
}

sub get_project_pmi($) {
    my $self = shift;
    my $project_id = shift;

    return $projects{$project_id}{'pmi'};
}

sub get_project_comments($) {
    my $self = shift;
    my $project_id = shift;

    return $projects{$project_id}{'comments'};
}


1;
