package Alambic::Model::Models;

use warnings;
use strict;

use Scalar::Util 'weaken';
use List::MoreUtils qw(uniq);
use Mojo::JSON qw( decode_json encode_json );
use Data::Dumper;


require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw( read_all_files
                 get_model_info
                 get_model_nodes 
                 get_attributes 
                 get_attributes_full
                 get_metrics 
                 get_metrics_repos 
                 get_metrics_full
                 get_qm
                 get_qm_full
                 populate_qm
                 );


my %metrics;
my %metrics_ds;
my @metrics_active;
my $metrics_total = 0;

my %attributes;
my $model;

# Constructor
sub new {
    my $class = shift;
    my $in_metrics = shift || {};
    my $in_attributes = shift || {};
    my $in_qm = shift || {};
    my $in_plugins = shift || {};

    &_init_metrics($in_metrics, $in_qm, $in_plugins);
    %attributes = %$in_attributes;
    $model = $in_qm;
    
    return bless {}, $class;
}

#
# Add is_active, parents nodes to metrics definition.
#
sub _init_metrics($) {
    my $in_metrics = shift;
    my $in_model = shift;
    my $in_plugins = shift;

    # Import metrics and enhance their defition (add is_active)
    foreach my $tmp_metric (keys %$in_metrics) {
        my $metric_mnemo = $in_metrics->{$tmp_metric}->{"mnemo"};

	# Check if the metric is active in the qm 
	my @nodes_array;
        # Find nodes of qm which have the same mnemonic.
	&find_qm_node($in_model, "metric", $metric_mnemo, \@nodes_array, "root");
	my %tmp_nodes;
	foreach my $node (@nodes_array) {
	    if (defined($node->{"father"})) {
		$tmp_nodes{$node->{"father"}}++;
	    } else {
#		$self->log->info( "[Model::Models] ERR: no father on " . $node->{"mnemo"} . "" );
	    }

	    if ($node->{"active"} =~ m!true!i) { 
		$in_metrics->{$tmp_metric}->{"active"} = "true"; 
	    } else {
		$in_metrics->{$tmp_metric}->{"active"} = "false"; 
	    }
	}
	$in_metrics->{$tmp_metric}->{"parents"} = \%tmp_nodes;

	# Populate metrics_ds and %metrics only if the metric has been found in the qm.
#	if ( defined($in_metrics->{$tmp_metric}->{"active"}) ) {
	    $metrics_total++;
	    $metrics{$metric_mnemo} = $in_metrics->{$tmp_metric};
# FIXME           if ( $in_metrics->{$tmp_metric}->{'active'} =~ m!true! ) { push( @metrics_active, $metric_mnemo ) }
#	} 
    }

    # Now build the list of data sources by reading through
    # plugins and assigning each metric its plugin.
    my $pis = $in_plugins->get_names_all();
    foreach my $pi_ref (keys %$pis) {
        my $pi_conf = $in_plugins->get_plugin($pi_ref)->get_conf();
        foreach my $metric (keys %{$pi_conf->{'provides_metrics'}}) {
            my $metric_map = $pi_conf->{'provides_metrics'}{$metric};
            if ( exists($metrics{$metric_map}) ) {
                $metrics_ds{$pi_conf->{'id'}}++;
                $metrics{$metric_map}{'ds'} = $pi_conf->{'id'};
            }
        }
    }

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


# Get the full quality model for the documentation visualisation.
sub get_qm_full() {
    my $self = shift;

    print "# In Models::get_qm_full " . Dumper($model);
    my $qm_full_children = $model;

    # Create a rich version of the quality model with all info on nodes.
    &_populate_qm($qm_full_children, undef, undef, undef, undef);

    my $qm_full = {
        "name" => "Alambic Full Quality Model",
        "version" => "" . localtime(),
        "children" => $qm_full_children,
    };
    
    return $qm_full;
}


# Recursive function to populate the quality model with information from 
# external files (metrics/attributes definition). 
#
# This one can be called from other modules.
#
# Params:
#   $qm a ref to an array of children
#   $attrs a ref to hash of values for attributes
#   $metrics a ref to hash of values for metrics
#   $inds a ref to hash of indicators for metrics
sub populate_qm($$$$$) {
    my $self = shift;
    my $qm = shift;
    my $l_attrs = shift;
    my $l_metrics = shift;
    my $l_inds = shift;

    return &_populate_qm($qm, $l_attrs, $l_metrics, $l_inds);
}


# Recursive function to populate the quality model with information from 
# external files (metrics/attributes definition). 
#
# This function is for internal use only (no self passed as 1st argument).
#
# Params:
#   $qm a ref to an array of children
#   $attrs a ref to hash of values for attributes
#   $metrics a ref to hash of values for metrics
#   $inds a ref to hash of indicators for metrics
sub _populate_qm($$$$$) {
    my $qm = shift;
    my $l_attrs = shift;
    my $l_metrics = shift;
    my $l_inds = shift;
    
    foreach my $child (@{$qm}) {
	my $mnemo = $child->{"mnemo"};
	
	if ($child->{"type"} =~ m!attribute!) {
	    $child->{"name"} = $attributes{$mnemo}{"name"};
	    $child->{"ind"} = $l_attrs->{$mnemo};
	} elsif ($child->{"type"} =~ m!metric!) {
	    $child->{"name"} = $metrics{$mnemo}{"name"};
            $child->{"value"} = eval sprintf("%.1f", $l_metrics->{$mnemo} || 0);
	    $child->{"ind"} = $l_inds->{$mnemo};
	} else { print "WARN: cannot recognize type " . $child->{"type"} . "\n"; }

	if ( exists($child->{"children"}) ) {
	    &_populate_qm($child->{"children"}, $l_attrs, $l_metrics, $l_inds);
	}
    }
}

sub get_model_nodes() {
    my @nodes = sort &find_nodes($model->{'children'});
    return @nodes;
}


# Utility to find all node mnemos in the qm tree
sub find_nodes($) {
    my $nodes = shift;

    my @nodes_ret;
    foreach my $node (@{$nodes}) {
	my $mnemo = $node->{'mnemo'};
	push(@nodes_ret, $mnemo);
	if (exists($node->{'children'})) {
	    my @nodes_new = &find_nodes($node->{'children'});
	    push(@nodes_ret, @{nodes_new});
	}
    }
    
    return uniq(@nodes_ret);
}

sub get_metrics() {
    return \%metrics;
}

sub get_metrics_active() {
    return \@metrics_active;
}

sub get_metrics_repos() {
    return \%metrics_ds;
}

sub get_metrics_full() {
    my %full = (
        'name' => "Alambic Metrics",
        'version' => localtime(),
        'children' => \%metrics,
    );

    return \%full;
}

sub get_attributes() {
    return \%attributes;
}

sub get_attributes_full() {
    my %full = (
        'name' => "Alambic Attributes",
        'version' => localtime(),
        'children' => \%attributes,
    );

    return \%full;
}

sub get_qm() {
    return $model;
}


1;
