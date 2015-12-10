package Alambic::Model::Projects;

use Mojo::Base -base;

use Alambic::Model::Analysis;

use Scalar::Util 'weaken';
use Mojo::JSON qw( decode_json encode_json );
use File::Path qw( remove_tree );
use File::Copy;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw( read_all_files
                     read_project_data
                     write_project_data
                     list_projects
                     get_all_projects
                     get_project_info
                     get_project_name_by_id
                     get_project_metrics
                     get_project_metrics_last
                     get_project_indicators
                     get_project_all_values
                     get_project_attrs
                     get_project_attrs_last
                     get_project_attrs_conf
                     get_project_questions
                     get_project_questions_conf
                     get_project_violations
                     get_project_pmi
                     get_project_comments
                     add_project_comment
                     edit_project_comment
                     delete_project_comment
                     retrieve_project_data
                     analyse_project
                     add_project
                     del_project
                     get_project_ds
                     set_project_ds
                     delete_project_ds );  


use warnings;
use strict;
use Data::Dumper;

my %projects;

my %projects_info;

my %attributes;
my %questions;
my %metrics;


# Constructor
sub new {
  my $class = shift;
  my $app = shift;

  my $config = $app->config;
  my $models = $app->models;

  &_read_files($config, $models, $app->log);

  my $hash = {app => $app};
  weaken $hash->{app};
  return bless $hash, $class;
}

sub read_all_files() { 
    my $self = shift;

    $self->{app}->log->debug( "[Model::Projects] Creating new Alambic::Model::Projects.pm class." );
    my $config = $self->{app}->config;
    my $models = $self->{app}->models;

    &_read_files($config, $models, $self->{app}->log);

}

sub _read_files($$) {
    my $config = shift;
    my $models = shift;
    my $log = shift;

    my $dir_data = $config->{'dir_data'};
   

    %attributes = %{$models->get_attributes()};
    %questions = %{$models->get_questions()};
    %metrics = %{$models->get_metrics()};

    # Read info for projects
    $log->info( "[Model::Projects] Reading all projects info from [$dir_data]." );
    my @projects_info = <$dir_data/*/*_info.json>;
    foreach my $project (@projects_info) {
        $project =~ m!.*[\/](.*?)_info.json!;
        my $id = $1;
        my $json_project = &read_project_data($project);
        $projects_info{$id} = $json_project;
    }

    # Read metrics for projects
    $log->info( "[Model::Projects] Reading all projects metrics from [$dir_data]." );
    my @projects_metrics = <$dir_data/*/*_metrics.json>;
    foreach my $project (@projects_metrics) {
        $project =~ m!.*[\/](.*?)_metrics.json!;
        my $id = $1;
        my $json_project = &read_project_data($project);
        $projects{$id}{'metrics'} = $json_project->{'children'};
    }

    # Read attributes for projects
    $log->info( "[Model::Projects] Reading all projects attributes from [$dir_data]." );
    my @projects_attrs = <$dir_data/*/*_attributes.json>;
    foreach my $project (@projects_attrs) {
        $project =~ m!.*[\/](.*?)_attributes.json!;
        my $id = $1;
        my $json_project = &read_project_data($project);
        $projects{$id}{'attrs'} = $json_project->{'children'};
    }

    # Read attributes_confidence for projects
    $log->info( "[Model::Projects] Reading all projects attrs_conf from [$dir_data]." );
    my @projects_attrs_conf = <$dir_data/*/*_attributes_confidence.json>;
    foreach my $project (@projects_attrs_conf) {
        $project =~ m!.*[\/](.*?)_attributes_confidence.json!;
        my $id = $1;
        my $json_project = &read_project_data($project);
        $projects{$id}{'attrs_conf'} = $json_project->{'children'};
    }

    # Read questions for projects
    $log->info( "[Model::Projects] Reading all projects questions from [$dir_data]." );
    my @projects_questions = <$dir_data/*/*_questions.json>;
    foreach my $project (@projects_questions) {
        $project =~ m!.*[\/](.*?)_questions.json!;
        my $id = $1;
        my $json_project = &read_project_data($project);
        $projects{$id}{'questions'} = $json_project->{'children'};
    }

    # Read questions_confidence for projects
    $log->info( "[Model::Projects] Reading all projects questions confidence from [$dir_data]." );
    my @projects_questions_conf = <$dir_data/*/*_questions_confidence.json>;
    foreach my $project (@projects_questions_conf) {
        $project =~ m!.*[\/](.*?)_questions_confidence.json!;
        my $id = $1;
        my $json_project = &read_project_data($project);
        $projects{$id}{'questions_conf'} = $json_project->{'children'};
    }

    # Read indicators for projects
    $log->info( "[Model::Projects] Reading all projects indicators from [$dir_data]." );
    my @projects_inds = <$dir_data/*/*_indicators.json>;
    foreach my $project (@projects_inds) {
        $project =~ m!.*[\/](.*?)_indicators.json!;
        my $id = $1;
        my $json_project = &read_project_data($project);
        $projects{$id}{'indicators'} = $json_project->{'children'};
    }


    # Read violations for projects
    $log->info( "[Model::Projects] Reading all projects violations from [$dir_data]." );
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
    $log->info( "[Model::Projects] Reading all projects PMI data from [$dir_data]." );
    my @projects_pmi = <$dir_data/*/*_pmi.json>;
    foreach my $project (@projects_pmi) {
        $project =~ m!.*[\/](.*?)_pmi.json!;
        my $id = $1;
        my $json_project = &read_project_data($project);
        $projects{$id}{'pmi'} = $json_project->{'projects'}->{$id};
    }

    # Read comments for projects
    $log->info( "[Model::Projects] Reading all projects comments from [$dir_data]." );
    my @projects_comments = <$dir_data/*/*_comments.json>;
    foreach my $project_file (@projects_comments) {
        $project_file =~ m!.*[\/](.*?)_comments.json!;
        my $id = $1;
        my $json_project = &read_project_data($project_file);
        foreach my $comment (@{$json_project->{'comments'}}) {
            $projects{$id}{'comments'}{$comment->{'id'}} = $comment;
        }
    }

    # Read custom data for projects
    $log->info( "[Model::Projects] Reading all projects custom data from [$dir_data]." );
    my @projects_cdata = <$dir_data/*/*_data_*.json>;
    foreach my $project_file (@projects_cdata) {
        $project_file =~ m!.*[\/](.*?)_data_.*\.json!;
        my $id = $1;
        my $json_project = &read_project_data($project_file);
        foreach my $cdata (@{$json_project->{'children'}}) {
            push( @{$projects{$id}{'cdata'}{$json_project->{'cd'}}}, $cdata );
        }
    }

    my $vol = scalar keys %projects_info;
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

sub write_project_data($$) {
    my $file = shift;
    my $content = shift;

    my $json_content = encode_json($content);

    do { 
        local $/;
        open my $fh, '>', $file or die "Could not open data file [$file].\n";
        print $fh $json_content;
        close $fh;
    };

    return 1;
}


sub list_projects() {
    my @projects = keys %projects_info ;
    return @projects;
}

sub get_all_projects() {
    return %projects;
}

sub get_project_info($) {
    my $self = shift;
    my $project_id = shift;

    return $projects_info{$project_id};
}

sub get_project_name_by_id($) {
    my $self = shift;
    my $project_id = shift;

    return $projects_info{$project_id}{'name'};
}

sub get_project_metrics($) {
    my $self = shift;
    my $project_id = shift;

    return $projects{$project_id}{'metrics'};
}

sub get_project_metrics_last($) {
    my $self = shift;
    my $project_id = shift;

    my $metrics_last = $self->{app}->repo->get_file_last( 
        'projects/' . $project_id . '/' . $project_id . '_metrics.json' 
        );
    
    if (not defined($metrics_last)) {
        return undef;
    }

    return $metrics_last->{'children'};
}

sub get_project_indicators($) {
    my $self = shift;
    my $project_id = shift;

    $self->{app}->log->info("[Model::Projects.pm] get_project_indicators $project_id.");

    return $projects{$project_id}{'indicators'};
}

sub get_project_all_values($) {
    my $self = shift;
    my $project_id = shift;

    my %model = %{$self->{app}->models->get_model()};

    # Create a rich version of the quality model with all info on nodes.
    &populate_qm($model{"children"}, $projects{$project_id}{'attrs'}, $projects{$project_id}{'questions'}, $projects{$project_id}{'metrics'}, $projects{$project_id}{'indicators'});

    return \%model;
}

sub get_project_attrs($) {
    my $self = shift;
    my $project_id = shift;

    return $projects{$project_id}{'attrs'};
}

sub get_project_attrs_last($) {
    my $self = shift;
    my $project_id = shift;

    my $attrs_last = $self->{app}->repo->get_file_last( 
        'projects/' . $project_id . '/' . $project_id . '_attributes.json' 
        );

    if (not defined($attrs_last)) {
        return undef;
    }

    return $attrs_last->{'children'};
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

    my @comments;
    push( @comments, $projects{$project_id}{'comments'}{$_} ) for sort keys %{$projects{$project_id}{'comments'}};

    return \@comments;
}

sub add_project_comment($$) {
    my $self = shift;
    my $project_id = shift;    
    my $comment = shift;    

    my $comment_id = $comment->{'id'};
    $projects{$project_id}{'comments'}{ $comment_id } = $comment;
    my @comments = map { $projects{$project_id}{'comments'}{$_} } keys %{$projects{$project_id}{'comments'}};

    # Create headers for json file
    my $raw = {
        "name" => "$project_id",
        "version" => "Last updated on " . localtime(),
        "comments" => \@comments,
    };

    # Write updated comment file.
    my $file_to = $self->{app}->config->{'dir_data'} . '/' . $project_id . '/' . $project_id . '_comments.json';
    &write_project_data( $file_to, $raw);

    return 1;
}

sub edit_project_comment($$) {
    my $self = shift;
    my $project_id = shift;    
    my $comment = shift;    

    my $comment_id = $comment->{'id'};
    $projects{$project_id}{'comments'}{ $comment_id } = $comment;
    my @comments = map { $projects{$project_id}{'comments'}{$_} } keys %{$projects{$project_id}{'comments'}};


    # Create headers for json file
    my $raw = {
        "name" => "$project_id",
        "version" => "Last updated on " . localtime(),
        "comments" => \@comments,
    };

    # Write updated comment file.
    my $file_to = $self->{app}->config->{'dir_data'} . '/' . $project_id . '/' . $project_id . '_comments.json';
    &write_project_data( $file_to, $raw);

    return 1;
}

sub delete_project_comment($$) {
    my $self = shift;
    my $project_id = shift;    
    my $comment_id = shift;    
    
    delete $projects{$project_id}{'comments'}{$comment_id};
    my @comments = map { $projects{$project_id}{'comments'}{$_} } keys %{$projects{$project_id}{'comments'}};

    # Create headers for json file
    my $raw = {
        "name" => "$project_id",
        "version" => "Last updated on " . localtime(),
        "comments" => \@comments,
    };

    # Write updated comment file.
    my $file_to = $self->{app}->config->{'dir_data'} . '/' . $project_id . '/' . $project_id . '_comments.json';
    &write_project_data( $file_to, $raw);

    return 1;
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


#
# Retrieves all data for a project, and generate the metrics for the set of data sources
#
sub retrieve_project_data() {
    my $self = shift;
    my $project_id = shift;
    my $ds = shift || 'all';
    
    my @log;

    # Create target dir if it does not exist
    if (not -d $self->{app}->config->{'dir_input'} . '/' . $project_id . '/') { 
        mkdir( $self->{app}->config->{'dir_input'} . '/' . $project_id . '/');
    }

    # Get list of all plugins.
    my $ds_list = $self->{app}->al_plugins->get_list_all();

    # For each plugin, execute the retrieve_data and compute_data steps.
    foreach my $ds ( sort keys %{$projects_info{$project_id}{'ds'}} ) {
        if ( grep( $ds, @{$ds_list} ) ) {
            push( @log, "Plugin [$ds]:" );
            my @ret2;
            foreach my $line ( @{$self->{app}->al_plugins->get_plugin($ds)->retrieve_data($project_id)} ) {
                chomp $line;
                push( @ret2, "&nbsp; &nbsp; $line" );
            }
            push( @log, @ret2 );
            push( @log, map {"  " . $_} @{$self->{app}->al_plugins->get_plugin($ds)->compute_data($project_id)} );
        } else {
            $self->{app}->log->warn("[Model::Projects.pm] retrieve_project_data Cannot recognise ds [$ds]."); 
            push( @log, "[Model::Projects.pm] retrieve_project_data Cannot recognise ds [$ds]." );
        }
    }

    return \@log;
}


#
# Retrieves metrics from the various data files and consolidates them in 
# a single file, then computes the aggregation of metrics up to top attributes 
# for the project.
#
sub analyse_project($) {
    my $self = shift;
    my $project_id = shift;

    my @log;

    # Create an instance of the Analysis module.
    my $analysis = Alambic::Model::Analysis->new($self->{app}, $project_id);

    # Gather all input metrics files, and write a single metrics file 
    # for the project in $dir_data.
    push( @log, "[Model::Projects] Analysing input data.." );
    my $metrics = $analysis->analyse_input($project_id);

    # Copy files marked as plugin artefacts, both from plugins and custom data.
    my @pis = sort keys %{$projects_info{$project_id}{'ds'}};
    push( @pis, sort keys %{$projects_info{$project_id}{'cdata'}} );

    my $dir_to = $self->{app}->config->{'dir_data'} . '/' . $project_id . '/';

    push( @log, "[Model::Projects] Copying files provided by plugins.." );
    foreach my $pi (@pis) {
        my @files = map { 
            $self->{app}->config->{'dir_input'} . '/' . $project_id . '/' . $project_id . '_' . $_ . '.json'
        } @{$self->{app}->al_plugins->get_plugin($pi)->get_conf()->{'provides_files'}};
        foreach my $file (@files) {
            copy($file, $dir_to) or $self->{app}->log->warn( "ERROR $!" );
        }
    }
    
    push( @log, "[Model::Projects] Computing indicators and attributes.." );
    foreach my $line ( @{$analysis->compute_inds($project_id)} ) {
        chomp $line;
        push( @log, "&nbsp; &nbsp; $line" );
    }

    return \@log;
}


#
#
# Add or replace a project basic information: 
#  * project_id (string)
#  * project_name (string)
#
sub add_project() {
    my $self = shift;
    my $project_id = shift;
    my $project_name = shift;

    # Create directories for project in conf_data, conf_input
    mkdir( $self->{app}->config->{'dir_data'} . "/" . $project_id );
    mkdir( $self->{app}->config->{'dir_input'} . "/" . $project_id );

    my $file_info = $self->{app}->config->{'dir_data'} . '/' . $project_id . '/' . $project_id . '_info.json';

    my $info;
    if (-e $file_info ) {
        $info = &read_project_data( $file_info );
        $info->{'name'} = $project_name;
    } else {
        $info = {
            "id" => $project_id,
            "name" => $project_name,
        };
    }

    &write_project_data( $file_info, $info );

    # Add values to the current hashes
    $projects_info{$project_id} = $info;
#    $projects{$project_id} = {};

    return 1;
}

sub del_project() {
    my $self = shift;
    my $project_id = shift;

    # Create directories for project in conf_data, conf_input
    remove_tree( $self->{app}->config->{'dir_data'} . "/" . $project_id );
    remove_tree( $self->{app}->config->{'dir_input'} . "/" . $project_id );

    # Remove project from local variables.
    delete $projects_info{$project_id};
    delete $projects{$project_id};

    return 1;
}


# Get the list of plugins defined on the project.
sub get_project_ds($$) {
    my $self = shift;
    my $project_id = shift;
    my $ds_id = shift;

    return $projects_info{$project_id}{'ds'}{$ds_id};
}

# Add a plugin to the project, and update its info file.
sub set_project_ds() {
    my $self = shift;
    my $project_id = shift;
    my $ds_id = shift;
    my $params = shift;

    foreach my $param (keys %{$params}) {
        $projects_info{$project_id}{'ds'}{$ds_id}{$param} = $params->{$param};
    }

    # Write updated info file.
    my $file_to = $self->{app}->config->{'dir_data'} . '/' . $project_id . '/' . $project_id . '_info.json';
    &write_project_data( $file_to, $projects_info{$project_id});    
}

# Remove a plugin from a project, an update its info file.
sub delete_project_ds() {
    my $self = shift;
    my $project_id = shift;
    my $ds_id = shift;

    # Remove key to the deleted ds in info hash.
    delete $projects_info{$project_id}{'ds'}{$ds_id};
    
    # Write updated info file.
    my $file_to = $self->{app}->config->{'dir_data'} . '/' . $project_id . '/' . $project_id . '_info.json';
    &write_project_data( $file_to, $projects_info{$project_id});    
}

# Get the list of entries for the custom data plugins on a project.
sub get_project_cd_content($$) {
    my $self = shift;
    my $project_id = shift;
    my $cd_id = shift;

    return $projects{$project_id}{'cdata'}{$cd_id};
}

# Add a custom data plugin to the project, and update its info file.
sub set_project_cd() {
    my $self = shift;
    my $project_id = shift;
    my $cd_id = shift;
    my $params = shift;

    foreach my $param (keys %{$params}) {
        $projects_info{$project_id}{'cdata'}{$cd_id}{$param} = $params->{$param};
    }

    # Write updated info file.
    my $file_to = $self->{app}->config->{'dir_data'} . '/' . $project_id . '/' . $project_id . '_info.json';
    &write_project_data( $file_to, $projects_info{$project_id});    
}

# Remove a custom data plugin from a project, an update its info file.
sub delete_project_cd() {
    my $self = shift;
    my $project_id = shift;
    my $cd_id = shift;

    # Remove key to the deleted cd in info hash.
    delete $projects_info{$project_id}{'cdata'}{$cd_id};
    
    # Write updated info file.
    my $file_to = $self->{app}->config->{'dir_data'} . '/' . $project_id . '/' . $project_id . '_info.json';
    &write_project_data( $file_to, $projects_info{$project_id});    
}

1;
