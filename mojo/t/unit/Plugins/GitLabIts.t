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

BEGIN { use_ok('Alambic::Plugins::GitLabIts'); }

my $plugin = Alambic::Plugins::GitLabIts->new();
isa_ok($plugin, 'Alambic::Plugins::GitLabIts');

note("Checking the plugin parameters. ");
my $conf = $plugin->get_conf();

ok(grep(m!its_evol_summary.rmd!, keys %{$conf->{'provides_figs'}}),
  "Conf has provides_figs > its_evol_summary");

ok(grep(m!ITS_CHANGED_1W!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > its_changed_1w");
ok(grep(m!ITS_CHANGED_1M!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > its_changed_1m");
ok(grep(m!ITS_CHANGED_1Y!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > its_changed_1y");

ok(grep(m!ITS_CREATED_1W!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > its_created_1w");
ok(grep(m!ITS_CREATED_1M!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > its_created_1m");
ok(grep(m!ITS_CREATED_1Y!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > its_created_1y");

ok(grep(m!ITS_ISSUES_OPEN!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > its_issues_open");
ok(grep(m!ITS_ISSUES_CLOSED!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > its_issues_closed");
ok(grep(m!ITS_ISSUES_ALL!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > its_issues_all");
ok(grep(m!ITS_ISSUES_LATE!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > its_issues_late");

ok(grep(m!metrics!, @{$conf->{'ability'}}), "Conf has ability > metrics");
ok(grep(m!info!,    @{$conf->{'ability'}}), "Conf has ability > info");
ok(grep(m!figs!,    @{$conf->{'ability'}}), "Conf has ability > figs");
ok(grep(m!data!,    @{$conf->{'ability'}}), "Conf has ability > data");
ok(grep(m!recs!,    @{$conf->{'ability'}}), "Conf has ability > recs");
ok(grep(m!viz!,     @{$conf->{'ability'}}), "Conf has ability > viz");

ok(grep(m!gitlab_url!, keys %{$conf->{'params'}}),
  "Conf has params > gitlab_url");
ok(grep(m!gitlab_id!, keys %{$conf->{'params'}}),
  "Conf has params > gitlab_id");
ok(grep(m!gitlab_token!, keys %{$conf->{'params'}}),
  "Conf has params > gitlab_token");

ok(grep(m!ITS_LONG_STANDING_OPEN!, @{$conf->{'provides_recs'}}),
  "Conf has provides_recs > its_long_standing_open");

my $in_gitlab_url     = "https://www.gitlab.com";
my $in_gitlab_id      = "bbaldassari/Alambic";
my $in_gitlab_token   = "tiPs2VdkhaDnfmteiToD";

note("Executing the plugin with Alambic project. ");
my $ret = $plugin->run_plugin(
    "test.gitlabits",
    { 'gitlab_url' => $in_gitlab_url, 
      'gitlab_id' => $in_gitlab_id,
      'gitlab_token' => $in_gitlab_token });

# Test log
my @log = @{$ret->{'log'}};
ok(grep(!/^ERROR/, @log), "Log returns no ERROR") or diag explain @log;
ok(grep(m!^\[Plugins::GitLabIts\] Retrieving data from \[http!, @log),
  "Log returns Retrieve data.")
  or diag explain @log;
ok(grep(m!^\[Plugins::GitLabIts\] Retrieved \d+ issues from!, @log),
  "Log returns Retrieved issues.")
  or diag explain @log;
ok(grep(m!^\[Plugins::GitLabIts\] GitLabIts execution finished!, @log),
  "Log returns finished execution.")
  or diag explain @log;

# Test metrics
ok($ret->{'metrics'}{'ITS_AUTHORS'} == 2,
  "Metric ITS_AUTHORS is " . $ret->{'metrics'}{'ITS_AUTHORS'} . " (ref 2).")
  or diag explain $ret;
ok($ret->{'metrics'}{'ITS_PEOPLE'} == 2,
  "Metric ITS_PEOPLE is " . $ret->{'metrics'}{'ITS_PEOPLE'} . " (ref 2).")
  or diag explain $ret;

ok($ret->{'metrics'}{'ITS_CHANGED_1W'} =~ /\d+/,
  "Metric ITS_CHANGED_1W is a digit " . $ret->{'metrics'}{'ITS_CHANGED_1W'} . ".")
  or diag explain $ret;
ok($ret->{'metrics'}{'ITS_CHANGED_1M'} =~ /\d+/,
  "Metric ITS_CHANGED_1M is a digit " . $ret->{'metrics'}{'ITS_CHANGED_1M'} . ".")
  or diag explain $ret;
ok($ret->{'metrics'}{'ITS_CHANGED_1Y'} =~ /\d+/,
  "Metric ITS_CHANGED_1Y is a digit " . $ret->{'metrics'}{'ITS_CHANGED_1Y'} . ".")
  or diag explain $ret;

ok($ret->{'metrics'}{'ITS_ISSUES_ALL'} == 80,
  "Metric ITS_ISSUES_ALL is a digit " . $ret->{'metrics'}{'ITS_ISSUES_ALL'} . ".")
  or diag explain $ret;

ok($ret->{'metrics'}{'ITS_ISSUES_LATE'} == 1,
  "Metric ITS_ISSUES_LATE is a digit " . $ret->{'metrics'}{'ITS_ISSUES_LATE'} . " (ref 1).")
  or diag explain $ret;

ok($ret->{'metrics'}{'ITS_ISSUES_OPEN'} == 10,
  "Metric ITS_ISSUES_OPEN is a digit " . $ret->{'metrics'}{'ITS_ISSUES_OPEN'} . " (ref 80).")
  or diag explain $ret;
ok($ret->{'metrics'}{'ITS_ISSUES_CLOSED'} == 70,
  "Metric ITS_ISSUES_CLOSED is a digit " . $ret->{'metrics'}{'ITS_ISSUES_CLOSED'} . " (ref 70).")
  or diag explain $ret;
ok($ret->{'metrics'}{'ITS_ISSUES_UNASSIGNED_OPEN'} == 9,
  "Metric ITS_ISSUES_UNASSIGNED_OPEN is a digit " . $ret->{'metrics'}{'ITS_ISSUES_UNASSIGNED_OPEN'} . " (ref 9).")
  or diag explain $ret;

ok($ret->{'metrics'}{'ITS_TOTAL_UPVOTES'} =~ /\d+/,
  "Metric ITS_TOTAL_UPVOTES is a digit " . $ret->{'metrics'}{'ITS_TOTAL_UPVOTES'} . ".")
  or diag explain $ret;


done_testing();
exit;

# Checking output/* files
ok(
  -e "projects/test.gitlab/output/test.gitlab_import_its.json",
  "Check that file test.gitlab_import_its.json exists."
);
ok(
  -e "projects/test.gitlab/output/test.gitlab_its_issues.json",
  "Check that file test.gitlab_import_its_issues.json exists."
);

done_testing();
