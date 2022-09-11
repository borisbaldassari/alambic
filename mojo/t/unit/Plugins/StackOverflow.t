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

BEGIN { use_ok('Alambic::Plugins::StackOverflow'); }

my $plugin = Alambic::Plugins::StackOverflow->new();
isa_ok($plugin, 'Alambic::Plugins::StackOverflow');

note("Checking the plugin parameters. ");
my $conf = $plugin->get_conf();

ok(grep(m!so_evolution.svg!, keys %{$conf->{'provides_figs'}}),
  "Conf has provides_figs > so_evolution.svg");
ok(grep(m!so_plot.svg!, keys %{$conf->{'provides_figs'}}),
  "Conf has provides_figs > so_plot.svg");
ok(grep(m!so_tm.svg!, keys %{$conf->{'provides_figs'}}),
  "Conf has provides_figs > so_tm.svg");

ok(grep(m!SO_QUESTIONS_VOL_5Y!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > so_questions_vol_5y");
ok(grep(m!SO_ANSWERS_VOL_5Y!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > so_answers_vol_5y");
ok(grep(m!SO_ANSWER_RATE_5Y!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > so_answer_rate_5y");
ok(grep(m!SO_VOTES_VOL_5Y!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > so_votes_vol_5y");
ok(grep(m!SO_VIEWS_VOL_5Y!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > so_views_vol_5y");
ok(grep(m!SO_VIEWS_VOL_5Y!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > so_views_vol_5y");
ok(grep(m!SO_ASKERS_5Y!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > so_askers_5y");

ok(grep(m!metrics!, @{$conf->{'ability'}}), "Conf has ability > metrics");
ok(grep(m!figs!,    @{$conf->{'ability'}}), "Conf has ability > figs");
ok(grep(m!data!,    @{$conf->{'ability'}}), "Conf has ability > data");
ok(grep(m!users!,    @{$conf->{'ability'}}), "Conf has ability > users");
ok(grep(m!viz!,     @{$conf->{'ability'}}), "Conf has ability > viz");
ok(grep(m!recs!,     @{$conf->{'ability'}}), "Conf has ability > recs");

ok(grep(m!SO_ANSWER_RATE_LOW!, @{$conf->{'provides_recs'}}),
  "Conf has recs > so_answer_rate_low");

ok(grep(m!so_keyword!, keys %{$conf->{'params'}}),
  "Conf has params > so_keyword");

ok(grep(m!stack_overflow.html!, keys %{$conf->{'provides_viz'}}),
  "Conf has provides_viz > stack_overflow.html");

my $in_keyword = "eclipse-sirius";

# Delete files before creating them, so we don't test a previous run.
unlink (
    "projects/test.project/input/test.project_import_so.json",
    "projects/test.project/output/test.project_so.json",
    "projects/test.project/output/test.project_so.csv",
    );

note("Executing the plugin with Sirius project. ");
my $ret = $plugin->run_plugin("test.project",
  {'so_keyword' => $in_keyword});

# Test log
my @log = @{$ret->{'log'}};
ok(grep(!/^ERROR/, @log), "Log returns no ERROR") or diag explain @log;
ok(grep(m!^\[Plugins::StackOverflow\] Fetching https://api.stackexchange.com!, @log),
  "Log returns fetching url.")
  or diag explain @log;
ok(grep(m!^\[Plugins::StackOverflow\] Fetched data from SO. Got !, @log),
  "Log returns got data from so.")
  or diag explain @log;
ok(grep(m!^\[Plugins::StackOverflow\] Quota: remaining!, @log),
   "Log returns got quota.");

# Test metrics
ok($ret->{'metrics'}{'SO_VOTES_VOL_5Y'} =~ m![1-9]\d*!,
  "Metric SO_VOTES_VOL_5Y is a digit: " . $ret->{'metrics'}{'SO_VOTES_VOL_5Y'} . ".")
  or diag explain $ret;
ok($ret->{'metrics'}{'SO_ASKERS_5Y'} =~ m![1-9]\d*!,
  "Metric SO_ASKERS_5Y is a digit: " . $ret->{'metrics'}{'SO_ASKERS_5Y'} . ".")
  or diag explain $ret;
ok($ret->{'metrics'}{'SO_VIEWS_VOL_5Y'} =~ m![1-9]\d*!,
  "Metric SO_VIEWS_VOL_5Y is a digit: " . $ret->{'metrics'}{'SO_VIEWS_VOL_5Y'} . ".")
  or diag explain $ret;
ok($ret->{'metrics'}{'SO_ANSWERS_VOL_5Y'} =~ m![1-9]\d*!,
  "Metric SO_ANSWERS_VOL_5Y is a digit: " . $ret->{'metrics'}{'SO_ANSWERS_VOL_5Y'} . ".")
  or diag explain $ret;
ok($ret->{'metrics'}{'SO_ANSWER_RATE_5Y'} =~ m![1-9]\d*!,
  "Metric SO_ANSWER_RATE_5Y is a digit 1+: " . $ret->{'metrics'}{'SO_ANSWER_RATE_5Y'} . ".")
  or diag explain $ret;
ok($ret->{'metrics'}{'SO_QUESTIONS_VOL_5Y'} =~ m![1-9]\d*!,
  "Metric SO_QUESTIONS_VOL_5Y is a digit 1+: " . $ret->{'metrics'}{'SO_QUESTIONS_VOL_5Y'} . ".")
  or diag explain $ret;


# Checking generated_ files
ok(
  -e "projects/test.project/input/test.project_import_so.json",
  "Check that file test.project_import_so.json exists."
);
ok(
  -e "projects/test.project/output/test.project_so.csv",
  "Check that file test.project_so.csv exists."
);
ok(
  -e "projects/test.project/output/test.project_so.json",
  "Check that file test.project_so.json exists."
    );


done_testing();
