#! perl -I../../lib/
#########################################################
#
# Copyright (c) 2015-2017 Castalia Solutions and Thales Group.
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

use Test::More;
use Mojo::JSON qw( decode_json);
use Data::Dumper;

BEGIN { use_ok('Alambic::Plugins::JiraIts'); }

my $plugin = Alambic::Plugins::JiraIts->new();
isa_ok($plugin, 'Alambic::Plugins::JiraIts');

note("Checking the plugin parameters. ");
my $conf = $plugin->get_conf();

ok(grep(m!jira_url!, keys %{$conf->{'params'}}), "Conf has params > jira_url");
ok(grep(m!jira_user!, keys %{$conf->{'params'}}),
  "Conf has params > jira_user");
ok(grep(m!jira_passwd!, keys %{$conf->{'params'}}),
  "Conf has params > jira_passwd");
ok(grep(m!jira_project!, keys %{$conf->{'params'}}),
  "Conf has params > jira_project");

ok(grep(m!info!,    @{$conf->{'ability'}}), "Conf has ability > info");
ok(grep(m!metrics!, @{$conf->{'ability'}}), "Conf has ability > metrics");
ok(grep(m!data!,    @{$conf->{'ability'}}), "Conf has ability > data");
ok(grep(m!recs!,    @{$conf->{'ability'}}), "Conf has ability > recs");
ok(grep(m!figs!,    @{$conf->{'ability'}}), "Conf has ability > figs");
ok(grep(m!viz!,     @{$conf->{'ability'}}), "Conf has ability > viz");
ok(grep(m!users!,   @{$conf->{'ability'}}), "Conf has ability > users");

ok(grep(m!JIRA_URL!, @{$conf->{'provides_info'}}),
  "Conf has provides_info > JIRA_URL");

# Delete files before creating them, so we don't test a previous run.
unlink (
    "projects/tools.cdt/input/tools.cdt_import_jira.json",
    "projects/tools.cdt/output/tools.cdt_jira_evol.inc",
    "projects/tools.cdt/output/tools.cdt_jira_issues.csv",
    "projects/tools.cdt/output/tools.cdt_jira_issues_late.csv",
    "projects/tools.cdt/output/tools.cdt_jira_issues_open.csv",
    "projects/tools.cdt/output/tools.cdt_jira_issues_open_old.csv",
    "projects/tools.cdt/output/tools.cdt_jira_issues_open_unassigned.csv",
    "projects/tools.cdt/output/tools.cdt_jira_evol_summary.csv",
    "projects/tools.cdt/output/tools.cdt_jira_evol_created.csv",
    "projects/tools.cdt/output/tools.cdt_jira_evol_authors.csv",
    );

ok(grep(m!import_jira.json!, keys %{$conf->{'provides_data'}}),
  "Conf has provides_data > import_jira.json");
ok(grep(m!jira_evol.csv!, keys %{$conf->{'provides_data'}}),
  "Conf has provides_data > jira_evol.csv");
ok(grep(m!jira_issues.csv!, keys %{$conf->{'provides_data'}}),
  "Conf has provides_data > jira_issues.csv");
ok(grep(m!jira_issues_late.csv!, keys %{$conf->{'provides_data'}}),
  "Conf has provides_data > jira_issues_late.csv");
ok(grep(m!jira_issues_open.csv!, keys %{$conf->{'provides_data'}}),
  "Conf has provides_data > jira_issues_open.csv");
ok(grep(m!jira_issues_open_old.csv!, keys %{$conf->{'provides_data'}}),
  "Conf has provides_data > jira_issues_open_old.csv");
ok(grep(m!jira_issues_open_unassigned.csv!, keys %{$conf->{'provides_data'}}),
  "Conf has provides_data > jira_issues_open_unassigned.csv");


ok(grep(m!ITS_ISSUES_ALL!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > ITS_ISSUES_ALL");
ok(grep(m!ITS_AUTHORS!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > ITS_AUTHORS");
ok(grep(m!ITS_AUTHORS_1M!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > ITS_AUTHORS_1M");
ok(grep(m!ITS_AUTHORS_1W!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > ITS_AUTHORS_1W");
ok(grep(m!ITS_AUTHORS_1Y!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > ITS_AUTHORS_1Y");
ok(grep(m!ITS_CREATED_1M!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > ITS_CREATED_1M");
ok(grep(m!ITS_CREATED_1W!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > ITS_CREATED_1W");
ok(grep(m!ITS_CREATED_1Y!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > ITS_CREATED_1Y");
ok(grep(m!ITS_UPDATED_1M!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > ITS_UPDATED_1M");
ok(grep(m!ITS_UPDATED_1W!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > ITS_UPDATED_1W");
ok(grep(m!ITS_UPDATED_1Y!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > ITS_UPDATED_1Y");
ok(grep(m!ITS_OPEN!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > ITS_OPEN");
ok(grep(m!ITS_OPEN_OLD!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > ITS_OPEN_OLD");
ok(grep(m!ITS_OPEN_PERCENT!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > ITS_OPEN_PERCENT");
ok(grep(m!ITS_LATE!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > ITS_LATE");
ok(grep(m!ITS_OPEN_UNASSIGNED!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > ITS_OPEN_UNASSIGNED");

ok(grep(m!jira_summary.html!, keys %{$conf->{'provides_figs'}}),
  "Conf has provides_figs > jira_summary.html");
ok(grep(m!jira_evol_summary.html!, keys %{$conf->{'provides_figs'}}),
  "Conf has provides_figs > jira_evol_summary.html");
ok(grep(m!jira_evol_created.html!, keys %{$conf->{'provides_figs'}}),
  "Conf has provides_figs > jira_evol_created.html");
ok(grep(m!jira_evol_authors.html!, keys %{$conf->{'provides_figs'}}),
  "Conf has provides_figs > jira_evol_authors.html");

note("Executing the plugin with AL project. ");
my $ret = $plugin->run_plugin(
  "tools.cdt",
  {
    'jira_url'         => 'https://castalia.atlassian.net',
    'jira_user'        => 'alambic@castalia.solutions',
    'jira_passwd'      => '0TQYZEB7BWwOlAAM1XEq8D9A',
    'jira_project'     => 'AL',
    'jira_open_states' => 'To Do',
  }
);

ok(
  grep(m!\[Plugins::JiraIts\] Retrieving information from \[http!,
    @{$ret->{'log'}}),
  "Ret has log > Retrieve info."
);
ok(grep(m!\[Plugins::JiraIts\] Writing user events file!, @{$ret->{'log'}}),
  "Ret has log > Writing user events file.");
ok(grep(/^\[Tools::R\] Exec \[Rsc.*jira_its.Rmd/, @{$ret->{'log'}}) == 1,
  "Checking if log contains jira_its.Rmd R code exec.")
  or diag explain $ret;
ok(
  grep(/^\[Tools::R\] Exec \[Rsc.*jira_evol_authors.rmd/, @{$ret->{'log'}})
    == 1,
  "Checking if log contains jira_evol_authors.rmd R code exec."
) or diag explain $ret;
ok(
  grep(/^\[Tools::R\] Exec \[Rsc.*jira_evol_created.rmd/, @{$ret->{'log'}})
    == 1,
  "Checking if log contains jira_evol_created.rmd R code exec."
) or diag explain $ret;
ok(grep(/^\[Tools::R\] Exec \[Rsc.*jira_summary.rmd/, @{$ret->{'log'}}) == 1,
  "Checking if log contains jira_summary.rmd R code exec.")
  or diag explain $ret;

ok($ret->{'metrics'}{'ITS_ISSUES_ALL'} =~ /^\d+$/, "ITS_ISSUES_ALL is a digit.")
  or diag explain $ret;
ok($ret->{'metrics'}{'ITS_OPEN'} =~ /^\d+$/, "ITS_OPEN is a digit.")
  or diag explain $ret;
ok($ret->{'metrics'}{'ITS_OPEN_OLD'} =~ /^\d+$/, "ITS_OPEN_OLD is a digit.")
  or diag explain $ret;
ok($ret->{'metrics'}{'ITS_OPEN_PERCENT'} =~ /^\d\d?$/,
  "ITS_OPEN_PERCENT is xx.")
  or diag explain $ret;
ok($ret->{'metrics'}{'ITS_OPEN_UNASSIGNED'} =~ /^\d+$/,
  "ITS_OPEN_UNASSIGNED is a digit.")
  or diag explain $ret;
ok($ret->{'metrics'}{'ITS_CREATED_1M'} =~ /^\d+$/,
  "ITS_CREATED_1M is a digit.")
  or diag explain $ret;
ok($ret->{'metrics'}{'ITS_CREATED_1Y'} =~ /^\d+$/,
  "ITS_CREATED_1Y is a digit.")
  or diag explain $ret;
ok($ret->{'metrics'}{'ITS_CREATED_1W'} =~ /^\d+$/,
  "ITS_CREATED_1W is a digit.")
  or diag explain $ret;
ok($ret->{'metrics'}{'ITS_UPDATED_1M'} =~ /^\d+$/,
  "ITS_UPDATED_1M is a digit.")
  or diag explain $ret;
ok($ret->{'metrics'}{'ITS_UPDATED_1W'} =~ /^\d+$/,
  "ITS_UPDATED_1W is a digit.")
  or diag explain $ret;
ok($ret->{'metrics'}{'ITS_UPDATED_1Y'} =~ /^\d+$/,
  "ITS_UPDATED_1Y is a digit.")
  or diag explain $ret;
ok($ret->{'metrics'}{'ITS_AUTHORS_1W'} =~ /^\d+$/,
  "ITS_AUTHORS_1W is a digit.")
  or diag explain $ret;
ok($ret->{'metrics'}{'ITS_AUTHORS_1M'} =~ /^\d+$/,
  "ITS_AUTHORS_1M is a digit.")
  or diag explain $ret;
ok($ret->{'metrics'}{'ITS_AUTHORS_1Y'} =~ /^\d+$/,
  "ITS_AUTHORS_1Y is a digit.")
  or diag explain $ret;
ok($ret->{'metrics'}{'ITS_AUTHORS'} =~ /^\d+$/, "ITS_AUTHORS is a digit.")
  or diag explain $ret;
ok($ret->{'metrics'}{'ITS_LATE'} =~ /^\d+$/, "ITS_LATE is a digit.")
  or diag explain $ret;


ok(scalar(@{$ret->{'recs'}}) == 1, "Ret has 1 rec.");
ok($ret->{'recs'}[0]{'rid'} eq "JIRA_LATE_ISSUES",
  "Ret has rec > JIRA_LATE_ISSUE.");

ok($ret->{'info'}{'JIRA_URL'} eq 'https://castalia.atlassian.net/projects/AL/',
  "Ret has info JIRA_URL.");


note("Check that files have been created. ");
ok(-e "projects/tools.cdt/input/tools.cdt_import_jira.json",
  "Check that file import_jira.json exists.");

ok(-e "projects/tools.cdt/output/tools.cdt_jira_evol.csv",
  "Check that file jira_evol.csv exists.");
ok(-e "projects/tools.cdt/output/tools.cdt_jira_issues.csv",
  "Check that file jira_issues.csv exists.");
ok(-e "projects/tools.cdt/output/tools.cdt_jira_issues_late.csv",
  "Check that file jira_issues_late.csv exists.");
ok(-e "projects/tools.cdt/output/tools.cdt_jira_issues_open.csv",
  "Check that file jira_issues_open.csv exists.");
ok(-e "projects/tools.cdt/output/tools.cdt_jira_issues_open_old.csv",
  "Check that file jira_issues_open_old.csv exists.");
ok(-e "projects/tools.cdt/output/tools.cdt_jira_issues_open_unassigned.csv",
  "Check that file jira_issues_open_unassigned.csv exists.");

ok(-e "projects/tools.cdt/output/tools.cdt_jira_summary.html",
  "Check that file jira_summary.html exists.");
ok(-e "projects/tools.cdt/output/tools.cdt_jira_its.inc",
  "Check that file jira_its.inc exists.");
ok(-e "projects/tools.cdt/output/tools.cdt_metrics_jira.csv",
  "Check that file metrics_jira.csv exists.");
ok(-e "projects/tools.cdt/output/tools.cdt_metrics_jira.json",
  "Check that file metrics_jira.json exists.");

ok(-e "projects/tools.cdt/output/tools.cdt_jira_evol_authors.html",
  "Check that file jira_evol_authors.html exists.");
ok(-e "projects/tools.cdt/output/tools.cdt_jira_evol_authors.svg",
  "Check that file jira_evol_authors.svg exists.");
ok(-e "projects/tools.cdt/output/tools.cdt_jira_evol_authors.png",
  "Check that file jira_evol_authors.png exists.");

ok(-e "projects/tools.cdt/output/tools.cdt_jira_evol_created.html",
  "Check that file jira_evol_created.html exists.");
ok(-e "projects/tools.cdt/output/tools.cdt_jira_evol_created.svg",
  "Check that file jira_evol_created.svg exists.");
ok(-e "projects/tools.cdt/output/tools.cdt_jira_evol_created.png",
  "Check that file jira_evol_created.png exists.");

done_testing();

exit;

