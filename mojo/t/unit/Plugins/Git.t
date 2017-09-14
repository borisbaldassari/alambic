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

use Test::More;
use Mojo::JSON qw( decode_json);
use Data::Dumper;

BEGIN { use_ok('Alambic::Plugins::Git'); }

my $plugin = Alambic::Plugins::Git->new('test.project',
  'https://BorisBaldassari@bitbucket.org/BorisBaldassari/alambic.git');
isa_ok($plugin, 'Alambic::Plugins::Git');

note("Checking the plugin parameters. ");
my $conf = $plugin->get_conf();

ok(grep(m!info!,    @{$conf->{'ability'}}), "Conf has ability > info");
ok(grep(m!metrics!, @{$conf->{'ability'}}), "Conf has not ability > metrics");
ok(grep(m!data!,    @{$conf->{'ability'}}), "Conf has not ability > data");
ok(grep(m!recs!,    @{$conf->{'ability'}}), "Conf has not ability > recs");
ok(grep(m!figs!,    @{$conf->{'ability'}}), "Conf has not ability > figs");
ok(grep(m!viz!,     @{$conf->{'ability'}}), "Conf has ability > viz");
ok(grep(m!users!,   @{$conf->{'ability'}}), "Conf has not ability > users");

ok(
  grep(m!GIT_URL!, @{$conf->{'provides_info'}}),
  "Conf has provides_info > GIT_URL"
);

ok(grep(m!import_git.txt!, keys %{$conf->{'provides_data'}}),
  "Conf has provides_data > import_git.txt");
ok(grep(m!metrics_git.json!, keys %{$conf->{'provides_data'}}),
  "Conf has provides_data > metrics_git.json");
ok(grep(m!git_commits.csv!, keys %{$conf->{'provides_data'}}),
  "Conf has provides_data > git_commits.csv");

ok(grep(m!SCM_AUTHORS!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > SCM_AUTHORS");
ok(grep(m!SCM_COMMITS!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > SCM_COMMITS");
ok(grep(m!SCM_COMMITTERS!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > SCM_COMMITTERS");
ok(grep(m!SCM_MOD_LINES!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > SCM_MOD_LINES");

ok(grep(m!metrics!, @{$conf->{'ability'}}), "Conf has ability > metrics");
ok(grep(m!data!,    @{$conf->{'ability'}}), "Conf has ability > data");
ok(grep(m!recs!,    @{$conf->{'ability'}}), "Conf has ability > recs");
ok(grep(m!info!,    @{$conf->{'ability'}}), "Conf has ability > info");
ok(grep(m!viz!,     @{$conf->{'ability'}}), "Conf has ability > viz");

ok(grep(m!git_url!, keys %{$conf->{'params'}}), "Conf has params > git_url");

ok(
  grep(m!SCM_LOW_ACTIVITY!, @{$conf->{'provides_recs'}}),
  "Conf has provides_recs > SCM_LOW_ACTIVITY"
);
ok(
  grep(m!SCM_ZERO_ACTIVITY!, @{$conf->{'provides_recs'}}),
  "Conf has provides_recs > SCM_ZERO_ACTIVITY"
);

ok(grep(m!git_summary.html!, keys %{$conf->{'provides_figs'}}),
  "Conf has provides_figs > git_summary.html");

ok(grep(m!git_scm!, keys %{$conf->{'provides_viz'}}),
  "Conf has provides_figs > git_scm");

# Execute the plugin
note("Execute the plugin with alambic.test project. ");
my $ret = $plugin->run_plugin(
  "alambic.test",
  {
    'git_url' =>
      'https://BorisBaldassari@bitbucket.org/BorisBaldassari/alambic.git'
  }
);

ok(grep(m!GIT_URL!, keys %{$ret->{'info'}}), "Ret has info > GIT_URL.");
ok($ret->{'info'}{'GIT_URL'} =~ m!^https://BorisBaldassari\@bitbucket.org/BorisBaldassari/alambic.git$!, 
   "Ret has correct GIT_URL.");
    
ok(grep(m!\[Tools::Git\] Getting Git log!, @{$ret->{'log'}}),
  "Ret has log > Getting Git log");
ok(grep(m!\[Plugins::Git\] Parsing git log:!, @{$ret->{'log'}}),
  "Ret has log > Parsing git log");
ok(grep(m!\[Plugins::Git\] Writing user events file.!, @{$ret->{'log'}}),
  "Ret has log > Getting Git log");

ok($ret->{'metrics'}{'SCM_COMMITTERS'} =~ /\d+/, "Metrics has SCM_COMMITTERS");
ok($ret->{'metrics'}{'SCM_COMMITTERS'} < 999,    "Metrics has SCM_COMMITTERS");
ok($ret->{'metrics'}{'SCM_COMMITTERS_1M'} =~ /\d+/,
  "Metrics has SCM_COMMITTERS_1M");
ok($ret->{'metrics'}{'SCM_COMMITTERS_1W'} =~ /\d+/,
  "Metrics has SCM_COMMITTERS_1W");
ok($ret->{'metrics'}{'SCM_COMMITTERS_1Y'} =~ /\d+/,
  "Metrics has SCM_COMMITTERS_1Y");

ok($ret->{'metrics'}{'SCM_AUTHORS'} =~ /\d+/,    "Metrics has SCM_AUTHORS");
ok($ret->{'metrics'}{'SCM_AUTHORS'} < 999,       "Metrics has SCM_AUTHORS");
ok($ret->{'metrics'}{'SCM_AUTHORS_1M'} =~ /\d+/, "Metrics has SCM_AUTHORS_1M");
ok($ret->{'metrics'}{'SCM_AUTHORS_1W'} =~ /\d+/, "Metrics has SCM_AUTHORS_1W");
ok($ret->{'metrics'}{'SCM_AUTHORS_1Y'} =~ /\d+/, "Metrics has SCM_AUTHORS_1Y");

ok($ret->{'metrics'}{'SCM_COMMITS'} =~ /\d+/,    "Metrics has SCM_COMMITS");
ok($ret->{'metrics'}{'SCM_COMMITS'} < 99999,     "Metrics has SCM_COMMITS");
ok($ret->{'metrics'}{'SCM_COMMITS_1M'} =~ /\d+/, "Metrics has SCM_COMMITS_1M");
ok($ret->{'metrics'}{'SCM_COMMITS_1W'} =~ /\d+/, "Metrics has SCM_COMMITS_1W");
ok($ret->{'metrics'}{'SCM_COMMITS_1Y'} =~ /\d+/, "Metrics has SCM_COMMITS_1Y");

ok($ret->{'metrics'}{'SCM_MOD_LINES'} =~ /\d+/,    "Metrics has SCM_MOD_LINES");
ok($ret->{'metrics'}{'SCM_MOD_LINES'} > 1000,     "Metrics has SCM_MOD_LINES");
ok($ret->{'metrics'}{'SCM_MOD_LINES_1M'} =~ /\d+/, "Metrics has SCM_MOD_LINES_1M");
ok($ret->{'metrics'}{'SCM_MOD_LINES_1W'} =~ /\d+/, "Metrics has SCM_MOD_LINES_1W");
ok($ret->{'metrics'}{'SCM_MOD_LINES_1Y'} =~ /\d+/, "Metrics has SCM_MOD_LINES_1Y");

# Check that files have been created.
note("Check that files have been created. ");
ok(-e "projects/alambic.test/input/alambic.test_import_git.txt",
  "Check that file import_git.txt exists.");
ok(
  -e "projects/alambic.test/output/alambic.test_git_commits.csv",
  "Check that file alambic.test_git_commits.csv exists."
);
ok(
  -e "projects/alambic.test/output/alambic.test_git_scm.inc",
  "Check that file alambic.test_git_scm.inc exists."
);
ok(
  -e "projects/alambic.test/output/alambic.test_metrics_git.json",
  "Check that file alambic.test_metrics_metrics_git.json exists."
);
ok(
  -e "projects/alambic.test/output/alambic.test_metrics_git.csv",
  "Check that file alambic.test_metrics_git.csv exists."
);

# Checking *_authors files
ok(
  -e "projects/alambic.test/output/alambic.test_git_evol_authors.html",
  "Check that file alambic.test_git_evol_authors.html exists."
);
ok(
  -e "projects/alambic.test/output/alambic.test_git_evol_authors.png",
  "Check that file alambic.test_git_evol_authors.png exists."
);
ok(
  -e "projects/alambic.test/output/alambic.test_git_evol_authors.svg",
  "Check that file alambic.test_git_evol_authors.svg exists."
);

# Checking *_commits files
ok(
  -e "projects/alambic.test/output/alambic.test_git_evol_commits.svg",
  "Check that file alambic.test_git_evol_commits.svg exists."
);
ok(
  -e "projects/alambic.test/output/alambic.test_git_evol_commits.svg",
  "Check that file alambic.test_git_evol_commits.svg exists."
);
ok(
  -e "projects/alambic.test/output/alambic.test_git_evol_commits.html",
  "Check that file alambic.test_git_evol_commits.html exists."
);

# Checking *_summary files
ok(
  -e "projects/alambic.test/output/alambic.test_git_evol_summary.html",
  "Check that file alambic.test_git_evol_summary.html exists."
);
ok(
  -e "projects/alambic.test/output/alambic.test_git_summary.html",
  "Check that file alambic.test_git_summary.html exists."
);

done_testing();
