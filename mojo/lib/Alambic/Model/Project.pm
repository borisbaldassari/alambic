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

package Alambic::Model::Project;

use warnings;
use strict;

use Data::Dumper;
use Text::CSV;

use Alambic::Model::Plugins;
use Alambic::Model::RepoFS;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(
  get_id
  name
  desc
  get_plugins
  last_run
  active
  info
  metrics
  indicators
  attributes
  attributes_conf
  recs
  get_qm
  run_plugin
  run_plugins
  run_qm
  run_post
  run_posts
  run_project
);

######################################
# Data associated with a project
my ($project_name, $project_id, $project_desc);
my $project_active   = 0;
my $project_last_run = '';

my %plugins = ();

# my %plugins = (
#     "plugin_id1" => {
# 	"param1" => "value1",
# 	"param2" => "value2",
#     },
#     );

my %info            = ();
my %metrics         = ();
my %indicators      = ();
my %attributes      = ();
my %attributes_conf = ();
my @recs            = ();
######################################

# A ref to the Plugins module.
my $plugins_module;

# Constructor to create a new Alambic::Model::Project object.
sub new {
  my ($class, $id, $name, $active, $last_run, $plugins, $data) = @_;

  $project_id       = $id;
  $project_name     = $name;
  $project_active   = $active;
  $project_last_run = $last_run;

  $plugins_module = Alambic::Model::Plugins->new();

  # Populate the plugins hash with init data.
  %plugins = ();
  if (defined($plugins)) {
    foreach my $plugin_id (keys %{$plugins}) {
      $plugins{$plugin_id} = $plugins->{$plugin_id};
    }
  }

  # Populate the metrics, indicators and attributes hashes with init data.
  %info            = ();
  %metrics         = ();
  %indicators      = ();
  %attributes      = ();
  %attributes_conf = ();
  @recs            = ();
  if (defined($data)) {
    %info            = %{$data->{'info'}            || {}};
    %metrics         = %{$data->{'metrics'}         || {}};
    %indicators      = %{$data->{'indicators'}      || {}};
    %attributes      = %{$data->{'attributes'}      || {}};
    %attributes_conf = %{$data->{'attributes_conf'} || {}};
    @recs            = @{$data->{'recs'}            || []};
  }

  return bless {}, $class;
}

# Get project ID.
sub get_id() {
  return $project_id;
}

# Get or set the project name.
sub name() {
  my ($self, $name) = @_;

  if (scalar @_ > 1) {
    $project_name = $name;
  }

  return $project_name;
}

# Get or set the project description.
sub desc() {
  my ($self, $desc) = @_;

  if (scalar @_ > 1) {
    $project_desc = $desc;
  }

  return $project_desc;
}

# Get or set the active flag for the project.
sub active() {
  my ($self, $active) = @_;

  if (scalar @_ > 1) {
    $project_active = $active;
  }

  return $project_active;
}

# Return results from the last run of the project.
sub last_run() {
  my ($self, $last_run) = @_;

  if (scalar @_ > 1) {
    $project_last_run = $last_run;
  }

  return $project_last_run;
}

# Return the list of plugins defined on the project.
sub get_plugins() {
  return \%plugins;
}

# Return the populated quality model with values.
sub get_qm($) {
  my ($self, $qm, $attributes, $metrics) = @_;

  &_populate_qm($qm, $attributes, $metrics);

  return $qm;
}

# Get or set the list of current 'info' on the project.
sub info() {
  my ($self, $info) = @_;

  %info = %{$info} if (scalar @_ > 1);

  return \%info;
}

# Get or set the list of current 'metrics' on the project.
sub metrics() {
  my ($self, $metrics) = @_;

  %metrics = %{$metrics} if (scalar @_ > 1);

  return \%metrics;
}

# Get or set the list of current indicators on the project.
sub indicators() {
  my ($self, $indicators) = @_;

  %indicators = %{$indicators} if (scalar @_ > 1);

  return \%indicators;
}

# Get or set the list of 'attributes' on the project.
sub attributes() {
  my ($self, $attributes) = @_;

  %attributes = %{$attributes} if (scalar @_ > 1);

  return \%attributes;
}

# Get or set the list of attributes confidence on the project.
sub attributes_conf() {
  my ($self, $attributes_conf) = @_;

  %attributes_conf = %{$attributes_conf} if (scalar @_ > 1);

  return \%attributes_conf;
}

# Get or set the list of 'recs' on the project.
sub recs() {
  my ($self, $recs) = @_;

  @recs = @{$recs} if (scalar @_ > 1);

  return \@recs;
}


# Runs a pre-type plugin and returns result.
#
# Params:
#   - $plugin_id the plugin id to execute.
sub run_plugin($) {
  my ($self, $plugin_id) = @_;

  my $ret = $plugins_module->run_plugin($project_id, $plugin_id,
    $plugins{$plugin_id});

  foreach my $info (sort keys %{$ret->{'info'}}) {
    $info{$info} = $ret->{'info'}{$info};
  }

  foreach my $metric (sort keys %{$ret->{'metrics'}}) {
    $metrics{$metric} = $ret->{'metrics'}{$metric};
  }

  foreach my $rec (@{$ret->{'recs'}}) {
    push(@recs, $rec);
  }

  return $ret;
}


# Runs all pre-type plugins and returns result.
sub run_plugins() {
  my ($self) = @_;

  my @log;

  my $list = $plugins_module->get_list_plugins_pre();
  my @pre_plugins = sort grep ($plugins{$_}, @$list);
  foreach my $plugin_id (@pre_plugins) {
    my $ret = $plugins_module->run_plugin($project_id, $plugin_id,
      $plugins{$plugin_id});

    foreach my $info (sort keys %{$ret->{'info'}}) {
      $info{$info} = $ret->{'info'}{$info};
    }
    foreach my $metric (sort keys %{$ret->{'metrics'}}) {
      $metrics{$metric} = $ret->{'metrics'}{$metric};
    }
    foreach my $rec (@{$ret->{'recs'}}) { push(@recs, $rec); }
    @log = (@log, @{$ret->{'log'}});
  }

  return {
    "info"    => \%info,
    "metrics" => \%metrics,
    "recs"    => \@recs,
    "log"     => \@log
  };
}


# Run a qm analysis: generate indicators and attributes for the project.
#
# Params:
#   - $models a ref to a Models.pm object
sub run_qm($) {
  my $self   = shift;
  my $models = shift;

  my $ret = &_compute_inds($models);
  %attributes = %{$ret->{'attrs'}};
  %indicators = %{$ret->{'inds'}};

  return $ret;
}


# Run a single post plugin for this project
#
# Params:
#   - $plugin_id the identifier of the post plugin to be executed
#   - $models a ref to a Models.pm object
sub run_post() {
  my ($self, $plugin_id, $models) = @_;

  my $ret;
  my $main = {"last_run" => $project_last_run,};

  # If plugin is a type post
  my $conf = {'main' => $main, 'project' => $self, 'models' => $models,};

  $ret = $plugins_module->run_post($project_id, $plugin_id, $conf);

  # Add retrieved values to the current project.
  foreach my $info (sort keys %{$ret->{'info'}}) {
    $info{$info} = $ret->{'info'}{$info};
  }
  foreach my $metric (sort keys %{$ret->{'metrics'}}) {
    $metrics{$metric} = $ret->{'metrics'}{$metric};
  }
  foreach my $rec (@{$ret->{'recs'}}) { push(@recs, $rec); }

  return $ret;

}


# Run all post plugins for this project
#
# Params:
#   - $models a ref to a Models.pm object
sub run_posts() {
  my ($self, $models) = @_;

  my @log;

  my $conf = {'last_run' => $project_last_run, 'project' => $self,
    'models' => $models,};
  my @post_plugins
    = sort
    grep { $plugins_module->get_plugin($_)->get_conf()->{'type'} =~ /^post$/ }
    keys %plugins;
  my $ret;
  foreach my $plugin_id (@post_plugins) {
    my $ret_plugin = $plugins_module->run_post($project_id, $plugin_id, $conf);

    # Add retrieved values to the current project.
    foreach my $info (sort keys %{$ret_plugin->{'info'}}) {
      $info{$info} = $ret_plugin->{'info'}{$info};
    }
    foreach my $metric (sort keys %{$ret_plugin->{'metrics'}}) {
      $metrics{$metric} = $ret_plugin->{'metrics'}{$metric};
    }
    foreach my $rec (@{$ret_plugin->{'recs'}}) { push(@recs, $rec); }
    @log = (@log, @{$ret_plugin->{'log'}});
  }

  return {
    "info"    => \%info,
    "metrics" => \%metrics,
    "recs"    => \@recs,
    "log"     => \@log,
  };
}


# Run a full project analysis: run plugins, qm, and post.
#
# Params:
#   $models a ref to a Models.pm object
sub run_project($) {
  my ($self, $models, $job) = @_;

  # Initialise current data before new run.
  %info            = ();
  %metrics         = ();
  %indicators      = ();
  %attributes      = ();
  %attributes_conf = ();
  @recs            = ();

  my %ret;
  $ret{'log'} = ['[Model::Project] Start Project run.'];

  # Run plugins
  $job->note( 'status' => "Running pre plugins.");
  my $list = $plugins_module->get_list_plugins_pre();
  my @pre_plugins = sort grep ($plugins{$_}, @$list);
  foreach my $plugin_id (@pre_plugins) {
    $job->note( 'status' => "Executing pre plugin $plugin_id." );
    my $ret_p = $plugins_module->run_plugin($project_id, $plugin_id,
      $plugins{$plugin_id});

    foreach my $info (sort keys %{$ret_p->{'info'}}) {
      $ret{'info'}{$info} = $ret_p->{'info'}{$info};
      $info{$info} = $ret_p->{'info'}{$info};
    }
    foreach my $metric (sort keys %{$ret_p->{'metrics'}}) {
	$ret{'metrics'}{$metric} = $ret_p->{'metrics'}{$metric};
	$metrics{$metric} = $ret_p->{'metrics'}{$metric};
    }
    foreach my $rec (@{$ret_p->{'recs'}}) {
	push( @{$ret{'recs'}}, $rec );
	push( @recs, $rec );
    }
    push( @{$ret{'log'}}, @{$ret_p->{'log'}} );
  }

  # Run qm
  $job->note( 'status' => "Populating QM.");
  my $qm_data = $self->run_qm($models);

  foreach my $item (keys %{$qm_data}) {

    # Most children are hashes.
    if (defined($qm_data->{$item}) && ref($qm_data->{$item}) =~ /HASH/) {
      foreach my $value (keys %{$qm_data->{$item}}) {
        $ret{$item}{$value} = $qm_data->{$item}{$value};
      }
    }
    elsif (defined($qm_data->{$item}) && ref($qm_data->{$item}) =~ /ARRAY/) {

      # Some children are arrays (e.g. log)
      foreach my $value (@{$qm_data->{$item}}) {
        push(@{$ret{$item}}, $value);
      }
    }
  }

  # Create RepoFS object for writing and reading files on FS.
  my $repofs = Alambic::Model::RepoFS->new();

  $job->note( 'status' => "Writing files to disk." );

  # Create file with all metric definitions for project
  my $csv     = Text::CSV->new({binary => 1, eol => "\n"});
  my $csv_out = "Mnemo,Name,Description\n";
  my $metrics = $models->get_metrics();
  foreach my $metric (keys %$metrics) {
    my $desc = join(' ', @{$metrics->{$metric}{'description'}});
    my @metrics
      = ($metrics->{$metric}{'mnemo'}, $metrics->{$metric}{'name'}, $desc);
    $csv->combine(@metrics);
    $csv_out .= $csv->string();
  }

  # Write csv file to disk.
  $repofs->write_output($project_id, "metrics_ref.csv", $csv_out);


  # Create file with all attribute definitions for project
  $csv = Text::CSV->new({binary => 1, eol => "\n"});
  $csv_out = "Mnemo,Name,Description\n";
  my $attrs = $models->get_attributes();
  foreach my $attr (keys %$attrs) {
    my $desc = join(' ', @{$attrs->{$attr}{'description'}});
    my @attrs = ($attrs->{$attr}{'mnemo'}, $attrs->{$attr}{'name'}, $desc,);
    $csv->combine(@attrs);
    $csv_out .= $csv->string();
  }

  # Write csv file to disk.
  $repofs->write_output($project_id, "attrs_ref.csv", $csv_out);


  # Create a CSV file with all metric values
  $metrics = $self->metrics();
  $csv = Text::CSV->new({binary => 1, eol => "\n"});
  $csv->combine(('Mnemo', 'Value'));
  $csv_out = $csv->string();
  foreach my $metric (sort keys %$metrics) {
    $csv->combine(($metric, $metrics->{$metric}));
    $csv_out .= $csv->string();
  }

  # Write csv file to disk.
  $repofs->write_output($project_id, "metrics.csv", $csv_out);

  # Create a CSV file with all indicators values
  my $inds = $self->indicators();
  $csv = Text::CSV->new({binary => 1, eol => "\n"});
  $csv->combine(('Mnemo', 'Value'));
  $csv_out = $csv->string();
  foreach my $ind (sort keys %$inds) {
    $csv->combine(($ind, $inds->{$ind}));
    $csv_out .= $csv->string();
  }

  # Write csv file to disk.
  $repofs->write_output($project_id, "indics.csv", $csv_out);

  # Create a CSV file with all attribute values
  my $attributes = $self->attributes();
  $csv = Text::CSV->new({binary => 1, eol => "\n"});
  $csv->combine(('Mnemo', 'Value'));
  $csv_out = $csv->string();
  foreach my $attribute (sort keys %$attributes) {
    $csv->combine(($attribute, $attributes->{$attribute}));
    $csv_out .= $csv->string();
  }

  # Write csv file to disk.
  $repofs->write_output($project_id, "attributes.csv", $csv_out);


  # Run post plugins
  $job->note( 'status' => "Running post plugins.");
  my $post_list = $plugins_module->get_list_plugins_post();
  my @post_plugins = sort grep ($plugins{$_}, @$post_list);
  my $conf = {'last_run' => $project_last_run, 'project' => $self,
    'models' => $models,};
  my $ret;
  foreach my $plugin_id (@post_plugins) {
    $job->note( 'status' => "Running post plugin $plugin_id.");

    my $ret_plugin = $plugins_module->run_post($project_id, $plugin_id, $conf);

    # Add retrieved values to the current project.
    foreach my $info (sort keys %{$ret_plugin->{'info'}}) {
      $ret{'info'}{$info} = $ret_plugin->{'info'}{$info};
    }
    foreach my $metric (sort keys %{$ret_plugin->{'metrics'}}) {
      $ret{'metrics'}{$metric} = $ret_plugin->{'metrics'}{$metric};
    }
    foreach my $rec (@{$ret_plugin->{'recs'}}) { push( @{$ret{'recs'}}, $rec ); }
    push( @{$ret{'log'}}, @{$ret_plugin->{'log'}} );
  }

#  my $post_data = $self->run_posts($models) || {};
#  @{$ret{'log'}} = (@{$ret{'log'}}, @{$post_data->{'log'} || []});

  $job->note( 'status' => "Analysis completed.");

  return \%ret;
}


# Check if the scale is normal or reverse
sub _is_ordered_scale($) {
  my $scale = shift;

  my $scale_unsort  = join(' ', @{$scale});
  my $scale_sort    = join(' ', sort { $a <=> $b } @{$scale});
  my $scale_revsort = join(' ', sort { $b <=> $a } @{$scale});

  my $is_sorted;
  if ($scale_sort eq $scale_unsort) {
    $is_sorted = 1;
  }
  elsif ($scale_revsort eq $scale_unsort) {
    $is_sorted = 0;
  }
  else {
    $is_sorted
      = "ERROR: scale [" . $scale_unsort . "] is not right. Not using it.";
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
  if (defined($value)) {
    if ($is_sorted) {
      if    ($value < $scale->[0]) { $indicator = 1 }
      elsif ($value < $scale->[1]) { $indicator = 2 }
      elsif ($value < $scale->[2]) { $indicator = 3 }
      elsif ($value < $scale->[3]) { $indicator = 4 }
      else                         { $indicator = 5 }
    }
    else {
      if    ($value > $scale->[0]) { $indicator = 1 }
      elsif ($value > $scale->[1]) { $indicator = 2 }
      elsif ($value > $scale->[2]) { $indicator = 3 }
      elsif ($value > $scale->[3]) { $indicator = 4 }
      else                         { $indicator = 5 }
    }
  }

  return $indicator;
}


# Recursive function to compute aggregates of the quality model
# from the leafs up to the root.
sub _aggregate_inds($$$$$) {
  my $raw_qm         = shift;
  my $values         = shift;
  my $inds_ref       = shift;
  my $attrs_ref      = shift;
  my $attrs_ref_conf = shift;
  my $metrics        = shift;
  my $log            = shift;

  my $mnemo = $raw_qm->{"mnemo"} || '';
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
      my $child_value = &_aggregate_inds($child, $values, $inds_ref, $attrs_ref,
        $attrs_ref_conf, $metrics, $log);

      $tmp_m_total += $child->{"m_total"};
      $tmp_m_ok    += $child->{"m_ok"};
      if (defined($child_value)) {

        # If a problem arose, then dispatch it.
        if ($child_value !~ /^{\d.}+$/) {
          push(@{$log}, "ERROR during scale compute for $mnemo.");
        }
        if (exists($child->{"weight"})) {
          $full_weight += $child->{"weight"};
          push(@coefs, $child_value * $child->{"weight"});
        }
        else {
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
    $raw_qm->{"m_ok"}    = $tmp_m_ok;

  }
  else {
    # Yes: compute the ind value of leaf.

    if (not exists($metrics->{$mnemo})) {
      push(@$log, "ERROR: Metric $mnemo not found in metrics definition.");
      $raw_qm->{"m_total"} = 0;
      $raw_qm->{"m_ok"}    = 0;
      return 0;
    }

    $coef = &_compute_scale($values->{$mnemo}, $metrics->{$mnemo}{"scale"});
    $raw_qm->{"ind"} = $coef;

    my $raw_qm_active = 0;
    if (exists($raw_qm->{'active'}) && $raw_qm->{'active'} =~ m!true!) {
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

      }
      else {
        $raw_qm->{"m_ok"} = 0;
        push(@$log, "ERROR: Metric [$mnemo] could not be computed.");
      }
    }
    else {
      $raw_qm->{"m_total"} = 0;
      $raw_qm->{"m_ok"}    = 0;
    }

  }

  my $confidence
    = ($raw_qm->{"m_ok"} || 'x') . " / " . ($raw_qm->{"m_total"} || 'x');

  # Populate hashes of values for indicators, attributes.
  if (defined($coef)) {
    if ($raw_qm->{"type"} =~ m!attribute!) {
      $attrs_ref->{$mnemo}      = $coef;
      $attrs_ref_conf->{$mnemo} = $confidence;
    }
    elsif ($raw_qm->{"type"} =~ m!metric!) {
      $inds_ref->{$mnemo} = $coef;
    }
  }

  return $coef;
}

sub _compute_inds($) {
  my $models = shift;

  my $log;
  my %ret;

  my $raw_qm  = $models->get_qm();
  my $metrics = $models->get_metrics();
  my $project_indicators = {};
  my $project_attrs      = {};
  my $project_attrs_conf = {};

  push(@$log,
    "[Model::Project] Aggregating data from leaves up to attributes.");
  &_aggregate_inds($raw_qm->[0], \%metrics, $project_indicators,
    $project_attrs, $project_attrs_conf, $metrics, $log);

  $ret{'inds'}       = $project_indicators;
  $ret{'attrs'}      = $project_attrs;
  $ret{'attrs_conf'} = $project_attrs_conf;
  $ret{'log'}        = $log;

  return \%ret;
}


# Recursive function to populate the quality model with information from
# external files (metrics/questions/attributes definition).
#
# This function is for internal use only (no self passed as 1st argument).
#
# Params:
#   $qm a ref to an array of children
#   $attrs a ref to hash of values for attributes
#   $questions a ref to hash of values for questions
#   $metrics a ref to hash of values for metrics
#   $inds a ref to hash of indicators for metrics
sub _populate_qm($$$$$) {
  my $qm          = shift;
  my $attrs_def   = shift;
  my $metrics_def = shift;

  foreach my $child (@{$qm}) {
    my $mnemo = $child->{"mnemo"};

    if ($child->{"type"} =~ m!attribute!) {
      $child->{"name"} = $attrs_def->{$mnemo}{"name"};
      $child->{"ind"}  = $attributes{$mnemo};
    }
    elsif ($child->{"type"} =~ m!metric!) {
      $child->{"name"}  = $metrics_def->{$mnemo}{"name"};
      $child->{"value"} = eval sprintf("%.1f", $metrics{$mnemo} || 0);
      $child->{"ind"}   = $indicators{$mnemo};
    }
    else { print "WARN: cannot recognize type " . $child->{"type"} . "\n"; }

    if (exists($child->{"children"})) {
      &_populate_qm($child->{"children"}, $attrs_def, $metrics_def);
    }
  }
}


1;


=encoding utf8

=head1 NAME

B<Alambic::Model::Project> - Interface to all project-related actions and
information defined in Alambic.

=head1 SYNOPSIS

    my $project = Alambic::Model::Project->new(
      $id,
      $project_conf->{'name'},
      $project_conf->{'is_active'},
      $project_conf->{'last_run'},
      $project_conf->{'plugins'},
      $project_data
    );
    $project->desc('this is my desc');
    
    my $metrics = $project->metrics();

=head1 DESCRIPTION

B<Alambic::Model::Project> provides a complete interface to a project within 
Alambic. This includes information (metrics, attributes, configuration, etc.)
as well as actions (run_project, run_qm, run_plugins, etc.)

=head1 METHODS

=head2 C<new()>

    my $project = Alambic::Model::Project->new(
      $id,
      $project_conf->{'name'},
      $project_conf->{'is_active'},
      $project_conf->{'last_run'},
      $project_conf->{'plugins'},
      $project_data
    );
    
    my $project = Alambic::Model::Project->new($id, $name);
    $project->desc($desc);
    $project->active($active);

Create a new L<Alambic::Model::Project> object and optionally initialises it 
with all information.

=head2 C<get_id()>

    my $id = $project->get_id();

Get the ID of the project.

=head2 C<name()>

    my $name = $project->name();
    $project->name('My New Name');

Get or set the name of the project.

=head2 C<desc()>

    my $desc = $project->desc();
    $project->desc('My New Desc');

Get or set the description of the project.

=head2 C<active()>

    my $is_active = $project->active();
    $project->active(1);

Get or set the is_active flag on the project. Active projects are displayed
in the list of projects in the dashboard and menu.

=head2 C<last_run()>

    my $run = $project->last_run();

Return results from the last run of the project.

=head2 C<get_plugins()>

    my $plugins = $project->get_plugins();

Return the list of plugins defined on the project.

=head2 C<get_qm()>

    my $qm = $project->get_qm();

Return the populated quality model with values.

=head2 C<info()>

    my $info = $project->info();
    $project->info( {'PMI_TITLE' => 'Awesome Project'} );

Get or set the list of current 'info' on the project.

=head2 C<metrics()>

    my $metrics = $project->metrics();
    $project->metrics( {'METRIC1' => '1433'} );

Get or set the list of current 'metrics' on the project.

=head2 C<indicators()>

    my $inds = $project->indicators();
    $project->indicators( {'IND1' => '3.2'} );

Get or set the list of current indicators on the project.

=head2 C<attributes()>

    my $attrs = $project->attributes();
    $project->attributes( {'ATTR1' => '3.2'} );

Get or set the list of current 'attributes' on the project.

=head2 C<attributes_conf()>

    my $attrs_conf = $project->attributes_conf();
    $project->attributes_conf( {'ATTR1' => '2 / 2'} );

Get or set the list of current attributes confidence on the project.

=head2 C<recs()>

    my $recs = $project->recs();
    $project->recs(
      {
        'rid' => 'PMI_EMPTY_TITLE',
        'src' => 'EclipsePmi',
        'severity' => 2,
        'desc' => 'The title entry is empty in the PMI.'
      }
    )

Get or set the list of 'recs' on the project.

=head2 C<run_plugin()>

    my $results = $project->run_plugin('EclipsePmi');

Runs a pre-type plugin and returns result.

    {
      "info"    => \%info,
      "metrics" => \%metrics,
      "recs"    => \@recs,
      "log"     => \@log
    }

=head2 C<run_plugins()>

    my $results = $project->run_plugin();

Runs all pre-type plugins and returns result.

    {
      'info'    => \%info,
      'metrics' => \%metrics,
      'recs'    => \@recs,
      'log'     => \@log
    }

=head2 C<run_qm()>

    my $models = $alambic->get_models();
    my $results = $project->run_qm($models);

Run a qm analysis: generate indicators and attributes for the project.

    {
      'log' => [ '[Model::Project] Aggregating data from leaves up to attributes.' ],
      'inds' => {
        'PMI_SCM_INFO' => 1,
        'PMI_ITS_INFO' => 5
      },
      'attrs' => { 'ATTR1' => '3.0' }
      'attrs_conf' => { 'ATTR1' => '2 / 2' },
    };

=head2 C<run_post()>

    my $models = $alambic->get_models();
    my $results = $project->run_post('ProjectSummary', $models);

Run a specific post plugin for this project and returns results.

    {
      'info'    => \%info,
      'metrics' => \%metrics,
      'recs'    => \@recs,
      'log'     => \@log
    }

=head2 C<run_posts()>

    my $models = $alambic->get_models();
    my $results = $project->run_posts($models);

Run all post plugins for this project and returns results.

    {
      'info'    => \%info,
      'metrics' => \%metrics,
      'recs'    => \@recs,
      'log'     => \@log
    }

=head2 C<run_project()>

    my $models = $alambic->get_models();
    my $results = $project->run_project($models);


Run a full project analysis: run plugins, qm, and post.

    {
      'info'    => \%info,
      'metrics' => \%metrics,
      'recs'    => \@recs,
      'log'     => \@log
    }

=head1 SEE ALSO

L<Mojolicious>, L<http://alambic.io>, L<https://bitbucket.org/BorisBaldassari/alambic>

=cut

