package Alambic::Model::Analysis;

use warnings;
use strict;

use Scalar::Util 'weaken';
use Mojo::JSON qw( decode_json encode_json );
use Data::Dumper;


require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw( read_all_files
                 analyse_input
                 compute_inds
                 );  

my $project_id;
my %project_values;

my %flat_metrics;
my %flat_attributes;
my %flat_questions;

# Constructor
sub new {
    my $class = shift;
    my $app = shift;
    $project_id = shift;
    
    # Get info about model, attributes, questions, metrics.
    my $models = $app->models;
    %flat_metrics = %{$models->get_metrics()};
    %flat_attributes = %{$models->get_attributes()};
    %flat_questions = %{$models->get_questions()};

    my $hash = {app => $app};
    weaken $hash->{app};

    return bless $hash, $class;
}


sub read_all_files() {

}


#
# Read all files in data_input following '*_metrics*.json' and 
# create a single file including all metrics for project.
# Also create a file with all errors/warnings from analysis.
#
sub analyse_input() {
    my $self = shift;
    
    my $dir_input = $self->{app}->config->{'dir_input'};
    my $dir_projects = $self->{app}->config->{'dir_projects'};

    my @project_errors;

    # We read metrics from all files named "*_metrics*.json"
    my @json_metrics_files = <$dir_input/${project_id}/${project_id}*_metrics_*.json>;
    for my $file (@json_metrics_files) {
	$self->{app}->log->info( "    - Reading metrics values file from [$file].." );    
	
	my $raw_values = &read_data($file);
	
	# We want to be able to read files from bitergia (raw) AND
	# from our scripts (extended).
	if (exists($raw_values->{"name"})) {
	    # Our first, initial format 
	    foreach my $metric (sort keys %{$raw_values->{"children"}}) {
		if ($raw_values->{"children"}->{$metric} =~ m![\d.]+!) {
		    $project_values{uc($metric)} = $raw_values->{"children"}->{$metric};
		} else {
		    if ($raw_values->{"children"}->{$metric} =~ m!^nan$!i) {
			push( @project_errors, "WARNING: NAN value for [" . uc($metric) . "]." );
		    } else {
                        push( @project_errors, "WARNING: Null value for [" . uc($metric) . "]: " 
                              . $raw_values->{"children"}->{$metric} . "." );
		    }
		}
	    }
	} else {
	    # New, Bitergia format
	    foreach my $metric (keys %{$raw_values}) {
		if ($raw_values->{$metric} =~ m![\d.]+!) {
		    $project_values{uc($metric)} = $raw_values->{$metric};
		} else {
		    if ($raw_values->{$metric} =~ m!^nan$!i) {
			push( @project_errors, "WARNING: NAN value for [" . uc($metric) . "]." );
		    } else {
                        push( @project_errors, "WARNING: Null value for [" . uc($metric) . "]: " 
                              . $raw_values->{"children"}->{$metric} . "." );
		    }
		}
	    }        
	}
    }

    # Create headers for json file
    my $raw = {
        "name" => "Metrics for $project_id",
        "version" => "Last updated by Alambic dashboard on " . localtime(),
        "children" => \%project_values,
    };

    my $file_to = $self->{app}->config->{'dir_data'} . '/' . $project_id . '/' . $project_id . '_metrics.json';
    &write_data( $file_to, $raw );    

    #
    # Create a file to log errors and warnings.
    # 

    # Check that all metrics are there, if not log the missing ones.
    foreach my $metric ( @{$self->{app}->models->get_metrics_active()} ) {
        if ( not grep( /${metric}/, keys %project_values ) ) {
            unshift( @project_errors, "ERROR: Missing metric [$metric]." );
        }
    }

    # Create headers for json file
    $raw = {
        "name" => "Error log for $project_id",
        "version" => "Last updated by Alambic dashboard on " . localtime(),
        "children" => \@project_errors,
    };

    $file_to = $self->{app}->config->{'dir_data'} . '/' . $project_id . '/' . $project_id . '_errors.json';
    &write_data( $file_to, $raw );    
    
    
    return \%project_values;
}


# Check if the scale is normal or reverse
sub is_ordered_scale($) {
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
        # TODO how to raise up this exception?
	my $err = "WARN: scale [" . $scale_unsort . 
	    "] is not right. Not using it.\n";
    }

    return $is_sorted;
}


# Computes indicators (range 1-5) from metrics (wide range).
# Params:
#   $value the value to be converted
#   $scale a ref to an array of 4 values describing the scale
sub compute_scale($$) {
    my $value = shift;
    my $scale = shift;

    my $is_sorted = &is_ordered_scale($scale);
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
    my $attrs = shift;
    my $questions = shift;
    my $metrics = shift;
    my $inds = shift;
    
    foreach my $child (@{$qm}) {
	my $mnemo = $child->{"mnemo"};
	
	if ($child->{"type"} =~ m!attribute!) {
	    $child->{"name"} = $flat_attributes{$mnemo}{"name"};
	    $child->{"ind"} = $attrs->{$mnemo};
	} elsif ($child->{"type"} =~ m!concept!) {
	    $child->{"name"} = $flat_questions{$mnemo}{"name"};
	    $child->{"ind"} = $questions->{$mnemo};
	} elsif ($child->{"type"} =~ m!metric!) {
	    $child->{"name"} = $flat_metrics{$mnemo}{"name"};
	    $child->{"value"} = $metrics->{$mnemo};
	    $child->{"ind"} = $inds->{$mnemo};
	} else { print "WARN: cannot recognize type " . $child->{"type"} . "\n"; }

	if ( exists($child->{"children"}) ) {
	    &populate_qm($child->{"children"}, $attrs, $questions, $metrics, $inds);
	}
    }
}


sub aggregate_inds($$$$$) {
    my $raw_qm = shift;
    my $values = shift;
    my $inds_ref = shift;
    my $inds_ref_conf = shift;
    my $questions_ref = shift;
    my $questions_ref_conf = shift;
    my $attrs_ref = shift;
    my $attrs_ref_conf = shift;
    my $project_id = shift;

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
	    my $child_value = &aggregate_inds($child, $values, 
					      $inds_ref, $inds_ref_conf, 
					      $questions_ref, $questions_ref_conf, 
					      $attrs_ref, $attrs_ref_conf,
		                              $project_id);
	    $tmp_m_total += $child->{"m_total"};
	    $tmp_m_ok += $child->{"m_ok"};
	    if (defined($child_value)) {
		if (exists($child->{"weight"})) {
		    $full_weight += $child->{"weight"};
		    push(@coefs, $child_value * $child->{"weight"});
		} else {
		    # Default value for weight is 1.
		    $full_weight += 1; 
		    push(@coefs, $child_value) if (defined($child_value));
		}
	    }
	}

	# Only store indicator if it is not null
	if ((scalar @coefs) != 0) {
	    my $sum;
	    map { $sum += $_ } @coefs;
	    
	    $coef = $sum / $full_weight;
	    my $coef_round = sprintf("%.1f", $coef);
#	    my $coef_round = int($coef);
	    $raw_qm->{"ind"} = $coef_round;
	    $coef = $coef_round;
	}

	# Compute the number of metrics: total, available.
	$raw_qm->{"m_total"} = $tmp_m_total;
	$raw_qm->{"m_ok"} = $tmp_m_ok;
	
    } else {
	# Yes: compute the ind value of leaf.
	$coef = &compute_scale($values->{$mnemo}, $flat_metrics{$mnemo}{"scale"});
	$raw_qm->{"ind"} = $coef;

	my $raw_qm_active = ( $raw_qm->{'active'} =~ m!true! ) || 0;

	# Increment the total number of metrics used for this node.
	# We do want to count only active metrics for confidence.
	if ($raw_qm_active) {
	    $raw_qm->{"m_total"} = 1;
	    # If metric is defined also increment m_ok
	    if (defined($coef)) {
		$raw_qm->{"m_ok"} = 1;
	    } else {
		$raw_qm->{"m_ok"} = 0;
		
		my $err = "ERR: Metric [$mnemo] is missing.";
#		push( @{$project_errors{$project_id}}, $err);
	    }
	} else {
	    $raw_qm->{"m_total"} = 0;
	    $raw_qm->{"m_ok"} = 0;
	}
	
    }

    my $confidence = $raw_qm->{"m_ok"} . " / " . $raw_qm->{"m_total"};

    # Populate hashes of values for indicators, questions, attributes.
    if (defined($coef)) {
	if ($raw_qm->{"type"} =~ m!attribute!) {
	    $attrs_ref->{$mnemo} = $coef;
	    $attrs_ref_conf->{$mnemo} = $confidence;
	} elsif ($raw_qm->{"type"} =~ m!concept!) {
	    $questions_ref->{$mnemo} = $coef;
	    $questions_ref_conf->{$mnemo} = $confidence;
	} elsif ($raw_qm->{"type"} =~ m!metric!) {
	    $inds_ref->{$mnemo} = $coef;
	    $inds_ref_conf->{$mnemo} = $confidence;
	}
    }
    
    my $tmp_coef = $coef || "undef";

    return $coef;
}

sub compute_inds {
    my $self = shift;

    my @log;

    push( @log, "  * Generating project data for [$project_id]." );

    my $raw_qm = $self->{app}->models->get_model();
    
    my %project_indicators;
    my %project_indicators_conf;
    my %project_questions;
    my %project_questions_conf;
    my %project_attrs;
    my %project_attrs_conf;

    push( @log, "    - Aggregating data from leaves up to attributes." );
    &aggregate_inds($raw_qm->{"children"}->[0], \%project_values, 
		    \%project_indicators, \%project_indicators_conf, 
		    \%project_questions, \%project_questions_conf, 
		    \%project_attrs, \%project_attrs_conf, $project_id);

    my $project_path = $self->{app}->config->{'dir_data'} . '/' . $project_id;
    push( @log, "    - Generating project indicators file.." );

    # Create headers for json file
    my $raw_indicators = {
        "name" => "Indicators for $project_id",
        "version" => "Last updated by Alambic dashboard on " . localtime(),
        "children" => \%project_indicators,
    };
    my $file_indicators = $project_path . '/' . $project_id . '_indicators.json';
    &write_data($file_indicators, $raw_indicators);

    push( @log, "    - Generating project questions file.." );

    # Create headers for json file
    my $raw_questions = {
        "name" => "Questions for $project_id",
        "version" => "Last updated by Alambic dashboard on " . localtime(),
        "children" => \%project_questions,
    };
    my $file_questions = $project_path . '/' . $project_id . '_questions.json';
    &write_data($file_questions, $raw_questions);

    # Create headers for json file
    my $raw_questions_conf = {
        "name" => "Questions confidence for $project_id",
        "version" => "Last updated by Alambic dashboard on " . localtime(),
        "children" => \%project_questions_conf,
    };
    my $file_questions_conf = $project_path . '/' . $project_id . '_questions_confidence.json';
    &write_data($file_questions_conf, $raw_questions_conf);

    push( @log, "    - Generating project attributes file.." );

    # Create headers for json file
    my $raw_attrs = {
        "name" => "Attributes for $project_id",
        "version" => "Last updated by Alambic dashboard on " . localtime(),
        "children" => \%project_attrs,
    };
    my $file_attrs = $project_path . '/' . $project_id . '_attributes.json';
    &write_data($file_attrs, $raw_attrs);

    # Create headers for json file
    my $raw_attrs_conf = {
        "name" => "Attributes confidence for $project_id",
        "version" => "Last updated by Alambic dashboard on " . localtime(),
        "children" => \%project_attrs_conf,
    };
    my $file_attrs_conf = $project_path . '/' . $project_id . '_attributes_confidence.json';
    &write_data($file_attrs_conf, $raw_attrs_conf);

    &populate_qm($raw_qm->{"children"}, 
		 \%project_attrs, 
		 \%project_questions, 
		 \%project_values, 
		 \%project_indicators);

    # And write json file with full qm for visualisation
    my $out_json = $project_path . '/' . $project_id . '_qm.json';
    &write_data($out_json, $raw_qm);

    # Reread all project files
    $self->{app}->projects->read_all_files();

    return \@log;
}

# Utility function to read files
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

# Utility function to write files
sub write_data($) {
    my $file = shift;
    my $content = shift;

    my $json = encode_json($content);
    do { 
        local $/;
        open my $fh, '>', $file or die "Could not open data file [$file].\n";
        print $fh $json;
        close $fh;
    };

    return 1;
}


1;
