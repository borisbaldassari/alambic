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

use Alambic::Model::Models;
use Test::More;
use Data::Dumper;

BEGIN { use_ok('Alambic::Model::Project'); }

my $plugins_conf = {"EclipsePmi" => {"project_pmi" => "tools.cdt",}};

my $metrics = {
  'PMI_ITS_INFO' => {
    'mnemo' => "PMI_ITS_INFO",
    "name"  => "",
    "desc"  => ["Desc"],
    "scale" => [1, 2, 3, 4]
  },
  'PMI_SCM_INFO' => {
    "name"  => "SCM information",
    "mnemo" => "PMI_SCM_INFO",
    "desc" => ["Is the source_repo info correctly filled in the PMI records? "],
    "scale" => [1, 2, 3, 4]
  },
};

my $attributes
  = {
  'ATTR1' => {'mnemo' => "ATTR1", "name" => "Attribute 1", "desc" => ["Desc"],}
  };

my $qm = [
  {
    'mnemo'    => 'ATTR1',
    'active'   => 'true',
    'type'     => 'attribute',
    'children' => [
      {'mnemo' => 'PMI_ITS_INFO', 'active' => 'true', 'type' => 'metric'},
      {'mnemo' => 'PMI_SCM_INFO', 'active' => 'true', 'type' => 'metric'}
    ]
  }
];

my $plugins = {
  "EclipsePMI" => {
    "id"   => "EclipsePmi",
    "name" => "Eclipse PMI",
    "desc" => [
      "Eclipse PMI Retrieves meta data about the project from the Eclipse PMI infrastructure.",
      'See <a href="http://alambic.io/Plugins/Pre/EclipsePmi.html">the project\'s web site</a> for more information.',
    ],
    "type"    => "pre",
    "ability" => ["metrics", "info", 'data', "recs", "viz"],
    "params"  => {
      "project_pmi" =>
        "The project ID used to identify the project on the PMI server. Look for it in the URL of the project on <a href=\"http://projects.eclipse.org\">http://projects.eclipse.org</a>.",
    },
    "provides_cdata" => [],
    "provides_info"  => [
      "MLS_DEV_URL",             "MLS_USR_URL",
      "PMI_MAIN_URL",            "PMI_WIKI_URL",
      "PMI_BUGZILLA_CREATE_URL", "PMI_DOWNLOAD_URL",
      "PMI_SCM_URL",             "PMI_BUGZILLA_COMPONENT",
      "PMI_CI_URL",              "PMI_BUGZILLA_PRODUCT",
      "PMI_BUGZILLA_QUERY_URL",  "PMI_DOCUMENTATION_URL",
      "PMI_DESC",                "PMI_GETTINGSTARTED_URL",
      "PMI_TITLE",               "PMI_ID",
      "PMI_UPDATESITE_URL",
    ],
    "provides_data" => {
      "pmi.json" =>
        "The PMI file as returned by the Eclipse repository (JSON).",
      "pmi_checks.json" => "The list of PMI checks and their results (JSON).",
      "pmi_checks.csv"  => "The list of PMI checks and their results (CSV).",
    },
    "provides_metrics" => {
      "PMI_ITS_INFO" => "PMI_ITS_INFO",
      "PMI_SCM_INFO" => "PMI_SCM_INFO",
      "PMI_REL_VOL"  => "PMI_REL_VOL"
    },
    "provides_figs" => {},
    "provides_recs" => [
      "PMI_EMPTY_BUGZILLA_CREATE", "PMI_NOK_BUGZILLA_CREATE",
      "PMI_EMPTY_BUGZILLA_QUERY",  "PMI_NOK_BUGZILLA_QUERY",
      "PMI_EMPTY_TITLE",           "PMI_NOK_WEB",
      "PMI_EMPTY_WEB",             "PMI_NOK_WIKI",
      "PMI_EMPTY_WIKI",            "PMI_NOK_DOWNLOAD",
      "PMI_EMPTY_DOWNLOAD",        "PMI_NOK_GETTING_STARTED",
      "PMI_EMPTY_GETTING_STARTED", "PMI_NOK_DOC",
      "PMI_EMPTY_DOC",             "PMI_NOK_PLAN",
      "PMI_EMPTY_PLAN",            "PMI_NOK_PROPOSAL",
      "PMI_EMPTY_PROPOSAL",        "PMI_NOK_DEV_ML",
      "PMI_EMPTY_DEV_ML",          "PMI_NOK_USER_ML",
      "PMI_EMPTY_USER_ML",         "PMI_NOK_SCM",
      "PMI_EMPTY_SCM",             "PMI_NOK_UPDATE",
      "PMI_EMPTY_UPDATE",          "PMI_NOK_CI",
      "PMI_EMPTY_CI",              "PMI_EMPTY_REL",
    ],
    "provides_viz" => {"pmi_checks" => "Eclipse PMI Checks",},
  }
};

my $models = Alambic::Model::Models->new($metrics, $attributes, $qm, $plugins);

my $project = Alambic::Model::Project->new('tools.cdt', 'Tools CDT', 'TRUE', '',
  $plugins_conf);
isa_ok($project, 'Alambic::Model::Project');

my $id = $project->get_id();
ok($id =~ m!^tools.cdt$!, 'Project id is tools.cdt.') or diag explain $id;

my $name = $project->name();
ok($name =~ m!^Tools CDT$!, 'Project name is Tools CDT.') or diag explain $name;

note("Running EclipsePmi plugin.");
my $ret = $project->run_plugin('EclipsePmi');
$ret = $ret->{'log'};
ok(grep(/^ERROR/, @{$ret}) == 0, "Log has no error.") or diag explain $ret;
ok(grep(/^\[Plugins::EclipsePmi\] Using Eclipse PMI infra at/, @{$ret}) == 1,
  "Log has Starting retrieval.")
  or diag explain $ret;
ok(
  grep(/^\[Plugins::EclipsePmi\] Writing PMI json file to input./, @{$ret})
    == 1,
  "Log has Writing json file to input."
) or diag explain $ret;
ok(
  grep(/^\[Plugins::EclipsePmi\] Writing PMI checks json file to output/,
    @{$ret}) == 1,
  "Log has Writing json file to output."
) or diag explain $ret;
ok(
  grep(/^\[Plugins::EclipsePmi\] Writing PMI checks csv file to output/,
    @{$ret}) == 1,
  "Log has Writing csv file to output."
) or diag explain $ret;

# TODO introduce another R-related plugin (e.g. stackoverflow).
#ok( grep( /^\[Plugins::EclipsePmi\] Retrieving evol/, @{$ret} ) == 1,
#    "Log has Retrieving evol." ) or diag explain $ret;
#ok( grep( /^\[Plugins::EclipsePmi\] Executing R/, @{$ret} ) >= 1,
#    "Log has Executing R." ) or diag explain $ret;

# Check that files have been created.
# TODO uncomment when stackoverflow plugin is done.
#ok( -e "projects/tools.cdt/input/tools.cdt_import_its.json", "Check that file import_its.json exists." );
#ok( -e "projects/tools.cdt/input/tools.cdt_import_its_evol.json", "Check that file import_its_evol.json exists." );
#ok( -e "projects/tools.cdt/output/its_evol_changed.html", "Check that file its_evol_changed.html exists." );
#ok( -e "projects/tools.cdt/output/eclipse_its.inc", "Check that file EclipseIts.inc exists." );
#ok( -e "projects/tools.cdt/output/its_evol_opened.html", "Check that file its_evol_opened.html exists." );
#ok( -e "projects/tools.cdt/output/its_evol_people.html", "Check that file its_evol_people.html exists." );
#ok( -e "projects/tools.cdt/output/its_evol_summary.html", "Check that file its_evol_summary.html exists." );
#ok( -e "projects/tools.cdt/output/tools.cdt_metrics_its.json", "Check that file tools.cdt_metrics_its.json exists." );

note("Get metrics from project.");
$ret = $project->metrics();

#is( $ret->{'PMI_ITS_INFO'}, 2, "Number of trackers is 2." ) or diag explain $ret;
#is( $ret->{'PMI_ITS_INFO'}, 2, "Number of trackers is 2." ) or diag explain $ret;
#is( scalar grep( /ITS_CLOSED/, keys %{$ret} ), 4, "There should be 4 ITS_CLOSED_*." ) or diag explain $ret;
#is( scalar grep( /ITS_CLOSERS/, keys %{$ret} ), 4, "There should be 4 ITS_CLOSERS_*." ) or diag explain $ret;
#is( scalar grep( /ITS_DIFF_/, keys %{$ret} ), 6, "There should be 6 ITS_DIFF_*.") or diag explain $ret;
#is( scalar grep( /ITS_PERCENTAGE/, keys %{$ret} ), 6, "There should be 6 ITS_PERCENTAGE_*." ) or diag explain $ret;
ok(exists($ret->{'PMI_ITS_INFO'}),
  "There should be a metric called PMI_ITS_INFO.")
  or diag explain $ret;
ok(exists($ret->{'PMI_SCM_INFO'}),
  "There should be a metric called PMI_SCM_INFO.")
  or diag explain $ret;

#ok( exists($ret->{'ITS_OPENED'}), "There should be a metric called ITS_OPENED." ) or diag explain $ret;
#ok( exists($ret->{'ITS_OPENERS'}), "There should be a metric called ITS_OPENERS." ) or diag explain $ret;


note("Run plugins.");

$ret = $project->run_plugins();
ok(
  exists($ret->{'metrics'}{'PMI_ITS_INFO'}),
  "PMI_ITS_INFO metric exists in run after plugins."
) or diag explain $ret;
ok(
  exists($ret->{'metrics'}{'PMI_SCM_INFO'}),
  "PMI_ITS_INFO metric exists in run after plugins."
) or diag explain $ret;
ok($ret->{'recs'}[0]{'rid'} =~ m!PMI_EMPTY_TITLE!,
  "recs[0] is PMI_EMPTY_TITLE.")
  or diag explain $ret;
ok(
  $ret->{'recs'}[0]{'severity'} == 2,
  "recs[0] (PMI_EMPTY_TITLE) has severity 2."
) or diag explain $ret;
ok(
  $ret->{'recs'}[0]{'src'} =~ m!^EclipsePmi$!,
  "recs[0] (PMI_EMPTY_TITLE) has src EclipsePmi."
) or diag explain $ret;
ok($ret->{'recs'}[0]{'desc'} =~ m!^The title entry is empty in the PMI.$!,
  "recs[0] (PMI_EMPTY_TITLE) has correct description.")
  or diag explain $ret;
ok(
  $ret->{'info'}{'PMI_BUGZILLA_CREATE_URL'}
    =~ m!^https://bugs.eclipse.org/bugs/enter_bug.cgi\?product=CDT$!,
  "PMI_BUGZILLA_CREATE_URL info has url."
) or diag explain $ret;
ok(
  $ret->{'info'}{'PMI_WIKI_URL'} =~ m!^http://wiki.eclipse.org/index.php/CDT$!,
  "PMI_WIKI_URL info has url."
) or diag explain $ret;
ok($ret->{'info'}{'PMI_MAIN_URL'} =~ m!^http://www.eclipse.org/cdt$!,
  "PMI_MAIN_URL info has url.")
  or diag explain $ret;
ok(
  $ret->{'info'}{'PMI_DOWNLOAD_URL'}
    =~ m!^http://www.eclipse.org/cdt/downloads.php$!,
  "PMI_DOWNLOAD_URL info has url."
) or diag explain $ret;


note("Run qm.");
$ret = $project->run_qm($models);
ok(
  grep(/Aggregating data/, @{$ret->{'log'}}),
  "After qm run log has aggregating data."
) or diag explain $ret;
ok(
  exists($ret->{'attrs_conf'}{'ATTR1'}),
  "There should be an attribute called ATTR1."
) or diag explain $ret;
ok(
  $ret->{'attrs_conf'}{'ATTR1'} =~ m!^2 / 2$!,
  "ATTR1 attribute conf is '2 / 2'."
) or diag explain $ret;
ok(exists($ret->{'attrs'}{'ATTR1'}), "After qm run attr1 is in ret.")
  or diag explain $ret;
ok($ret->{'attrs'}{'ATTR1'} =~ m!^3.0$!, "ATTR1 attribute value is '3.0'.")
  or diag explain $ret;
ok(
  exists($ret->{'inds'}{'PMI_ITS_INFO'}),
  "After qm run inds its_closed is in ret."
) or diag explain $ret;
ok($ret->{'inds'}{'PMI_ITS_INFO'} == 5, "PMI_ITS_INFO indicator value is 5.")
  or diag explain $ret;
ok(
  exists($ret->{'inds'}{'PMI_SCM_INFO'}),
  "After qm run inds its_closers is in ret."
) or diag explain $ret;
ok($ret->{'inds'}{'PMI_SCM_INFO'} == 1, "PMI_SCM_INFO indicator value is 1.")
  or diag explain $ret;

$ret = $project->recs();
print "RECS " . Dumper($ret);

note("Run project.");

# TODO this fails. why?
#$ret = $project->run_project($models);
#print "RUN PROJ " . Dumper($ret); exit;
#$ret = $project->get_qm(); print "GET QM " . Dumper($ret);

done_testing(30);
