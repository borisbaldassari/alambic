package Alambic::Model::Models;
use Scalar::Util 'weaken';

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw( read_all_files
                 get_model 
                 get_model_info
                 get_attributes 
                 get_attributes_info 
                 get_attributes_full
                 get_metrics 
                 get_metrics_info 
                 get_metrics_repos 
                 get_metrics_full
                 get_questions 
                 get_questions_info 
                 get_questions_full
                 get_rules 
                 get_rules_sources );  

use Mojo::JSON qw(decode_json encode_json);

use warnings;
use strict;
use Data::Dumper;

my %metrics;
my %metrics_ds;
my %metrics_info;

my %attributes;
my %attributes_info;

my %questions;
my %questions_info;

my %model;
my %model_info;

my %rules;
my %rules_sources;


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

    $self->{app}->log->debug("[Model::Models] TEST.");
    my $config = $self->{app}->config;

    # Read quality model definition
    my $file_model = $config->{'dir_conf'} . "/quality_model.json";
    $self->{app}->log->info( "[Model::Models] Reading model definition from [$file_model]." );

    my $json_model = &read_data($file_model);
    %model = %{$json_model};
    $model_info{'name'} = $model{'name'};
    $model_info{'version'} = $model{'version'};

    &read_metrics( $self->{app}, $config->{'dir_conf'} );

    &read_attributes( $self->{app}, $config->{'dir_conf'} );

    &read_questions( $self->{app}, $config->{'dir_conf'} );

    &read_rules( $self->{app}, $config->{'dir_rules'} );

}


#
# Read metrics definition and set the global %metrics variable.
#
sub read_metrics($) {
    my $app = shift;
    my $dir_conf = shift;

    my $file_metrics = $dir_conf . "/model_metrics.json";
    $app->log->info( "[Model::Models] Reading metrics definition from [$file_metrics]." );

    my $json_metrics = &read_data($file_metrics);

    # Import metrics and enhance their defition (add is_active)
    my $metrics_total;
    foreach my $tmp_metric (@{$json_metrics->{"children"}}) {
        my $metric_mnemo = $tmp_metric->{"mnemo"};
        my $metric_ds = $tmp_metric->{"ds"};
	if (exists $metrics{$metric_mnemo}) {
	    my $err = "WARN: Metric [$metric_mnemo] already exists!.";
#	    push( @{$project_errors{'MAIN'}}, $err);
#	    print "$err\n",
            next;
	}

	# Check if the metric is active in the qm 
	my @nodes_array;
        # Find nodes of qm which have the same mnemonic.
	&find_qm_node($model{'children'}, "metric", $metric_mnemo, \@nodes_array, "root");
	my %tmp_nodes;
	foreach my $node (@nodes_array) {
	    if (defined($node->{"father"})) {
		$tmp_nodes{$node->{"father"}}++;
	    } else {
		$app->log->info( "[Model::Models] ERR: no father on " . $node->{"mnemo"} . "" );
	    }

	    if ($node->{"active"} =~ m!true!i) { 
		$tmp_metric->{"active"} = "true"; 
	    } else {
		$tmp_metric->{"active"} = "false"; 
	    }
	}
	$tmp_metric->{"parents"} = \%tmp_nodes;

	# Populate metrics_ds and %metrics only if the metric has been found in the qm.
	if ( defined($tmp_metric->{"active"}) ) {
	    $metrics_ds{$metric_ds}++;
	    $metrics_total++;
	    $metrics{$metric_mnemo} = $tmp_metric;
	} 
    }

    $metrics_info{'name'} = $json_metrics->{'name'};
    $metrics_info{'version'} = $json_metrics->{'version'};

    # Create a rich version of the quality model with all info on nodes.
    #&populate_qm($model{"children"}, undef, undef, undef, undef);

}


# Find and return a specific mnemo in the quality model tree.
# The function can return zero, one or more nodes.
# This is a recursive method!
sub find_qm_node($$$$) {
    my $raw_qm_array = shift;
    my $type = shift;
    my $mnemo = shift;
    my $nodes_array = shift;
    my $father_mnemo = shift;

    foreach my $child (@{$raw_qm_array}) {
	if (($child->{"type"} eq $type) and ($child->{"mnemo"} eq $mnemo)) {
	    $child->{"father"} = $father_mnemo;
	    push(@{$nodes_array}, $child);
	    next;
	}
	if (exists($child->{"children"})) {
	    &find_qm_node($child->{"children"}, $type, $mnemo, $nodes_array, $child->{"mnemo"});
	} else {
	}
    }
}


#
# Read attributes definition and set the %attributes global var.
#
sub read_attributes($) {
    my $app = shift;
    my $dir_conf = shift;

    my $file_attrs = $dir_conf . "/model_attributes.json";
    $app->log->info( "[Model::Models] Reading attributes definition from [$file_attrs]." );
    my $json_attrs = &read_data($file_attrs);
    foreach my $item (@{$json_attrs->{'children'}}) {
        $attributes{$item->{'mnemo'}} = $item;
    }

    $attributes_info{'name'} = $json_attrs->{'name'};
    $attributes_info{'version'} = $json_attrs->{'version'};
}

#
# Read questions definition and set the %questions global var.
#
sub read_questions($) {
    my $app = shift;
    my $dir_conf = shift;

    my $file_questions = $dir_conf . "/model_questions.json";
    $app->log->info( "[Model::Models] Reading questions definition from [$file_questions]." );
    my $json_questions = &read_data($file_questions);
    foreach my $item (@{$json_questions->{'children'}}) {
        $questions{$item->{'mnemo'}} = $item;
    }

    $questions_info{'name'} = $json_questions->{'name'};
    $questions_info{'version'} = $json_questions->{'version'};
}

#
# Read questions definition and set the %questions global var.
#
sub read_rules($) {
    my $app = shift;
    my $dir_rules = shift;

    $app->log->info( "[Model::Models] Reading rules definition from [$dir_rules]." );

    my @files = <$dir_rules/*_rules.json>;
    foreach my $file_rules (@files) {
        $app->log->info( "[Model::Models]   * Reading file [$file_rules]." );
        my $json_rules = &read_data($file_rules);
        foreach my $item (@{$json_rules->{'children'}}) {
            my $source = $json_rules->{'name'} . " " . $json_rules->{'version'};
            $rules{$item->{'mnemo'}} = $item;
            $rules{$item->{'mnemo'}}{'src'} = $source;
            $rules_sources{$source}++;
        }
    }
}


# Recursive function to populate the quality model with information from 
# external files (metrics/questions/attributes definition). 
# Params:
#   $qm a ref to an array of children
#   $attrs a ref to hash of values for attributes
#   $questions a ref to hash of values for questions
#   $metrics a ref to hash of values for metrics
#   $inds a ref to hash of indicators for metrics
# sub populate_qm($$$$$) {
#     my $qm = shift;
#     my $l_attrs = shift;
#     my $l_questions = shift;
#     my $l_metrics = shift;
#     my $l_inds = shift;
    
#     foreach my $child (@{$qm}) {
# 	my $mnemo = $child->{"mnemo"};
	
# 	if ($child->{"type"} =~ m!attribute!) {
# 	    $child->{"name"} = $attributes{$mnemo}{"name"};
# 	    $child->{"ind"} = $l_attrs->{$mnemo};
# 	} elsif ($child->{"type"} =~ m!concept!) {
# 	    $child->{"name"} = $questions{$mnemo}{"name"};
# 	    $child->{"ind"} = $l_questions->{$mnemo};
# 	} elsif ($child->{"type"} =~ m!metric!) {
# 	    $child->{"name"} = $metrics{$mnemo}{"name"};
# 	    $child->{"value"} = $l_metrics->{$mnemo};
# 	    $child->{"ind"} = $l_inds->{$mnemo};
# 	} else { print "WARN: cannot recognize type " . $child->{"type"} . "\n"; }

# 	if ( exists($child->{"children"}) ) {
# 	    &populate_qm($child->{"children"}, $attrs, $questions, $metrics, $inds);
# 	}
#     }
# }

sub get_model() {
    return %model;
}

sub get_model_info() {
    return %model_info;
}

sub get_metrics() {
    return %metrics;
}

sub get_metrics_info() {
    return %metrics_info;
}

sub get_metrics_repos() {
    return %metrics_ds;
}

sub get_metrics_full() {
    my %full = (
        'name' => $metrics_info{'name'},
        'version' => $metrics_info{'version'},
        'children' => \%metrics,
    );

    return %full;
}

sub get_attributes() {
    return %attributes;
}

sub get_attributes_info() {
    return %attributes_info;
}

sub get_attributes_full() {
    my %full = (
        'name' => $attributes_info{'name'},
        'version' => $attributes_info{'version'},
        'children' => \%attributes,
    );

    return %full;
}

sub get_questions() {
    return %questions;
}

sub get_questions_info() {
    return %questions_info;
}

sub get_questions_full() {
    my %full = (
        'name' => $questions_info{'name'},
        'version' => $questions_info{'version'},
        'children' => \%questions,
    );

    return %full;
}

sub get_rules() {
    return %rules;
}

sub get_rules_sources() {
    return %rules_sources;
}

sub read_data($) {
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

1;
