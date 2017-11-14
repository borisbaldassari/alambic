#########################################################
#
# Copyright (c) 2015-2017 Castalia Solutions and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
#
# Contributors:
#   Boris Baldassari - Castalia Solutions
#
#########################################################

package Alambic::Model::Models;

use warnings;
use strict;

use Scalar::Util 'weaken';
use List::MoreUtils qw(uniq);
use Data::Dumper;


require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(
  init_models
  get_attribute
  get_attributes
  get_attributes_full
  get_metric
  get_metrics
  get_metrics_active
  get_metrics_repos
  get_metrics_full
  get_qm
  get_qm_full
);


my %metrics;
my %metrics_ds;
my @metrics_active;
my $metrics_total = 0;

my %attributes;
my $model;

# Create a new Models object and initialise it with a set of
# metrics, attributes, quality model and plugins.
sub new {
  my $class         = shift;
  my $in_metrics    = shift || {};
  my $in_attributes = shift || {};
  my $in_qm         = shift || [];
  my $in_plugins    = shift || {};

  &_init_metrics($in_metrics, $in_qm, $in_plugins);
  %attributes = %$in_attributes;
  $model      = $in_qm;

  return bless {}, $class;
}

# Another way to initialise the model after the object creation:
# read and set the metrics, attributes, qm and plugins from here.
sub init_models($$$$) {
  my $self          = shift;
  my $in_metrics    = shift || {};
  my $in_attributes = shift || {};
  my $in_qm         = shift || [];
  my $in_plugins    = shift || {};

  %metrics        = ();
  %attributes     = ();
  $metrics_total  = 0;
  %metrics_ds     = ();
  @metrics_active = ();

  &_init_metrics($in_metrics, $in_qm, $in_plugins);
  %attributes = %$in_attributes;
  $model      = $in_qm;
}

# Add used, parents nodes to metrics definition.
sub _init_metrics($) {
  my $in_metrics = shift;
  my $in_model   = shift;
  my $in_plugins = shift;

  # Import metrics and enhance their defition (add is_used)
  foreach my $tmp_metric (keys %$in_metrics) {

    # Check if the metric is used in the qm
    my @nodes_array;

    # Find nodes of qm which have the same mnemonic.
    &_find_qm_node($in_model, "metric", $tmp_metric, \@nodes_array, "root");
    my %tmp_nodes;
    foreach my $node (@nodes_array) {
      if (defined($node->{"father"})) {
        $tmp_nodes{$node->{"father"}}++;
      }

      my $used = $node->{"used"} || '';
      if ($used =~ m!true!i) {
        $in_metrics->{$tmp_metric}->{"used"} = "true";
      }
      else {
        $in_metrics->{$tmp_metric}->{"used"} = "false";
      }
    }
    $in_metrics->{$tmp_metric}->{"parents"} = \%tmp_nodes;

    $metrics_total++;
    $metrics{$tmp_metric} = $in_metrics->{$tmp_metric};

    # Populate @metrics_active
    push(@metrics_active, $tmp_metric);
  }

  # Now build the list of data sources by reading through
  # plugins and assigning each metric its plugin.
  foreach my $pi_ref (keys %$in_plugins) {
    my $pi_conf = $in_plugins->{$pi_ref};
    foreach my $metric (keys %{$pi_conf->{'provides_metrics'}}) {
      my $metric_map = $pi_conf->{'provides_metrics'}{$metric};
      if (exists($metrics{$metric_map})) {
        $metrics_ds{$pi_conf->{'id'}}++;
        $metrics{$metric_map}{'ds'} = $pi_conf->{'id'};
      }
    }
  }

}


# Find and return a specific mnemo in the quality model tree.
# The function can return zero, one or more nodes.
# This is a recursive method!
sub _find_qm_node($$$$) {
  my $raw_qm_array = shift;
  my $type         = shift;
  my $mnemo        = shift;
  my $nodes_array  = shift;
  my $father_mnemo = shift;

  foreach my $child (@{$raw_qm_array}) {
    if (($child->{"type"} eq $type) and ($child->{"mnemo"} eq $mnemo)) {
      $child->{"father"} = $father_mnemo;
      push(@{$nodes_array}, $child);
      next;
    }
    if (exists($child->{"children"})) {
      &_find_qm_node($child->{"children"}, $type, $mnemo, $nodes_array,
        $child->{"mnemo"});
    }
    else {
    }
  }
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
  my $qm        = shift;
  my $l_attrs   = shift;
  my $l_metrics = shift;
  my $l_inds    = shift;

  foreach my $child (@{$qm}) {
    my $mnemo = $child->{"mnemo"};

    if ($child->{"type"} =~ m!attribute!) {
      $child->{"name"} = $attributes{$mnemo}{"name"};
      $child->{"ind"}  = $l_attrs->{$mnemo};
    }
    elsif ($child->{"type"} =~ m!metric!) {
      $child->{"name"}  = $metrics{$mnemo}{"name"};
      $child->{"value"} = eval sprintf("%.1f", $l_metrics->{$mnemo} || 0);
      $child->{"ind"}   = $l_inds->{$mnemo};
    }
    else { print "WARN: cannot recognize type " . $child->{"type"} . "\n"; }

    if (exists($child->{"children"})) {
      &_populate_qm($child->{"children"}, $l_attrs, $l_metrics, $l_inds);
    }
  }
}

# Utility to find all node mnemos in the qm tree
# sub _find_nodes($) {
#     my $nodes = shift;

#     my @nodes_ret;
#     foreach my $node (@{$nodes}) {
# 	my $mnemo = $node->{'mnemo'};
# 	push(@nodes_ret, $mnemo);
# 	if (exists($node->{'children'})) {
# 	    my @nodes_new = &_find_nodes($node->{'children'});
# 	    push(@nodes_ret, @{nodes_new});
# 	}
#     }

#     return uniq(@nodes_ret);
# }


# Returns information about a single metric.
#
# Params:
#  - $metric the id of the requested metric
#
# Returns:
# {
#     'active' => 'false',
#     'desc' => [ 'Desc' ],
# 	'mnemo' => 'METRIC1',
# 	'ds' => 'EclipseIts',
#       'scale' => [1, 2, 3, 4],
# 	    'name' => 'Metric 1',
# 	    'parents' => {
# 		'ATTR1' => 1
# 	}
# }
sub get_metric($) {
  my ($self, $metric) = @_;
  return $metrics{$metric};
}


# Returns information about all metrics.
#
# Returns:
# {
#     'METRIC1' => {
# 	'active' => 'false',
# 	'desc' => [ 'Desc' ],
# 	    'mnemo' => 'METRIC1',
# 	    'ds' => 'EclipseIts',
# 	    'scale' => [1, 2, 3, 4],
# 		'name' => 'Metric 1',
# 		'parents' => {
# 		    'ATTR1' => 1
# 	    }
#     }
# };
sub get_metrics() {
  return \%metrics;
}

# Get list of metrics with information and headers.
sub get_metrics_full() {
  my %full = (
    'name'     => "Alambic Metrics",
    'version'  => "" . localtime(),
    'children' => \%metrics,
  );

  return \%full;
}

# Returns a list of the active metrics, i.e. metrics defined and
# used in the quality model. It is an array of metric ids.
sub get_metrics_active() {
  return \@metrics_active;
}

# Get a list of all data providers (plugins).
sub get_metrics_repos() {
  return \%metrics_ds;
}

# Get information about a single attribute.
#
#  {
#    'name' => 'Diversity',
#    'description' => [ 'The diversity of the project\'s ecosystem, as measured..' ],
#    'mnemo' => 'QM_DIVERSITY'
#  };
sub get_attribute($) {
  my ($self, $attr) = @_;

  return $attributes{$attr};
}

# Return the list of all attributes with their information.
sub get_attributes() {
  return \%attributes;
}

# Return the list of all attributes with their information and headers.
sub get_attributes_full() {
  my %full = (
    'name'     => "Alambic Attributes",
    'version'  => "" . localtime(),
    'children' => \%attributes,
  );

  return \%full;
}

# Get Quality Model description (without headers).
sub get_qm() {
  return $model;
}


# Get the full quality model for the documentation visualisation.
# This includes the quality model, with attributes and metrics and
# their values. Also includes headers.
sub get_qm_full() {
  my $self = shift;

  my $qm_full_children = $model;

  # Create a rich version of the quality model with all info on nodes.
  &_populate_qm($qm_full_children, undef, undef, undef, undef);

  my $qm_full = {
    "name"     => "Alambic Full Quality Model",
    "version"  => "" . localtime(),
    "children" => $qm_full_children,
  };

  return $qm_full;
}


1;


=encoding utf8

=head1 NAME

B<Alambic::Model::Models> - Interface to all models definition: metrics, 
attributes, quality model, and links to data providers.

=head1 SYNOPSIS

    my $models = Alambic::Model::Models->new(
      $metrics, $attributes, $qm, $plugins
    );
    
    my $qm_full = $models->get_qm_full();
    my $metrics = $models->get_metrics();
    my $metric = $models->get_metric('NCLOC');

=head1 DESCRIPTION

B<Alambic::Model::Models> provides a complete interface to the Models used behind the Alambic
application: metrics definition, quality attribute definition, quality model tree, etc. 

=head1 METHODS

=head2 C<new()>

    my $models = Alambic::Model::Models->new(
      $metrics, $attributes, $qm, $plugins
    );

Create a new L<Alambic::Model::Models> object and initialises it with provided metrics, 
attributes, quality model and plugins (i.e. data providers).

=head2 C<init_models()>

    my $models = Alambic::Model::Models->new();
    $models = ->init_models( $metrics, $attributes, 
      $qm, $plugins->get_conf_all());
    );

Another way to initialise the model after the object creation:
read and set the metrics, attributes, qm and plugins from here.

=head2 C<get_metric()>

    my $metric = $models->get_metric('NCLOC');

Returns information about a single metric. Returns a hash reference:

    {
      'active' => 'false',
      'desc' => [ 'Desc' ],
        'mnemo' => 'METRIC1',
        'ds' => 'EclipseIts',
        'scale' => [1, 2, 3, 4],
     	'name' => 'Metric 1',
     	'parents' => {
     	    'ATTR1' => 1
      }
    }

=head2 C<get_metrics()>

    my $metrics = $models->get_metrics();

Returns information about all metrics. Returns a hash reference:

    {
      'METRIC1' => {
        'active' => 'false',
        'desc' => [ 'Desc' ],
          'mnemo' => 'METRIC1',
          'ds' => 'EclipseIts',
          'scale' => [1, 2, 3, 4],
       	'name' => 'Metric 1',
       	'parents' => {
       	    'ATTR1' => 1
        }
      }
    }

=head2 C<get_metrics_full()>

    my $metrics_full = $models->get_metrics_full();

Get list of metrics with information and headers.

=head2 C<get_metrics_active()>

    my $list = $models->get_metrics_active();
    foreach my $m (@$list) { say $models->get_metric($m); }

Returns a list of the active metrics, i.e. metrics defined and
used in the quality model. It is an array of metric ids.

=head2 C<get_metrics_repos()>

    my $repos = $models->get_metrics_repos();

Get a list of all data providers (plugins). Returns a array reference.

=head2 C<get_attribute()>

    my $attr = $models->get_attribute('QM_ECOSYSTEM');

Get information about a single attribute.

    {
      'name' => 'Diversity',
      'description' => [ 'The diversity of the project\'s ecosystem, as measured..' ],
      'mnemo' => 'QM_DIVERSITY'
    };

=head2 C<get_attributes()>

    my $attrs = $models->get_attributes();

Get information about all attributes.

    {
      'ATTR1' => {
        'name' => 'Attribute 1',
        'mnemo' => 'ATTR1',
        'desc' => [
          'Desc'
        ]
      }
    }

=head2 C<get_attributes_full()>

    my $attrs = $models->get_attributes_full();

Get information about all attributes and headers.

    {
      'name' => 'Alambic Attributes',
      'version' => 'Sun Jul 30 10:16:57 2017',
      'children' => {
        'ATTR1' => {
          'name' => 'Attribute 1',
          'mnemo' => 'ATTR1',
          'desc' => [
            'Desc'
          ]
        }
      }
    }

=head2 C<get_qm()>

    my $qm = $models->get_qm();

Get Quality Model description (without headers).

=head2 C<get_qm_full()>

    my $qm = $models->get_qm_full();

Get the full quality model for the documentation visualisation.
This includes the quality model, with attributes and metrics and
their values. Also includes headers.

=head1 SEE ALSO

L<Mojolicious>, L<http://alambic.io>, L<https://bitbucket.org/BorisBaldassari/alambic>

=cut

