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

package Alambic::Model::Plugins;

use warnings;
use strict;

use Module::Load;
use Data::Dumper;


require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(
  get_names_all
  get_conf_all
  get_list_plugins_pre
  get_list_plugins_cdata
  get_list_plugins_post
  get_list_plugins_global
  get_list_plugins_data
  get_list_plugins_metrics
  get_list_plugins_figs
  get_list_plugins_info
  get_list_plugins_recs
  get_list_plugins_viz
  get_plugin
  run_plugin
  run_post
  test
);


my %plugins;

# array of plugin ids ordered by type or ability.
my %plugins_type;
my %plugins_ability;

# Constructor to build a new Alambic::Model::Plugins object and 
# initialise the list of plugins.
sub new {
  my ($class) = @_;

  &_read_plugins();

  return bless {}, $class;
}


# Read plugins from files in the lib/Alambic/Plugins directory.
sub _read_plugins() {

  # Clean hashes before reading files.
  %plugins         = ();
  %plugins_type    = ();
  %plugins_ability = ();

  # Read plugins directory.
  my @plugins_list = <lib/Alambic/Plugins/*.pm>;
  foreach my $plugin_path (@plugins_list) {
    $plugin_path =~ m!lib/(.+).pm!;
    my $plugin = $1;
    $plugin =~ s!/!::!g;

    $plugin_path =~ m!.+/([^/\\]+).pm!;
    my $plugin_name = $1;

    autoload $plugin;

    my $conf = $plugin->get_conf();
    $plugins{$conf->{'id'}} = $plugin;
    push(@{$plugins_type{$conf->{'type'}}}, $conf->{'id'});
    foreach my $a (@{$conf->{'ability'}}) {
      push(@{$plugins_ability{$a}}, $conf->{'id'});
    }
  }
}


# Get a list of all plugins with their names.
#
# Returns a hash ref:
# {
#     'plugin1' => 'Plugin number 1',
#     'plugin2' => 'Plugin number 2',
# }
sub get_names_all() {
  my @list = keys %plugins;
  my %list;
  foreach my $p (@list) {
    $list{$p} = $plugins{$p}->get_conf()->{'name'};
  }

  return \%list;
}

# Get configuration hashes for all plugins.
# { 
#   'ProjectSummary' => {
#     'name' => 'Project summary',
#     'type' => 'post',
#     'provides_cdata' => [],
#     'provides_recs' => [],
#     'provides_data' => {},
#     'desc' => [
#       'The Project Summary plugin creates a bunch of exportable HTML snippets, images and badges.'
#     ],
#     'id' => 'ProjectSummary',
#     'provides_info' => [],
#     'params' => {},
#     'provides_figs' => {
#       'badge_qm' => 'A HTML snippet that displays main quality attributes.',
#       'badge_qm_viz' => 'A HTML snippet that displays the quality model visualisation.',
#     },
#     'provides_viz' => {
#       'badges.html' => 'Badges'
#     },
#     'ability' => [ 'figs', 'viz' ],
#     'provides_metrics' => {}
#   }
# }
sub get_conf_all() {
  my @list = keys %plugins;
  my %list;
  foreach my $p (@list) {
    $list{$p} = $plugins{$p}->get_conf();
  }

  return \%list;
}


# Get a list (array) of pre- plugin ids.
sub get_list_plugins_pre() {
  return $plugins_type{'pre'} || [];
}


# Get a list (array) of cdata- plugin ids.
sub get_list_plugins_cdata() {
  return $plugins_type{'cdata'} || [];
}


# Get a list (array) of post- plugin ids.
sub get_list_plugins_post() {
  return $plugins_type{'post'} || [];
}


# Get a list (array) of global- plugin ids.
sub get_list_plugins_global() {
  return $plugins_type{'global'} || [];
}


# Get a list (array) of plugin ids with data ability.
sub get_list_plugins_data() {
  return $plugins_ability{'data'} || [];
}


# Get a list (array) of plugin ids with metrics ability.
sub get_list_plugins_metrics() {
  return $plugins_ability{'metrics'} || [];
}


# Get a list (array) of plugin ids with figs ability.
sub get_list_plugins_figs() {
  return $plugins_ability{'figs'} || [];
}


# Get a list (array) of plugin ids with info ability.
sub get_list_plugins_info() {
  return $plugins_ability{'info'} || [];
}


# Get a list (array) of plugin ids with recs ability.
sub get_list_plugins_recs() {
  return $plugins_ability{'recs'} || [];
}


# Get a list (array) of plugin ids with viz ability.
sub get_list_plugins_viz() {
  return $plugins_ability{'viz'} || [];
}

# Get the Alambic::Plugins::Plugin object for the provided id.
sub get_plugin($) {
  my ($self, $plugin_id) = @_;

  return $plugins{$plugin_id};
}

# Run a specific pre plugin on a project.
sub run_plugin($$$) {
  my ($self, $project_id, $plugin_id, $conf) = @_;
  my $ret = $plugins{$plugin_id}->run_plugin($project_id, $conf);

  # Add the plugin ID to each rec.
  foreach my $rec (@{$ret->{'recs'} || []}) {
    $rec->{'src'} = $plugin_id;
  }

  return $ret;
}

# Run a specific post plugin on a project.
sub run_post($$$) {
  my ($self, $project_id, $plugin_id, $conf) = @_;

  my $ret = $plugins{$plugin_id}->run_post($project_id, $conf);
  return $ret;
}

1;



=encoding utf8

=head1 NAME

B<Alambic::Model::Plugins> - Interface to all plugins defined in Alambic.

=head1 SYNOPSIS

    my $plugins = Alambic::Model::Plugins->new();
    
    my $plugin_so = $plugins->get_plugin('StackOverflow');
    my $list_pre = $plugins->get_list_plugins_pre();

=head1 DESCRIPTION

B<Alambic::Model::Plugins> provides a complete interface to the Plugins management
of Alambic, with ability to get lists of plugins according to their type or 
ability. Also provides access to the plugin objects themselves.

=head1 METHODS

=head2 C<new()>

    my $plugins = Alambic::Model::Plugins->new();

Create a new L<Alambic::Model::Plugins> object and initialises it with the list of 
plugins on the file system (i.e. Alambic/Plugins/*.pm).

=head2 C<get_names_all()>

    my $names = $plugins->get_names_all();

Get a list of all plugins with their names. Returns a hash ref:

    {
      'plugin1' => 'Plugin number 1',
      'plugin2' => 'Plugin number 2',
    }

=head2 C<get_conf_all()>

    my $conf = $plugins->get_conf_all();

Get configuration hashes for all plugins.

    { 
      'ProjectSummary' => {
        'name' => 'Project summary',
        'type' => 'post',
        'provides_cdata' => [],
        'provides_recs' => [],
        'provides_data' => {},
        'desc' => [
          'The Project Summary plugin creates a bunch of exportable HTML snippets, images and badges.'
        ],
        'id' => 'ProjectSummary',
        'provides_info' => [],
        'params' => {},
        'provides_figs' => {
          'badge_qm' => 'A HTML snippet that displays main quality attributes.',
          'badge_qm_viz' => 'A HTML snippet that displays the quality model visualisation.',
        },
        'provides_viz' => {
          'badges.html' => 'Badges'
        },
        'ability' => [ 'figs', 'viz' ],
        'provides_metrics' => {}
      }
    }

=head2 C<get_list_plugins_pre()>

    my $list = $plugins->get_list_plugins_pre();

Get a list (array) of all pre- plugin ids.

=head2 C<get_list_plugins_cdata()>

    my $list = $plugins->get_list_plugins_cdata();

Get a list (array) of all cdata- plugin ids.

=head2 C<get_list_plugins_post()>

    my $list = $plugins->get_list_plugins_post();

Get a list (array) of all post- plugin ids.

=head2 C<get_list_plugins_global()>

    my $list = $plugins->get_list_plugins_global();

Get a list (array) of all global- plugin ids.

=head2 C<get_list_plugins_data()>

    my $list = $plugins->get_list_plugins_data();

Get a list (array of ids) of all plugins with 'data' ability.

=head2 C<get_list_plugins_metrics()>

    my $list = $plugins->get_list_plugins_metrics();

Get a list (array of ids) of all plugins with 'metrics' ability.

=head2 C<get_list_plugins_figs()>

    my $list = $plugins->get_list_plugins_figs();

Get a list (array of ids) of all plugins with 'figs' ability.

=head2 C<get_list_plugins_info()>

    my $list = $plugins->get_list_plugins_info();

Get a list (array of ids) of all plugins with 'info' ability.

=head2 C<get_list_plugins_recs()>

    my $list = $plugins->get_list_plugins_recs();

Get a list (array of ids) of all plugins with 'recs' ability.

=head2 C<get_list_plugins_viz()>

    my $list = $plugins->get_list_plugins_viz();

Get a list (array of ids) of all plugins with 'viz' ability.

=head2 C<get_plugin()>

    my $conf = $plugins->get_plugin('StackOverflow')->get_conf();

Get the Alambic::Plugins::Plugin object for the provided id.

=head2 C<run_plugin()>

    my $results = $plugins->run_plugin(
      'modeling.sirius', 
      'StackOverflow', 
      $conf
    );

Run a specific pre plugin on a project.

=head2 C<run_post()>

    my $results = $plugins->run_post(
      'modeling.sirius', 
      'ProjectSummary', 
      $conf
    );

Run a specific post plugin on a project.

=head1 SEE ALSO

L<Mojolicious>, L<http://alambic.io>, L<https://bitbucket.org/BorisBaldassari/alambic>

=cut

