#! perl -I../../lib/
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


use strict;
use warnings;

use Alambic::Model::Project;
use Alambic::Model::Models;

use Test::More;
use Mojo::JSON qw( decode_json);
use Data::Dumper;

BEGIN { use_ok('Alambic::Plugins::ProjectSummary'); }

my $plugin = Alambic::Plugins::ProjectSummary->new();
isa_ok($plugin, 'Alambic::Plugins::ProjectSummary');

note("Checking the plugin parameters. ");
my $conf = $plugin->get_conf();

ok(grep(m!metrics!, @{$conf->{'ability'}}) == 0,
  "Conf has not ability > metrics");
ok(grep(m!info!, @{$conf->{'ability'}}) == 0, "Conf has not ability > info");
ok(grep(m!data!, @{$conf->{'ability'}}) == 0, "Conf has not ability > data");
ok(grep(m!recs!, @{$conf->{'ability'}}) == 0, "Conf has not ability > recs");
ok(grep(m!figs!, @{$conf->{'ability'}}),      "Conf has ability > figs");
ok(grep(m!viz!,  @{$conf->{'ability'}}),      "Conf has ability > viz");

ok(grep(m!badge_attr_alambic.svg!, keys %{$conf->{'provides_figs'}}),
  "Conf has provides_figs > badge_attr_alambic");

#ok( grep( m!psum_attrs.html!, keys %{$conf->{'provides_figs'}} ), "Conf has provides_figs > psum_attrs" );
ok(grep(m!badge_qm!, keys %{$conf->{'provides_figs'}}),
  "Conf has provides_figs > badge_qm");
ok(grep(m!badge_project_main!, keys %{$conf->{'provides_figs'}}),
  "Conf has provides_figs > badge_project_main");
ok(grep(m!badge_qm_viz!, keys %{$conf->{'provides_figs'}}),
  "Conf has provides_figs > badge_qm_viz");
ok(grep(m!badge_downloads!, keys %{$conf->{'provides_figs'}}),
  "Conf has provides_figs > badge_downloads");
ok(grep(m!badge_plugins!, keys %{$conf->{'provides_figs'}}),
  "Conf has provides_figs > badge_plugins");

ok(grep(m!badges.html!, keys %{$conf->{'provides_viz'}}),
  "Conf has provides_viz > badge_plugins");

# Execute the plugin
note("Execute the plugin with project test.project. ");

# Preparation: create the Models object
my $metrics = {
  'METRIC1' => {
    'mnemo' => "METRIC1",
    "name"  => "Metric 1",
    "desc"  => ["Desc"],
    "scale" => [1, 2, 3, 4]
  }
};
my $attributes
  = {
  'ATTR1' => {'mnemo' => "ATTR1", "name" => "Attribute 1", "desc" => ["Desc"],}
  };
my $qm = [
  {
    'mnemo'    => 'ATTR1',
    'type'     => 'attribute',
    'children' => [{'mnemo' => 'METRIC1', 'type' => 'metric'}]
  }
];
my $plugins = {
  'EclipseIts' => {
    'provides_data' =>
      {'metrics_its.json' => 'Metrics for the ITS plugin (JSON).',},
    'params'        => {'project_grim' => '',},
    'provides_recs' => ['ITS_CLOSE_BUGS',],
    'id'            => 'EclipseIts',
    'name'          => 'Eclipse ITS',
    'desc'          => ['Eclipse ITS description',],
    'ability' => ['metrics', 'recs', 'figs', 'viz',],
    'provides_figs'    => {'its_evol_ggplot.rmd' => 'its_evol_ggplot.html',},
    'provides_viz'     => {'eclipse_its.html'    => 'Eclipse ITS',},
    'provides_metrics' => {'METRIC1'             => 'METRIC1',},
    'provides_cdata'   => [],
    'provides_info'    => ['MLS_DEV',],
    'type'             => 'pre',
  }
};
my $models = Alambic::Model::Models->new($metrics, $attributes, $qm, $plugins);

# Preparation: create the Project object
my $plugins_conf = {"EclipsePmi" => {"project_pmi" => "test.project",}};
my $project
  = Alambic::Model::Project->new('test.project', 'Test project', 'TRUE', '',
  $plugins_conf);

my $conf_run = {
  'last_run' => '2017-02-27 15:28:06',
  'project'  => $project,
  'models'   => $models,
};

my $ret = $plugin->run_post("test.project", $conf_run);
ok(
  grep(/^\[Plugins::ProjectSummary\] Executing R snippet files./,
    @{$ret->{'log'}}) == 1,
  "Checking if log contains R snippet exec."
) or diag explain $ret;
ok(grep(/^\[Tools::R\] Exec \[Rsc.*psum_attrs.rmd/, @{$ret->{'log'}}) == 1,
  "Checking if log contains R code exec.")
  or diag explain $ret;
ok(
  grep(/^\[Plugins::ProjectSummary\] Executing R report./, @{$ret->{'log'}})
    == 1,
  "Checking if log contains R report exec."
) or diag explain $ret;
ok(grep(/^\[Tools::R\] Moved .*ret \[1\]./, @{$ret->{'log'}}) == 1,
  "Checking if log contains moved files.")
  or diag explain $ret;

# Check pmi checks
note("Checking retrieved file. ");

# Check that files have been created.
note("Check that files have been created. ");

ok(-e "projects/test.project/output/test.project_badge_attr_alambic.svg",
  "Check that file badge_attr_alambic.svg exists.");

ok(-e "projects/test.project/output/test.project_badge_attr_Metric 1.svg",
  "Check that file badge_attr_Metric 1.svg exists.");

ok(-e "projects/test.project/output/test.project_badge_attr_root.svg",
  "Check that file badge_attr_root.svg exists.");

ok(-e "projects/test.project/output/test.project_badges.inc",
  "Check that file badges.inc exists.");


done_testing();
