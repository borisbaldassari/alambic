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
use File::Copy;
use File::Path qw(make_path remove_tree);

BEGIN { use_ok('Alambic::Plugins::GenericR'); }

my $plugin = Alambic::Plugins::GenericR->new();
isa_ok($plugin, 'Alambic::Plugins::GenericR');

note("Checking the plugin parameters. ");
my $conf = $plugin->get_conf();

ok(grep(m!metrics!, @{$conf->{'ability'}}) == 0,
  "Conf has not ability > metrics");
ok(grep(m!info!, @{$conf->{'ability'}}) == 0, "Conf has not ability > info");
ok(grep(m!figs!, @{$conf->{'ability'}}) == 0, "Conf has not ability > figs");
ok(grep(m!recs!, @{$conf->{'ability'}}) == 0, "Conf has not ability > recs");
ok(grep(m!viz!,  @{$conf->{'ability'}}) == 0, "Conf has not ability > viz");
ok(grep(m!data!, @{$conf->{'ability'}}),      "Conf has ability > data");

ok(grep(m!generic_r.pdf!, keys %{$conf->{'provides_data'}}),
  "Conf has provides_data > generic_r.pdf");

# Execute the plugin
note("Execute the plugin with project modeling.sirius. ");

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

# Prepare csv files required for the plugin
make_path('projects/modeling.sirius/output/');
copy "t/resources/modeling.sirius_metrics.csv",
  "projects/modeling.sirius/output/"
  or die "Cannot copy modeling.sirius_metrics.csv.";
copy "t/resources/modeling.sirius_metrics_ref.csv",
  "projects/modeling.sirius/output/"
  or die "Cannot copy modeling.sirius_metrics_ref.csv.";
copy "t/resources/modeling.sirius_indics.csv",
  "projects/modeling.sirius/output/"
  or die "Cannot copy modeling.sirius_indics.csv.";
copy "t/resources/modeling.sirius_attributes.csv",
  "projects/modeling.sirius/output/"
  or die "Cannot copy modeling.sirius_attributes.csv.";
copy "t/resources/modeling.sirius_attrs_ref.csv",
  "projects/modeling.sirius/output/"
  or die "Cannot copy modeling.sirius_attrs_ref.csv.";
copy "t/resources/modeling.sirius_git_commits.csv",
  "projects/modeling.sirius/output/"
  or die "Cannot copy modeling.sirius_git_commits.csv.";

# Preparation: create the Project object
my $plugins_conf = {"EclipseIts" => {"project_grim" => "modeling.sirius",}};
my $project
  = Alambic::Model::Project->new('modeling.sirius', 'Test project GenericR',
  'TRUE', '', $plugins_conf);

my $conf_run = {
  'last_run' => '2017-02-27 15:28:06',
  'project'  => $project,
  'models'   => $models,
};

# Run all post plugins.
my $ret = $plugin->run_post("modeling.sirius", $conf_run);
ok(
  grep(/^\[Plugins::GenericR\] Start Generic R plugin execution./,
    @{$ret->{'log'}}) == 1,
  "Checking if log contains Generic R plugin exec."
) or diag explain $ret;
ok(
  grep(/^\[Plugins::GenericR\] Executing R pdf markdown document./,
    @{$ret->{'log'}}) == 1,
  "Checking if log contains R pdf exec."
) or diag explain $ret;
ok(grep(/^\[Tools::R\] Exec \[Rsc.*generic_r.Rmd/, @{$ret->{'log'}}) == 1,
  "Checking if log contains R code exec.")
  or diag explain $ret;

# Check that files have been created.
note("Check that files have been created. ");
ok(-e "projects/modeling.sirius/output/modeling.sirius_generic_r.pdf",
  "Check that file generic_r.pdf exists.");

done_testing();
