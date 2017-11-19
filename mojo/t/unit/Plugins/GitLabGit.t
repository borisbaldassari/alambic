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

BEGIN { use_ok('Alambic::Plugins::GitLabGit'); }

my $plugin = Alambic::Plugins::GitLabGit->new();
isa_ok($plugin, 'Alambic::Plugins::GitLabGit');

note("Checking the plugin parameters. ");
my $conf = $plugin->get_conf();

#ok(grep(m!git_evol_summary.rmd!, keys %{$conf->{'provides_figs'}}),
#  "Conf has provides_figs > git_evol_summary");

ok(grep(m!import_gitlab_git_commits.json!, keys %{$conf->{'provides_data'}}),
   "Conf has provides_data > import_gitlab_git_commits.json");
ok(grep(m!import_gitlab_git_merge_requests.json!, keys %{$conf->{'provides_data'}}),
   "Conf has provides_data > import_gitlab_git_merge_requests.json");
ok(grep(m!gitlab_git_merge_requests.csv!, keys %{$conf->{'provides_data'}}),
   "Conf has provides_data > gitlab_git_merge_requests.csv");
ok(grep(m!gitlab_git_merge_requests.json!, keys %{$conf->{'provides_data'}}),
   "Conf has provides_data > gitlab_git_merge_requests.json");
ok(grep(m!gitlab_git_commits.csv!, keys %{$conf->{'provides_data'}}),
   "Conf has provides_data > gitlab_git_commits.csv");
ok(grep(m!gitlab_git_commits.json!, keys %{$conf->{'provides_data'}}),
   "Conf has provides_data > gitlab_git_commits.json");
ok(grep(m!gitlab_git_commits_hist.csv!, keys %{$conf->{'provides_data'}}),
   "Conf has provides_data > gitlab_git_commits_hist.csv");
   
ok(grep(m!SCM_AUTHORS!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > scm_authors");
ok(grep(m!SCM_AUTHORS_1W!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > scm_authors_1w");
ok(grep(m!SCM_AUTHORS_1M!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > scm_authors_1m");
ok(grep(m!SCM_AUTHORS_1Y!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > scm_authors_1y");

ok(grep(m!SCM_COMMITS!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > scm_commits");
ok(grep(m!SCM_COMMITS_1W!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > scm_commits_1w");
ok(grep(m!SCM_COMMITS_1M!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > scm_commits_1m");
ok(grep(m!SCM_COMMITS_1Y!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > scm_commits_1y");

ok(grep(m!SCM_COMMITTERS!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > scm_committers");
ok(grep(m!SCM_COMMITTERS_1W!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > scm_committers_1w");
ok(grep(m!SCM_COMMITTERS_1M!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > scm_committers_1m");
ok(grep(m!SCM_COMMITTERS_1Y!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > scm_committers_1y");

ok(grep(m!SCM_MRS!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > scm_mrs");
ok(grep(m!SCM_MRS_OPENED!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > scm_mrs_opened");
ok(grep(m!SCM_MRS_OPENED_1W!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > scm_mrs_opened_1w");
ok(grep(m!SCM_MRS_OPENED_1M!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > scm_mrs_opened_1m");
ok(grep(m!SCM_MRS_OPENED_1Y!, keys %{$conf->{'provides_metrics'}}),
   "Conf has provides_metrics > scm_mrs_opened_1y");

ok(grep(m!SCM_MRS_OPENED_STILL!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > scm_mrs_opened_still");
ok(grep(m!SCM_MRS_OPENED_STILL_1W!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > scm_mrs_opened_still_1w");
ok(grep(m!SCM_MRS_OPENED_STILL_1M!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > scm_mrs_opened_still_1m");
ok(grep(m!SCM_MRS_OPENED_STILL_1Y!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > scm_mrs_opened_still_1y");
ok(grep(m!SCM_MRS_OPENED_STALED_1M!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > scm_mrs_opened_staled_1m");

ok(grep(m!SCM_MRS_CLOSED!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > scm_mrs_closed");
ok(grep(m!SCM_MRS_MERGED!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > scm_mrs_merged");


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

ok(grep(m!SCM_MRS_STALED_1W!, @{$conf->{'provides_recs'}}),
  "Conf has provides_recs > scm_mrs_staled_1w");
ok(grep(m!SCM_LOW_ACTIVITY!, @{$conf->{'provides_recs'}}),
  "Conf has provides_recs > scm_low_activity");
ok(grep(m!SCM_ZERO_ACTIVITY!, @{$conf->{'provides_recs'}}),
  "Conf has provides_recs > scm_zero_activity");
ok(grep(m!SCM_LOW_DIVERSITY!, @{$conf->{'provides_recs'}}),
  "Conf has provides_recs > scm_low_diversity");

my $in_gitlab_url     = "https://www.gitlab.com";
my $in_gitlab_id      = "bbaldassari/Alambic";
my $in_gitlab_token   = "tiPs2VdkhaDnfmteiToD";

note("Executing the plugin with Alambic project. ");
my $ret = $plugin->run_plugin(
    "test.gitlabgit",
    { 'gitlab_url' => $in_gitlab_url, 
      'gitlab_id' => $in_gitlab_id,
      'gitlab_token' => $in_gitlab_token });

# Test log
my @log = @{$ret->{'log'}};
ok(grep(!/^ERROR/, @log), "Log returns no ERROR") or diag explain @log;
ok(grep(m!^\[Plugins::GitLabGit\] Retrieved Commits info from \[http!, @log),
  "Log returns Retrieved commits.")
  or diag explain @log;
ok(grep(m!^\[Plugins::GitLabGit\] Retrieved Merge requests info from \[http!, @log),
  "Log returns Retrieved Merge requests.")
  or diag explain @log;
ok(grep(m!^\[Plugins::GitLabGit\] Writing user events file.!, @log),
  "Log returns User event file.")
  or diag explain @log;
ok(grep(m!^\[Tools::R\] Exec \[Rscript -e "library\(rmarkdown\).!, @log),
  "Log returns R exec.")
  or diag explain @log;
ok(grep(m!^\[Tools::R\] Moved main file!, @log),
  "Log returns R moved main file.")
  or diag explain @log;

# Test metrics
ok($ret->{'metrics'}{'SCM_COMMITS'} =~ /\d+/,
  "Metric SCM_COMMITS is a digit " . $ret->{'metrics'}{'SCM_COMMITS'} . ".")
    or diag explain $ret;
ok($ret->{'metrics'}{'SCM_COMMITS_1W'} =~ /\d+/,
  "Metric SCM_COMMITS_1W is a digit " . $ret->{'metrics'}{'SCM_COMMITS_1W'} . ".")
  or diag explain $ret;
ok($ret->{'metrics'}{'SCM_COMMITS_1M'} =~ /\d+/,
  "Metric SCM_COMMITS_1M is a digit " . $ret->{'metrics'}{'SCM_COMMITS_1M'} . ".")
  or diag explain $ret;
ok($ret->{'metrics'}{'SCM_COMMITS_1Y'} =~ /\d+/,
  "Metric SCM_COMMITS_1Y is a digit " . $ret->{'metrics'}{'SCM_COMMITS_1Y'} . ".")
  or diag explain $ret;

ok($ret->{'metrics'}{'SCM_AUTHORS'} =~ /\d+/,
  "Metric SCM_AUTHORS is a digit " . $ret->{'metrics'}{'SCM_AUTHORS'} . ".")
  or diag explain $ret;
ok($ret->{'metrics'}{'SCM_AUTHORS_1W'} =~ /\d+/,
  "Metric SCM_AUTHORS_1W is a digit " . $ret->{'metrics'}{'SCM_AUTHORS_1W'} . ".")
  or diag explain $ret;
ok($ret->{'metrics'}{'SCM_AUTHORS_1M'} =~ /\d+/,
  "Metric SCM_AUTHORS_1M is a digit " . $ret->{'metrics'}{'SCM_AUTHORS_1M'} . ".")
  or diag explain $ret;
ok($ret->{'metrics'}{'SCM_AUTHORS_1Y'} =~ /\d+/,
  "Metric SCM_AUTHORS_1Y is a digit " . $ret->{'metrics'}{'SCM_AUTHORS_1Y'} . ".")
    or diag explain $ret;

ok($ret->{'metrics'}{'SCM_COMMITTERS'} =~ /\d+/,
  "Metric SCM_COMMITTERS is a digit " . $ret->{'metrics'}{'SCM_COMMITTERS'} . ".")
  or diag explain $ret;
ok($ret->{'metrics'}{'SCM_COMMITTERS_1W'} =~ /\d+/,
  "Metric SCM_COMMITTERS_1W is a digit " . $ret->{'metrics'}{'SCM_COMMITTERS_1W'} . ".")
  or diag explain $ret;
ok($ret->{'metrics'}{'SCM_COMMITTERS_1M'} =~ /\d+/,
  "Metric SCM_COMMITTERS_1M is a digit " . $ret->{'metrics'}{'SCM_COMMITTERS_1M'} . ".")
    or diag explain $ret;
ok($ret->{'metrics'}{'SCM_COMMITTERS_1Y'} =~ /\d+/,
  "Metric SCM_COMMITTERS_1Y is a digit " . $ret->{'metrics'}{'SCM_COMMITTERS_1Y'} . ".")
    or diag explain $ret;


ok($ret->{'metrics'}{'SCM_MRS'} =~ /\d+/,
  "Metric SCM_MRS is a digit " . $ret->{'metrics'}{'SCM_MRS'} . ".")
    or diag explain $ret;
ok($ret->{'metrics'}{'SCM_MRS_CLOSED'} =~ /\d+/,
  "Metric SCM_MRS_CLOSED is a digit " . $ret->{'metrics'}{'SCM_MRS_CLOSED'} . ".")
    or diag explain $ret;
ok($ret->{'metrics'}{'SCM_MRS_MERGED'} =~ /\d+/,
  "Metric SCM_MRS_MERGED is a digit " . $ret->{'metrics'}{'SCM_MRS_MERGED'} . ".")
  or diag explain $ret;
ok($ret->{'metrics'}{'SCM_MRS_OPENED'} =~ /\d+/,
  "Metric SCM_MRS_OPENED is a digit " . $ret->{'metrics'}{'SCM_MRS_OPENED'} . ".")
  or diag explain $ret;
ok($ret->{'metrics'}{'SCM_MRS_OPENED_1W'} =~ /\d+/,
  "Metric SCM_MRS_OPENED_1W is a digit " . $ret->{'metrics'}{'SCM_MRS_OPENED_1W'} . ".")
  or diag explain $ret;
ok($ret->{'metrics'}{'SCM_MRS_OPENED_1M'} =~ /\d+/,
  "Metric SCM_MRS_OPENED_1M is a digit " . $ret->{'metrics'}{'SCM_MRS_OPENED_1M'} . ".")
    or diag explain $ret;
ok($ret->{'metrics'}{'SCM_MRS_OPENED_1Y'} =~ /\d+/,
  "Metric SCM_MRS_OPENED_1Y is a digit " . $ret->{'metrics'}{'SCM_MRS_OPENED_1Y'} . ".")
  or diag explain $ret;

ok($ret->{'metrics'}{'SCM_MRS_OPENED_STILL_1W'} =~ /\d+/,
  "Metric SCM_MRS_OPENED_STILL_1W is a digit " . $ret->{'metrics'}{'SCM_MRS_OPENED_STILL_1W'} . ".")
  or diag explain $ret;
ok($ret->{'metrics'}{'SCM_MRS_OPENED_STILL_1M'} =~ /\d+/,
  "Metric SCM_MRS_OPENED_STILL_1M is a digit " . $ret->{'metrics'}{'SCM_MRS_OPENED_STILL_1M'} . ".")
  or diag explain $ret;
ok($ret->{'metrics'}{'SCM_MRS_OPENED_STILL_1Y'} =~ /\d+/,
  "Metric SCM_MRS_OPENED_STILL_1Y is a digit " . $ret->{'metrics'}{'SCM_MRS_OPENED_STILL_1Y'} . ".")
    or diag explain $ret;

ok($ret->{'metrics'}{'SCM_MRS_OPENED_STALED_1M'} =~ /\d+/,
  "Metric SCM_MRS_OPENED_STALED_1M is a digit " . $ret->{'metrics'}{'SCM_MRS_OPENED_STALED_1M'} . ".")
    or diag explain $ret;

# Test info results
ok($ret->{'info'}{'GL_COMMITS_URL'} =~ m!https://www.gitlab.com/bbaldassari/Alambic/commits/master!,
  "Info GL_COMMITS_URL is a correct.")
  or diag explain $ret;
ok($ret->{'info'}{'GL_MRS_URL'} =~ m!https://www.gitlab.com/bbaldassari/Alambic/merge_requests!,
  "Info GL_MRS_URL is a correct.")
  or diag explain $ret;

# Checking output/* files
#ok(
#  -e "projects/test.gitlab/output/test.gitlab_import_its.json",
#  "Check that file test.gitlab_import_its.json exists."
#);
#ok(
#  -e "projects/test.gitlab/output/test.gitlab_its_issues.json",
#  "Check that file test.gitlab_import_its_issues.json exists."
#);


done_testing();
exit;

