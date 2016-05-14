package Alambic::Model::Project;

use warnings;
use strict;

use Data::Dumper;

use Alambic::Model::Plugins;
#use Alambic::Model::Analysis;
#use Alambic::Model::Config;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw( 
                     get_id
                     get_name
                     get_plugins
                     last_run
                     active
                     info
                     metrics
                     indicators
                     attributes
                     recs
                     run_plugin
                     run_plugins
                     run_qm
                     run_post
                     run_project
                   );  

######################################
# Data associated with a project
my ($project_name, $project_id, $project_desc);
my $project_active = 0;
my $project_last_run = '';

my %plugins = ();
# my %plugins = (
#     "plugin_id1" => {
# 	"param1" => "value1",
# 	"param2" => "value2",
#     },
#     );

my %info = ();
my %metrics = ();
my %indicators = ();
my %attributes = ();
my %attributes_conf = ();
my %recs = ();
######################################

# A ref to the Plugins module.
my $plugins_module;

# Constructor
sub new {
    my ($class, $id, $name, $active, $last_run, $plugins, $data) = @_;

    $project_id = $id;
    $project_name = $name;
    $project_active = $active;
    $project_last_run = $last_run;
    
    $plugins_module = Alambic::Model::Plugins->new();

    # Populate the plugins hash with init data.
    %plugins = ();
    if ( defined($plugins) ) {
	foreach my $plugin_id (keys %{$plugins}) {
	    $plugins{$plugin_id} = $plugins->{$plugin_id};
	}
    }

    # Populate the metrics, indicators and attributes hashes with init data.
    %info = ();
    %metrics = ();
    %indicators = ();
    %attributes = ();
    %attributes_conf = ();
    %recs = ();
    if ( defined($data) ) {
	%info = %{$data->{'info'} || {}};
	%metrics = %{$data->{'metrics'} || {}};
	%indicators = %{$data->{'indicators'} || {}};
	%attributes = %{$data->{'attributes'} || {}};
	%attributes_conf = %{$data->{'attributes_conf'} || {}};
	%recs = %{$data->{'recs'} || {}};
    }

    return bless {}, $class;
}

sub get_id() {
    return $project_id;
}

sub get_name() {
    return $project_name;
}

sub desc() {
    my ($self, $desc) = @_;

    if (scalar @_ > 1) {
	$project_desc = $desc;
    }
    
    return $project_desc;
}

sub active() {
    my ($self, $active) = @_;

    if (scalar @_ > 1) {
	$project_active = $active;
    }
    
    return $project_active;
}

sub last_run() {
    my ($self, $last_run) = @_;

    if (scalar @_ > 1) {
	$project_last_run = $last_run;
    }
    
    return $project_last_run;
}

sub get_plugins() {
    return \%plugins;
}

sub info() {
    my ($self, $info) = @_;

    %info = %{$info} if (scalar @_ > 1);
	   
    return \%info;
}

sub metrics() {
    my ($self, $metrics) = @_;

    %metrics = %{$metrics} if (scalar @_ > 1);
	   
    return \%metrics;
}

sub indicators() {
    my ($self, $indicators) = @_;

    %metrics = %{$indicators} if (scalar @_ > 1);
	   
    return \%indicators;
}

sub attributes() {
    my ($self, $attributes) = @_;

    %attributes = %{$attributes} if (scalar @_ > 1);
	   
    return \%attributes;
}

sub recs() {
    my ($self, $recs) = @_;
    
    %recs = %{$recs} if (scalar @_ > 1);
	   
    return \%recs;
}

sub run_plugin($) {
    my ($self, $plugin_id) = @_;

    my $ret = $plugins_module->get_plugin($plugin_id)->run_plugin($project_id, $plugins{$plugin_id});

    foreach my $info (sort keys %{$ret->{'info'}} ) {
	$info{$info} = $ret->{'info'}{$info};
    }

    foreach my $metric (sort keys %{$ret->{'metrics'}} ) {
	$metrics{$metric} = $ret->{'metrics'}{$metric};
    }

    foreach my $rec (sort keys %{$ret->{'recs'}} ) {
	$recs{$rec} = $ret->{'recs'}{$rec};
    }
    
    return $ret;
}

sub run_plugins() {
    my ($self) = @_;

    my @log;

    foreach my $plugin_id (keys %plugins) {
	my $ret = $plugins_module->get_plugin($plugin_id)->run_plugin($project_id, $plugins{$plugin_id});

	foreach my $metric (sort keys %{$ret->{'metrics'}} ) {
	    $metrics{$metric} = $ret->{'metrics'}{$metric};
	}
	
	foreach my $rec (sort keys %{$ret->{'recs'}} ) {
	    $recs{$rec} = $ret->{'recs'}{$rec};
	}

	@log = (@log, @{$ret->{'log'}});
    }

    return { "metrics" => \%metrics, "recs" => \%recs, "log" => \@log };
}


# Run a qm analysis: generate indicators and attributes for the project.
#
# Params:
#   $models a ref to a Models.pm object
sub run_qm($) {
    my $self = shift;
    my $models = shift;
    
    my $ret = &_compute_inds($models);
    %attributes = %{$ret->{'attrs'}};
    %indicators = %{$ret->{'inds'}};
		    
    return $ret;
}


# Run all post plugins for this project
sub run_post() {

}


# Run a full project analysis: run plugins, qm, and post.
#
# Params:
#   $models a ref to a Models.pm object
sub run_project($) {
    my ($self, $models) = @_;

    my %ret;

    # Run plugins
    my $pre_data = $self->run_plugins();
    foreach my $item (keys %$pre_data) {
	$ret{$item} = $pre_data->{$item};
    }
    
    # Run plugins
    my $qm_data = $self->run_qm($models);
    foreach my $item (keys %{$qm_data}) {
	# Most children are hashes.
	if ( defined($qm_data->{$item}) && ref($qm_data->{$item}) =~ /HASH/ ) {
	    foreach my $value (keys %{$qm_data->{$item}}) {
		$ret{$item}{$value} = $qm_data->{$item}{$value};
	    }
	}
	# Some children are arrays (e.g. log)
	if ( defined($qm_data->{$item}) && ref($qm_data->{$item}) =~ /ARRAY/ ) {
	    foreach my $value (@{$qm_data->{$item}}) {
		push( @{$ret{$item}}, $value );
	    }
	}
    }
    
    # Run post plugins
    my $post_data = $self->run_post();
    
    return \%ret;
}


# Check if the scale is normal or reverse
sub _is_ordered_scale($) {
    my $scale = shift;

    my $scale_unsort = join(' ', @{$scale});
    my $scale_sort = join(' ', sort { $a <=> $b } @{$scale});
    my $scale_revsort = join(' ', sort { $b <=> $a } @{$scale});

    my $is_sorted;
    if ($scale_sort eq $scale_unsort) {
	$is_sorted = 1;
    } elsif ($scale_revsort eq $scale_unsort) {
	$is_sorted = 0;
    } else {
	$is_sorted = "ERROR: scale [" . $scale_unsort . "] is not right. Not using it.";
    }

    return $is_sorted;
}


# Computes indicators (range 1-5) from metrics (wide range).
# Params:
#   $value the value to be converted
#   $scale a ref to an array of 4 values describing the scale
sub _compute_scale($$) {
    my $value = shift;
    my $scale = shift;

    my $is_sorted = &_is_ordered_scale($scale);
    # If a problem arose, then dispatch it.
    if ($is_sorted !~ /\d/) { return $is_sorted }
    
    my $indicator;

    # If the value is not defined we want to return undef
    if ( defined($value) ) {
	if ( $is_sorted ) {
	    if ( $value < $scale->[0] ) { $indicator = 1 }
	    elsif ( $value < $scale->[1] ) { $indicator = 2 }
	    elsif ( $value < $scale->[2] ) { $indicator = 3 }
	    elsif ( $value < $scale->[3] ) { $indicator = 4 }
	    else { $indicator = 5 }
	} else {
	    if ( $value > $scale->[0] ) { $indicator = 1 }
	    elsif ( $value > $scale->[1] ) { $indicator = 2 }
	    elsif ( $value > $scale->[2] ) { $indicator = 3 }
	    elsif ( $value > $scale->[3] ) { $indicator = 4 }
	    else { $indicator = 5 }	    
	}
    }

    return $indicator;
}


# Recursive function to compute aggregates of the quality model
# from the leafs up to the root.
sub _aggregate_inds($$$$$) {
    my $raw_qm = shift;
    my $values = shift;
    my $inds_ref = shift;
    my $inds_ref_conf = shift;
    my $attrs_ref = shift;
    my $attrs_ref_conf = shift;
    my $metrics = shift;
    my $log = shift;
    
    my $mnemo = $raw_qm->{"mnemo"};
    my $coef;

    # Are we in a leaf?
    if (exists($raw_qm->{"children"})) {
	# No: we have children beneath.
	my @children = @{$raw_qm->{"children"}};
	my @coefs;
	my $tmp_m_total;
	my $tmp_m_ok;
	my $full_weight;
	foreach my $child (@children) {
	    my $child_value = &_aggregate_inds($child, $values, 
					      $inds_ref, $inds_ref_conf, 
					      $attrs_ref, $attrs_ref_conf, $metrics, $log);
	    
	    $tmp_m_total += $child->{"m_total"};
	    $tmp_m_ok += $child->{"m_ok"};
	    if (defined($child_value)) {
		# If a problem arose, then dispatch it.
		if ($child_value !~ /^\d*$/) { 
		    push( @{$log}, "ERROR during scale compute for $mnemo.") 
		}
		if (exists($child->{"weight"})) {
		    $full_weight += $child->{"weight"};
		    push(@coefs, $child_value * $child->{"weight"});
		} else {
		    # Default value for weight is 1.
		    $full_weight += 1; 
		    push(@coefs, $child_value);
		}
	    }
	}

	# Only store indicator if it is not null
	if ((scalar @coefs) != 0) {
	    my $sum;
	    map { $sum += $_ } @coefs;
	    
	    $coef = $sum / $full_weight;
	    my $coef_round = sprintf("%.1f", $coef);
	    $raw_qm->{"ind"} = $coef_round;
	    $coef = $coef_round;
	}

	# Compute the number of metrics: total, available.
	$raw_qm->{"m_total"} = $tmp_m_total;
	$raw_qm->{"m_ok"} = $tmp_m_ok;
	
    } else {
	# Yes: compute the ind value of leaf.

	if (not exists($metrics->{$mnemo})) {
	    push( @$log, "ERROR: Metric $mnemo not found in metrics definition.");
	    $raw_qm->{"m_total"} = 0; 
	    $raw_qm->{"m_ok"} = 0;
	    return 0;
	}
	
	$coef = &_compute_scale($values->{$mnemo}, $metrics->{$mnemo}{"scale"});
	$raw_qm->{"ind"} = $coef;

	my $raw_qm_active = 0;
	if ( exists( $raw_qm->{'active'} ) && $raw_qm->{'active'} =~ m!true! ) {
	    $raw_qm_active = 1;
	}

	# Increment the total number of metrics used for this node.
	# We do want to count only active metrics for confidence.
	if ($raw_qm_active) {
	    $raw_qm->{"m_total"} = 1;
	    # If metric is defined also increment m_ok
	    if (defined($coef)) {
		$raw_qm->{"m_ok"} = 1;

		# If a problem arose, then dispatch it.
		if ($coef !~ /^\d*$/) { return $coef }

	    } else {
		$raw_qm->{"m_ok"} = 0;		
		push( @$log, "ERROR: Metric [$mnemo] could not be computed." );
	    }
	} else {
	    $raw_qm->{"m_total"} = 0; 
	    $raw_qm->{"m_ok"} = 0;
	}
	
    }

    my $confidence = $raw_qm->{"m_ok"} . " / " . $raw_qm->{"m_total"};

    # Populate hashes of values for indicators, attributes.
    if (defined($coef)) {
	if ($raw_qm->{"type"} =~ m!attribute!) {
	    $attrs_ref->{$mnemo} = $coef;
	    $attrs_ref_conf->{$mnemo} = $confidence;
	} elsif ($raw_qm->{"type"} =~ m!metric!) {
	    $inds_ref->{$mnemo} = $coef;
	    $inds_ref_conf->{$mnemo} = $confidence;
	}
    }
    
    return $coef;
}

sub _compute_inds($) {
    my $models = shift;
    
    my $log;
    my %ret;

    my $raw_qm = $models->get_qm();
    my $metrics = $models->get_metrics();
    
    my $project_indicators = {};
    my $project_indicators_conf = {};
    my $project_attrs = {};
    my $project_attrs_conf = {};

    push( @$log, "[Model::Project] Aggregating data from leaves up to attributes." );
    &_aggregate_inds(
	$raw_qm->[0], \%metrics, 
	$project_indicators, $project_indicators_conf, 
	$project_attrs, $project_attrs_conf, $metrics, $log);
    
    $ret{'inds'} = $project_indicators;
    $ret{'inds_conf'} = $project_indicators_conf;
    $ret{'attrs'} = $project_attrs;
    $ret{'attrs_conf'} = $project_attrs_conf;
    $ret{'log'} = $log;

    return \%ret;
}


1;
