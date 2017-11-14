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
ok(grep(m!jira_issues_open_unassigned.csv!, keys %{$conf->{'provides_data'}}),
  "Conf has provides_data > jira_issues_open_unassigned.csv");


ok(grep(m!JIRA_VOL!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > JIRA_VOL");
ok(grep(m!JIRA_AUTHORS!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > JIRA_AUTHORS");
ok(grep(m!JIRA_AUTHORS_1M!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > JIRA_AUTHORS_1M");
ok(grep(m!JIRA_AUTHORS_1W!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > JIRA_AUTHORS_1W");
ok(grep(m!JIRA_AUTHORS_1Y!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > JIRA_AUTHORS_1Y");
ok(grep(m!JIRA_CREATED_1W!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > JIRA_CREATED_1W");
ok(grep(m!JIRA_UPDATED_1W!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > JIRA_UPDATED_1W");
ok(grep(m!JIRA_LATE!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > JIRA_LATE");

ok(grep(m!jira_summary.html!, keys %{$conf->{'provides_figs'}}),
  "Conf has provides_figs > jira_summary.html");

note("Executing the plugin with AL project. ");
my $ret = $plugin->run_plugin(
  "tools.cdt",
  {
    'jira_url'         => 'https://castalia.atlassian.net',
    'jira_user'        => 'alambic',
    'jira_passwd'      => 'alambic123',
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

ok($ret->{'metrics'}{'JIRA_VOL'} =~ /^\d+$/, "JIRA_VOL is a digit.")  or diag explain $ret;
ok($ret->{'metrics'}{'JIRA_OPEN'} =~ /^\d+$/, "JIRA_OPEN is a digit.") or diag explain $ret;
ok($ret->{'metrics'}{'JIRA_OPEN_PERCENT'} =~ /^\d\d?$/, "JIRA_OPEN_PERCENT is xx.")
  or diag explain $ret;
ok($ret->{'metrics'}{'JIRA_OPEN_UNASSIGNED'} =~ /^\d+$/, "JIRA_OPEN_UNASSIGNED is a digit.")
  or diag explain $ret;
ok($ret->{'metrics'}{'JIRA_CREATED_1M'} =~ /^\d+$/, "JIRA_CREATED_1M is a digit.")
  or diag explain $ret;
ok($ret->{'metrics'}{'JIRA_CREATED_1Y'} =~ /^\d+$/, "JIRA_CREATED_1Y is a digit.")
  or diag explain $ret;
ok($ret->{'metrics'}{'JIRA_CREATED_1W'} =~ /^\d+$/, "JIRA_CREATED_1W is a digit.")
  or diag explain $ret;
ok($ret->{'metrics'}{'JIRA_UPDATED_1M'} =~ /^\d+$/, "JIRA_UPDATED_1M is a digit.")
  or diag explain $ret;
ok($ret->{'metrics'}{'JIRA_UPDATED_1W'} =~ /^\d+$/, "JIRA_UPDATED_1W is a digit.")
  or diag explain $ret;
ok($ret->{'metrics'}{'JIRA_UPDATED_1Y'} =~ /^\d+$/, "JIRA_UPDATED_1Y is a digit.")
  or diag explain $ret;
ok($ret->{'metrics'}{'JIRA_AUTHORS_1W'} =~ /^\d+$/, "JIRA_AUTHORS_1W is a digit.")
  or diag explain $ret;
ok($ret->{'metrics'}{'JIRA_AUTHORS_1M'} =~ /^\d+$/, "JIRA_AUTHORS_1M is a digit.")
  or diag explain $ret;
ok($ret->{'metrics'}{'JIRA_AUTHORS_1Y'} =~ /^\d+$/, "JIRA_AUTHORS_1Y is a digit.")
  or diag explain $ret;
ok($ret->{'metrics'}{'JIRA_AUTHORS'} =~ /^\d+$/, "JIRA_AUTHORS is a digit.")
  or diag explain $ret;
ok($ret->{'metrics'}{'JIRA_LATE'} =~ /^\d+$/, "JIRA_LATE is a digit.") or diag explain $ret;


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

