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

BEGIN { use_ok('Alambic::Plugins::GitLabProject'); }

my $plugin = Alambic::Plugins::GitLabProject->new();
isa_ok($plugin, 'Alambic::Plugins::GitLabProject');

note("Checking the plugin parameters. ");
my $conf = $plugin->get_conf();

# Check params

ok(grep(m!gitlab_url!, keys %{$conf->{'params'}}), "Conf has params > gitlab_url");
ok(grep(m!gitlab_id!, keys %{$conf->{'params'}}), "Conf has params > gitlab_id");
ok(grep(m!gitlab_token!, keys %{$conf->{'params'}}), "Conf has params > gitlab_token");

# Check provides_data

ok(grep(m!import_gitlab_project_contributors.json!, keys %{$conf->{'provides_data'}}),
   "Conf has provides_data > import_gitlab_git_contributors.json");
ok(grep(m!import_gitlab_project_events.json!, keys %{$conf->{'provides_data'}}),
   "Conf has provides_data > import_gitlab_git_events.json");
ok(grep(m!import_gitlab_project_branches.json!, keys %{$conf->{'provides_data'}}),
   "Conf has provides_data > import_gitlab_git_branches.json");
ok(grep(m!import_gitlab_project_commits.json!, keys %{$conf->{'provides_data'}}),
   "Conf has provides_data > import_gitlab_project_commits.json");
ok(grep(m!import_gitlab_project_merge_requests.json!, keys %{$conf->{'provides_data'}}),
   "Conf has provides_data > import_gitlab_project_merge_requests.json");

ok(grep(m!metrics_gitlab_project.csv!, keys %{$conf->{'provides_data'}}),
   "Conf has provides_data > metrics_gitlab_project.csv");
ok(grep(m!metrics_gitlab_project.json!, keys %{$conf->{'provides_data'}}),
   "Conf has provides_data > metrics_gitlab_project.json");
ok(grep(m!info_gitlab_project.csv!, keys %{$conf->{'provides_data'}}),
   "Conf has provides_data > info_gitlab_project.csv");

ok(grep(m!gitlab_project_branches.csv!, keys %{$conf->{'provides_data'}}),
   "Conf has provides_data > gitlab_project_branches.csv");
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

# Check provides_info

ok(grep(m!PROJECT_COMMITS_URL!, @{$conf->{'provides_info'}}),
   "Conf has provides_info > project_commits_url");
ok(grep(m!PROJECT_URL!, @{$conf->{'provides_info'}}),
   "Conf has provides_info > project_url");
ok(grep(m!PROJECT_NAME_SPACE!, @{$conf->{'provides_info'}}),
   "Conf has provides_info > project_name_space");
ok(grep(m!PROJECT_AVATAR!, @{$conf->{'provides_info'}}),
   "Conf has provides_info > project_avatar");
ok(grep(m!PROJECT_WEB!, @{$conf->{'provides_info'}}),
   "Conf has provides_info > project_web");
ok(grep(m!PROJECT_OWNER_ID!, @{$conf->{'provides_info'}}),
   "Conf has provides_info > project_owner_id");
ok(grep(m!PROJECT_OWNER_NAME!, @{$conf->{'provides_info'}}),
   "Conf has provides_info > project_owner_name");
ok(grep(m!PROJECT_ISSUES_ENABLED!, @{$conf->{'provides_info'}}),
   "Conf has provides_info > project_issues_enabled");
ok(grep(m!PROJECT_ISSUES_URL!, @{$conf->{'provides_info'}}),
   "Conf has provides_info > project_issues_url");
ok(grep(m!PROJECT_CI_ENABLED!, @{$conf->{'provides_info'}}),
   "Conf has provides_info > project_ci_enabled");
ok(grep(m!PROJECT_CI_URL!, @{$conf->{'provides_info'}}),
   "Conf has provides_info > project_ci_url");
ok(grep(m!PROJECT_WIKI_ENABLED!, @{$conf->{'provides_info'}}),
   "Conf has provides_info > project_wiki_enabled");
ok(grep(m!PROJECT_WIKI_URL!, @{$conf->{'provides_info'}}),
   "Conf has provides_info > project_wiki_url");
ok(grep(m!PROJECT_MRS_ENABLED!, @{$conf->{'provides_info'}}),
   "Conf has provides_info > project_mrs_enabled");
ok(grep(m!PROJECT_MRS_URL!, @{$conf->{'provides_info'}}),
   "Conf has provides_info > project_mrs_url");
ok(grep(m!PROJECT_SNIPPETS_ENABLED!, @{$conf->{'provides_info'}}),
   "Conf has provides_info > project_snippets_enabled");
ok(grep(m!PROJECT_CREATED_AT!, @{$conf->{'provides_info'}}),
   "Conf has provides_info > project_created_at");
ok(grep(m!PROJECT_VISIBILITY!, @{$conf->{'provides_info'}}),
   "Conf has provides_info > project_visibility");
ok(grep(m!PROJECT_REPO_SSH!, @{$conf->{'provides_info'}}),
   "Conf has provides_info > project_repo_ssh");
ok(grep(m!PROJECT_REPO_HTTP!, @{$conf->{'provides_info'}}),
   "Conf has provides_info > project_repo_http");

# Check provides_metrics
   
ok(grep(m!PROJECT_ISSUES_OPEN!, map { $conf->{'provides_metrics'}{$_} } keys %{$conf->{'provides_metrics'}}),
   "Conf has provides_metrics > project_issues_open");
ok(grep(m!PROJECT_FORKS!, map { $conf->{'provides_metrics'}{$_} } keys %{$conf->{'provides_metrics'}}),
   "Conf has provides_metrics > project_forks");
ok(grep(m!PROJECT_STARS!, map { $conf->{'provides_metrics'}{$_} } keys %{$conf->{'provides_metrics'}}),
   "Conf has provides_metrics > project_stars");
ok(grep(m!PROJECT_LAST_ACTIVITY_AT!, map { $conf->{'provides_metrics'}{$_} } keys %{$conf->{'provides_metrics'}}),
   "Conf has provides_metrics > project_last_activity_at");
   
ok(grep(m!PROJECT_AUTHORS!, map { $conf->{'provides_metrics'}{$_} } keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > project_authors");
ok(grep(m!PROJECT_AUTHORS_1W!, map { $conf->{'provides_metrics'}{$_} } keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > project_authors_1w");
ok(grep(m!PROJECT_AUTHORS_1M!, map { $conf->{'provides_metrics'}{$_} } keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > project_authors_1m");
ok(grep(m!PROJECT_AUTHORS_1Y!, map { $conf->{'provides_metrics'}{$_} } keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > project_authors_1y");

ok(grep(m!PROJECT_COMMITS!, map { $conf->{'provides_metrics'}{$_} } keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > project_commits");
ok(grep(m!PROJECT_COMMITS_1W!, map { $conf->{'provides_metrics'}{$_} } keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > project_commits_1w");
ok(grep(m!PROJECT_COMMITS_1M!, map { $conf->{'provides_metrics'}{$_} } keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > project_commits_1m");
ok(grep(m!PROJECT_COMMITS_1Y!, map { $conf->{'provides_metrics'}{$_} } keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > project_commits_1y");

ok(grep(m!PROJECT_COMMITTERS!, map { $conf->{'provides_metrics'}{$_} } keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > project_committers");
ok(grep(m!PROJECT_COMMITTERS_1W!, map { $conf->{'provides_metrics'}{$_} } keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > project_committers_1w");
ok(grep(m!PROJECT_COMMITTERS_1M!, map { $conf->{'provides_metrics'}{$_} } keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > project_committers_1m");
ok(grep(m!PROJECT_COMMITTERS_1Y!, map { $conf->{'provides_metrics'}{$_} } keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > project_committers_1y");

ok(grep(m!SCM_PRS!, map { $conf->{'provides_metrics'}{$_} } keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > scm_prs");
ok(grep(m!SCM_PRS_OPENED!, map { $conf->{'provides_metrics'}{$_} } keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > scm_prs_opened");
ok(grep(m!SCM_PRS_OPENED_1W!, map { $conf->{'provides_metrics'}{$_} } keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > scm_prs_opened_1w");
ok(grep(m!SCM_PRS_OPENED_1M!, map { $conf->{'provides_metrics'}{$_} } keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > scm_prs_opened_1m");
ok(grep(m!SCM_PRS_OPENED_1Y!, map { $conf->{'provides_metrics'}{$_} } keys %{$conf->{'provides_metrics'}}),
   "Conf has provides_metrics > scm_prs_opened_1y");

ok(grep(m!SCM_PRS_OPENED_STILL!, map { $conf->{'provides_metrics'}{$_} } keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > scm_prs_opened_still");
ok(grep(m!SCM_PRS_OPENED_STILL_1W!, map { $conf->{'provides_metrics'}{$_} } keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > scm_prs_opened_still_1w");
ok(grep(m!SCM_PRS_OPENED_STILL_1M!, map { $conf->{'provides_metrics'}{$_} } keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > scm_prs_opened_still_1m");
ok(grep(m!SCM_PRS_OPENED_STILL_1Y!, map { $conf->{'provides_metrics'}{$_} } keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > scm_prs_opened_still_1y");
ok(grep(m!SCM_PRS_OPENED_STALED_1M!, map { $conf->{'provides_metrics'}{$_} } keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > scm_prs_opened_staled_1m");

ok(grep(m!SCM_PRS_CLOSED!, map { $conf->{'provides_metrics'}{$_} } keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > scm_prs_closed");
ok(grep(m!SCM_PRS_MERGED!, map { $conf->{'provides_metrics'}{$_} } keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > scm_prs_merged");


ok(grep(m!metrics!, @{$conf->{'ability'}}), "Conf has ability > metrics");
ok(grep(m!info!,    @{$conf->{'ability'}}), "Conf has ability > info");
ok(grep(m!figs!,    @{$conf->{'ability'}}) == 0, "Conf has ability > figs");
ok(grep(m!data!,    @{$conf->{'ability'}}), "Conf has ability > data");
ok(grep(m!recs!,    @{$conf->{'ability'}}) == 0, "Conf has ability > recs");
ok(grep(m!viz!,     @{$conf->{'ability'}}), "Conf has ability > viz");

# Exec plugin

my $in_gitlab_url     = "https://www.gitlab.com";
my $in_gitlab_id      = "bbaldassari/Alambic";
my $in_gitlab_token   = "tiPs2VdkhaDnfmteiToD";



# Delete files before creating them, so we don't test a previous run.
unlink (
    "projects/test.gitlabproject/input/test.gitlabproject_import_gitlab_git_commits.json",
    "projects/test.gitlabproject/input/test.gitlabproject_import_gitlab_git_merge_requests.json",
    "projects/test.gitlabproject/input/test.gitlabproject_import_gitlab_project_branches.json",
    "projects/test.gitlabproject/input/test.gitlabproject_import_gitlab_project_contributors.json",
    "projects/test.gitlabproject/input/test.gitlabproject_import_gitlab_project_events.json",
    "projects/test.gitlabproject/input/test.gitlabproject_import_gitlab_project_milestones.json",
    "projects/test.gitlabproject/output/test.gitlabproject_git_commits.csv",
    "projects/test.gitlabproject/output/test.gitlabproject_git_commits.json",
    "projects/test.gitlabproject/output/test.gitlabproject_git_commits_hist.csv",
    "projects/test.gitlabproject/output/test.gitlabproject_git_merge_requests.csv",
    "projects/test.gitlabproject/output/test.gitlabproject_git_merge_requests.json",
    "projects/test.gitlabproject/output/test.gitlabproject_project.inc",
    "projects/test.gitlabproject/output/test.gitlabproject_project_branches.csv",
    "projects/test.gitlabproject/output/test.gitlabproject_project_milestones.csv",
    "projects/test.gitlabproject/output/test.gitlabproject_info_gitlab_project.csv",
    "projects/test.gitlabproject/output/test.gitlabproject_metrics_gitlab_project.csv",
    "projects/test.gitlabproject/output/test.gitlabproject_metrics_gitlab_project.json",
    );

note("Executing the plugin with Alambic project. ");
my $ret = $plugin->run_plugin(
    "test.gitlabproject",
    { 'gitlab_url' => $in_gitlab_url, 
      'gitlab_id' => $in_gitlab_id,
      'gitlab_token' => $in_gitlab_token });

# Test log
my @log = @{$ret->{'log'}}; print "LOG " . Dumper( @log );
ok(grep(!/^ERROR/, @log), "Log returns no ERROR") or diag explain @log;
ok(grep(m!^\[Plugins::GitLabProject\] Retrieving project.!, @log),
  "Log returns Retrieving project.")
  or diag explain @log;
ok(grep(m!^\[Plugins::GitLabProject\] Retrieved Commits info from \[http!, @log),
  "Log returns Retrieved commits.")
  or diag explain @log;
ok(grep(m!^\[Plugins::GitLabProject\] Retrieved Merge requests info from \[http!, @log),
  "Log returns Retrieved Merge requests.")
  or diag explain @log;
ok(grep(m!^\[Plugins::GitLabProject\] Retrieving contributors.!, @log),
  "Log returns Retrieving contributors.")
  or diag explain @log;
ok(grep(m!^\[Plugins::GitLabProject\] Writing user events file.!, @log),
  "Log returns User event file.")
  or diag explain @log;
ok(grep(m!^\[Tools::R\] Exec \[Rscript -e "library\(rmarkdown\).!, @log),
  "Log returns R exec.")
  or diag explain @log;
ok(grep(m!^\[Tools::R\] Moved main file!, @log),
  "Log returns R moved main file.")
  or diag explain @log;

# Test metrics
ok($ret->{'metrics'}{'PROJECT_COMMITS'} =~ /\d+/,
  "Metric PROJECT_COMMITS is a digit " . $ret->{'metrics'}{'PROJECT_COMMITS'} . ".")
    or diag explain $ret;
ok($ret->{'metrics'}{'PROJECT_COMMITS_1W'} =~ /\d+/,
  "Metric PROJECT_COMMITS_1W is a digit " . $ret->{'metrics'}{'PROJECT_COMMITS_1W'} . ".")
  or diag explain $ret;
ok($ret->{'metrics'}{'PROJECT_COMMITS_1M'} =~ /\d+/,
  "Metric PROJECT_COMMITS_1M is a digit " . $ret->{'metrics'}{'PROJECT_COMMITS_1M'} . ".")
  or diag explain $ret;
ok($ret->{'metrics'}{'PROJECT_COMMITS_1Y'} =~ /\d+/,
  "Metric PROJECT_COMMITS_1Y is a digit " . $ret->{'metrics'}{'PROJECT_COMMITS_1Y'} . ".")
  or diag explain $ret;

ok($ret->{'metrics'}{'PROJECT_AUTHORS'} =~ /\d+/,
  "Metric PROJECT_AUTHORS is a digit " . $ret->{'metrics'}{'PROJECT_AUTHORS'} . ".")
  or diag explain $ret;
ok($ret->{'metrics'}{'PROJECT_AUTHORS_1W'} =~ /\d+/,
  "Metric PROJECT_AUTHORS_1W is a digit " . $ret->{'metrics'}{'PROJECT_AUTHORS_1W'} . ".")
  or diag explain $ret;
ok($ret->{'metrics'}{'PROJECT_AUTHORS_1M'} =~ /\d+/,
  "Metric PROJECT_AUTHORS_1M is a digit " . $ret->{'metrics'}{'PROJECT_AUTHORS_1M'} . ".")
  or diag explain $ret;
ok($ret->{'metrics'}{'PROJECT_AUTHORS_1Y'} =~ /\d+/,
  "Metric PROJECT_AUTHORS_1Y is a digit " . $ret->{'metrics'}{'PROJECT_AUTHORS_1Y'} . ".")
    or diag explain $ret;

ok($ret->{'metrics'}{'PROJECT_COMMITTERS'} =~ /\d+/,
  "Metric PROJECT_COMMITTERS is a digit " . $ret->{'metrics'}{'PROJECT_COMMITTERS'} . ".")
  or diag explain $ret;
ok($ret->{'metrics'}{'PROJECT_COMMITTERS_1W'} =~ /\d+/,
  "Metric PROJECT_COMMITTERS_1W is a digit " . $ret->{'metrics'}{'PROJECT_COMMITTERS_1W'} . ".")
  or diag explain $ret;
ok($ret->{'metrics'}{'PROJECT_COMMITTERS_1M'} =~ /\d+/,
  "Metric PROJECT_COMMITTERS_1M is a digit " . $ret->{'metrics'}{'PROJECT_COMMITTERS_1M'} . ".")
    or diag explain $ret;
ok($ret->{'metrics'}{'PROJECT_COMMITTERS_1Y'} =~ /\d+/,
  "Metric PROJECT_COMMITTERS_1Y is a digit " . $ret->{'metrics'}{'PROJECT_COMMITTERS_1Y'} . ".")
    or diag explain $ret;


ok($ret->{'metrics'}{'SCM_PRS'} =~ /\d+/,
  "Metric SCM_PRS is a digit " . $ret->{'metrics'}{'SCM_PRS'} . ".")
    or diag explain $ret;
ok($ret->{'metrics'}{'SCM_PRS_CLOSED'} =~ /\d+/,
  "Metric SCM_PRS_CLOSED is a digit " . $ret->{'metrics'}{'SCM_PRS_CLOSED'} . ".")
    or diag explain $ret;
ok($ret->{'metrics'}{'SCM_PRS_MERGED'} =~ /\d+/,
  "Metric SCM_PRS_MERGED is a digit " . $ret->{'metrics'}{'SCM_PRS_MERGED'} . ".")
  or diag explain $ret;
ok($ret->{'metrics'}{'SCM_PRS_OPENED'} =~ /\d+/,
  "Metric SCM_PRS_OPENED is a digit " . $ret->{'metrics'}{'SCM_PRS_OPENED'} . ".")
  or diag explain $ret;
ok($ret->{'metrics'}{'SCM_PRS_OPENED_1W'} =~ /\d+/,
  "Metric SCM_PRS_OPENED_1W is a digit " . $ret->{'metrics'}{'SCM_PRS_OPENED_1W'} . ".")
  or diag explain $ret;
ok($ret->{'metrics'}{'SCM_PRS_OPENED_1M'} =~ /\d+/,
  "Metric SCM_PRS_OPENED_1M is a digit " . $ret->{'metrics'}{'SCM_PRS_OPENED_1M'} . ".")
    or diag explain $ret;
ok($ret->{'metrics'}{'SCM_PRS_OPENED_1Y'} =~ /\d+/,
  "Metric SCM_PRS_OPENED_1Y is a digit " . $ret->{'metrics'}{'SCM_PRS_OPENED_1Y'} . ".")
  or diag explain $ret;

ok($ret->{'metrics'}{'SCM_PRS_OPENED_STILL_1W'} =~ /\d+/,
  "Metric SCM_PRS_OPENED_STILL_1W is a digit " . $ret->{'metrics'}{'SCM_PRS_OPENED_STILL_1W'} . ".")
  or diag explain $ret;
ok($ret->{'metrics'}{'SCM_PRS_OPENED_STILL_1M'} =~ /\d+/,
  "Metric SCM_PRS_OPENED_STILL_1M is a digit " . $ret->{'metrics'}{'SCM_PRS_OPENED_STILL_1M'} . ".")
  or diag explain $ret;
ok($ret->{'metrics'}{'SCM_PRS_OPENED_STILL_1Y'} =~ /\d+/,
  "Metric SCM_PRS_OPENED_STILL_1Y is a digit " . $ret->{'metrics'}{'SCM_PRS_OPENED_STILL_1Y'} . ".")
    or diag explain $ret;

ok($ret->{'metrics'}{'SCM_PRS_OPENED_STALED_1M'} =~ /\d+/,
  "Metric SCM_PRS_OPENED_STALED_1M is a digit " . $ret->{'metrics'}{'SCM_PRS_OPENED_STALED_1M'} . ".")
    or diag explain $ret;

# Test info results
ok($ret->{'info'}{'PROJECT_CI_ENABLED'} == 1,
  "Info PROJECT_CI_ENABLED is 1.")
  or diag explain $ret;
ok($ret->{'info'}{'PROJECT_CI_URL'} =~ m!https://www.gitlab.com/bbaldassari/Alambic/pipelines!,
  "Info PROJECT_CI_URL is correct.")
  or diag explain $ret;
ok($ret->{'info'}{'PROJECT_COMMITS_URL'} =~ m!https://www.gitlab.com/bbaldassari/Alambic/commits/master!,
  "Info PROJECT_COMMITS_URL is correct.")
  or diag explain $ret;
ok($ret->{'info'}{'PROJECT_CREATED_AT'} =~ m!2016-12-25T22:43:49.851Z!,
  "Info PROJECT_CREATED_AT is correct.")
  or diag explain $ret;
ok($ret->{'info'}{'PROJECT_ISSUES_ENABLED'} == 1,
  "Info PROJECT_ISSUES_ENABLED is 1.")
  or diag explain $ret;
ok($ret->{'info'}{'PROJECT_ISSUES_URL'} =~ m!https://www.gitlab.com/bbaldassari/Alambic/issues!,
  "Info PROJECT_ISSUES_URL is correct.")
  or diag explain $ret;
ok($ret->{'info'}{'PROJECT_MRS_ENABLED'} == 1,
  "Info PROJECT_MRS_ENABLED is 1.")
  or diag explain $ret;
ok($ret->{'info'}{'PROJECT_MRS_URL'} =~ m!https://www.gitlab.com/bbaldassari/Alambic/merge_requests!,
  "Info PROJECT_MRS_URL is correct.")
  or diag explain $ret;
ok($ret->{'info'}{'PROJECT_NAME_SPACE'} =~ m!Boris Baldassari / Alambic!,
  "Info PROJECT_COMMITS_URL is correct.")
  or diag explain $ret;
ok($ret->{'info'}{'PROJECT_OWNER_ID'} =~ m!905787!,
  "Info PROJECT_OWNER_ID is correct.")
  or diag explain $ret;
ok($ret->{'info'}{'PROJECT_OWNER_NAME'} =~ m!Boris Baldassari!,
  "Info PROJECT_OWNER_NAME is correct.")
  or diag explain $ret;
ok($ret->{'info'}{'PROJECT_REPO_HTTP'} =~ m!https://gitlab.com/bbaldassari/Alambic.git!,
  "Info PROJECT_REPO_HTTP is correct.")
  or diag explain $ret;
ok($ret->{'info'}{'PROJECT_REPO_SSH'} =~ m!git\@gitlab.com:bbaldassari/Alambic.git!,
  "Info PROJECT_REPO_SSH is correct.")
  or diag explain $ret;
ok($ret->{'info'}{'PROJECT_SNIPPETS_ENABLED'} == 0,
  "Info PROJECT_SNIPPETS_ENABLED is 0.")
    or diag explain $ret; print "URL " . Dumper($ret->{'info'}{'PROJECT_URL'});
ok($ret->{'info'}{'PROJECT_URL'} =~ m!https://www.gitlab.com/bbaldassari/Alambic!,
  "Info PROJECT_URL is correct.")
  or diag explain $ret;
ok($ret->{'info'}{'PROJECT_VISIBILITY'} =~ m!public!,
  "Info PROJECT_VISIBILITY is correct.")
  or diag explain $ret;
ok($ret->{'info'}{'PROJECT_WEB'} =~ m!https://gitlab.com/bbaldassari/Alambic!,
  "Info PROJECT_WEB is correct.")
  or diag explain $ret;
ok($ret->{'info'}{'PROJECT_WIKI_ENABLED'} == 1,
  "Info PROJECT_WIKI_ENABLED is 1.")
  or diag explain $ret; print "WIKI " . Dumper($ret->{'info'}{'PROJECT_WIKI_URL'});
ok($ret->{'info'}{'PROJECT_WIKI_URL'} =~ m!https://www.gitlab.com/bbaldassari/Alambic/wikis/home!,
  "Info PROJECT_WIKI_URL is correct.")
  or diag explain $ret;

# Checking output/* files
ok(
 -e "projects/test.gitlabproject/input/test.gitlabproject_import_gitlab_git_commits.json",
 "Check that file test.gitlabproject_import_gitlab_git_commits.json exists."
);
ok(
 -e "projects/test.gitlabproject/input/test.gitlabproject_import_gitlab_git_merge_requests.json",
 "Check that file test.gitlabproject_import_gitlab_git_merge_requests.json exists."
);
ok(
 -e "projects/test.gitlabproject/input/test.gitlabproject_import_gitlab_project_branches.json",
 "Check that file test.gitlabproject_import_gitlab_project_branches.json exists."
);
ok(
 -e "projects/test.gitlabproject/input/test.gitlabproject_import_gitlab_project_contributors.json",
 "Check that file test.gitlabproject_import_gitlab_project_contributors.json exists."
);
ok(
 -e "projects/test.gitlabproject/input/test.gitlabproject_import_gitlab_project_events.json",
 "Check that file test.gitlabproject_import_gitlab_project_events.json exists."
);
ok(
 -e "projects/test.gitlabproject/input/test.gitlabproject_import_gitlab_project_milestones.json",
 "Check that file test.gitlabproject_import_gitlab_project_milestones.json exists."
);

ok(
 -e "projects/test.gitlabproject/output/test.gitlabproject_gitlab_git_commits.csv",
 "Check that file test.gitlabproject_git_commits.csv exists."
);
ok(
 -e "projects/test.gitlabproject/output/test.gitlabproject_gitlab_git_commits.json",
 "Check that file test.gitlabproject_git_commits.json exists."
);
ok(
 -e "projects/test.gitlabproject/output/test.gitlabproject_gitlab_git_commits_hist.csv",
 "Check that file test.gitlabproject_git_commits_hist.csv exists."
);
ok(
 -e "projects/test.gitlabproject/output/test.gitlabproject_gitlab_git_merge_requests.csv",
 "Check that file test.gitlabproject_git_merge_requests.csv exists."
);
ok(
 -e "projects/test.gitlabproject/output/test.gitlabproject_gitlab_git_merge_requests.json",
 "Check that file test.gitlabproject_git_merge_requests.json exists."
);
ok(
 -e "projects/test.gitlabproject/output/test.gitlabproject_gitlab_project.inc",
 "Check that file test.gitlabproject_project.inc exists."
);
ok(
 -e "projects/test.gitlabproject/output/test.gitlabproject_gitlab_project_branches.csv",
 "Check that file test.gitlabproject_project_branches.csv exists."
);
ok(
 -e "projects/test.gitlabproject/output/test.gitlabproject_gitlab_project_milestones.csv",
 "Check that file test.gitlabproject_project_milestones.csv exists."
);
ok(
 -e "projects/test.gitlabproject/output/test.gitlabproject_info_gitlab_project.csv",
 "Check that file test.gitlabproject_info_gitlab_project.csv exists."
);
ok(
 -e "projects/test.gitlabproject/output/test.gitlabproject_metrics_gitlab_project.csv",
 "Check that file test.gitlabproject_metrics_gitlab_project.csv exists."
);
ok(
 -e "projects/test.gitlabproject/output/test.gitlabproject_metrics_gitlab_project.json",
 "Check that file test.gitlabproject_metrics_gitlab_project.json exists."
);


done_testing();
exit;

