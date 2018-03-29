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


# Exec plugin for gitlab-runner

my $in_gitlab_url     = "https://www.gitlab.com";
my $in_gitlab_token   = "tiPs2VdkhaDnfmteiToD";

&test_project( "test.gitlab-runner", "gitlab-org/gitlab-runner" );

sub test_project {
    my $project_id = shift;
    my $gitlab_id = shift;

    # Delete files before creating them, so we don't test a previous run.
    unlink (
        "projects/" . $project_id . "/input/" . $project_id . "_import_gitlab_git_commits.json",
        "projects/" . $project_id . "/input/" . $project_id . "_import_gitlab_git_merge_requests.json",
        "projects/" . $project_id . "/input/" . $project_id . "_import_gitlab_project_branches.json",
        "projects/" . $project_id . "/input/" . $project_id . "_import_gitlab_project_contributors.json",
        "projects/" . $project_id . "/input/" . $project_id . "_import_gitlab_project_events.json",
        "projects/" . $project_id . "/input/" . $project_id . "_import_gitlab_project_milestones.json",
        "projects/" . $project_id . "/output/" . $project_id . "_git_commits.csv",
        "projects/" . $project_id . "/output/" . $project_id . "_git_commits.json",
        "projects/" . $project_id . "/output/" . $project_id . "_git_commits_hist.csv",
        "projects/" . $project_id . "/output/" . $project_id . "_git_merge_requests.csv",
        "projects/" . $project_id . "/output/" . $project_id . "_git_merge_requests.json",
        "projects/" . $project_id . "/output/" . $project_id . "_project.inc",
        "projects/" . $project_id . "/output/" . $project_id . "_project_branches.csv",
        "projects/" . $project_id . "/output/" . $project_id . "_project_milestones.csv",
        "projects/" . $project_id . "/output/" . $project_id . "_info_gitlab_project.csv",
        "projects/" . $project_id . "/output/" . $project_id . "_metrics_gitlab_project.csv",
        "projects/" . $project_id . "/output/" . $project_id . "_metrics_gitlab_project.json",
        );

    note("Executing the plugin with " . $project_id . " project. ");
    my $ret = $plugin->run_plugin(
        $project_id,
        { 'gitlab_url' => $in_gitlab_url, 
          'gitlab_id' => $gitlab_id,
          'gitlab_token' => $in_gitlab_token });

# Test log
    my @log = @{$ret->{'log'}}; 
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
    ok(exists($ret->{'info'}{'PROJECT_CI_ENABLED'}),
       "Info PROJECT_CI_ENABLED exists.")
        or diag explain $ret;
    ok($ret->{'info'}{'PROJECT_CI_URL'} =~ m!https://www.gitlab.com/!,
       "Info PROJECT_CI_URL starts with https://gitlab.com.")
        or diag explain $ret;
    ok($ret->{'info'}{'PROJECT_COMMITS_URL'} =~ m!https://www.gitlab.com/!,
       "Info PROJECT_COMMITS_URL starts with https://gitlab.com.")
        or diag explain $ret;
    ok(exists($ret->{'info'}{'PROJECT_CREATED_AT'}),
       "Info PROJECT_CREATED_AT exists.")
        or diag explain $ret;
    ok(exists($ret->{'info'}{'PROJECT_ISSUES_ENABLED'}),
       "Info PROJECT_ISSUES_ENABLED exists.")
        or diag explain $ret;
    ok($ret->{'info'}{'PROJECT_ISSUES_URL'} =~ m!https://www.gitlab.com/!,
       "Info PROJECT_ISSUES_URL starts with https://gitlab.com.")
        or diag explain $ret;
    ok(exists($ret->{'info'}{'PROJECT_MRS_ENABLED'}),
       "Info PROJECT_MRS_ENABLED exists.")
        or diag explain $ret;
    ok($ret->{'info'}{'PROJECT_MRS_URL'} =~ m!https://www.gitlab.com/!,
       "Info PROJECT_MRS_URL starts with https://gitlab.com.")
        or diag explain $ret;
    ok(exists($ret->{'info'}{'PROJECT_NAME_SPACE'}),
       "Info PROJECT_COMMITS_URL exists.")
        or diag explain $ret;
    ok(exists($ret->{'info'}{'PROJECT_OWNER_ID'}),
       "Info PROJECT_OWNER_ID exists.")
        or diag explain $ret;
    ok(exists($ret->{'info'}{'PROJECT_OWNER_NAME'}),
       "Info PROJECT_OWNER_NAME exists.")
        or diag explain $ret;
    ok($ret->{'info'}{'PROJECT_REPO_HTTP'} =~ m!https://gitlab.com/!,
       "Info PROJECT_REPO_HTTP starts with https://gitlab.com.")
        or diag explain $ret;
    ok($ret->{'info'}{'PROJECT_REPO_SSH'} =~ m!git\@gitlab.com:!,
       "Info PROJECT_REPO_SSH starts with https://gitlab.com.")
        or diag explain $ret;
    ok(exists($ret->{'info'}{'PROJECT_SNIPPETS_ENABLED'}),
       "Info PROJECT_SNIPPETS_ENABLED exists.")
        or diag explain $ret; 
    ok($ret->{'info'}{'PROJECT_URL'} =~ m!https://www.gitlab.com/!,
       "Info PROJECT_URL starts with https://gitlab.com.")
        or diag explain $ret;
    ok($ret->{'info'}{'PROJECT_VISIBILITY'} =~ m!public!,
       "Info PROJECT_VISIBILITY is public.")
        or diag explain $ret;
    ok($ret->{'info'}{'PROJECT_WEB'} =~ m!https://gitlab.com/!,
       "Info PROJECT_WEB starts with https://gitlab.com.")
        or diag explain $ret;
    ok(exists($ret->{'info'}{'PROJECT_WIKI_ENABLED'}),
       "Info PROJECT_WIKI_ENABLED exists.")
        or diag explain $ret; 
    ok(exists($ret->{'info'}{'PROJECT_WIKI_URL'}),
       "Info PROJECT_WIKI_URL exists.")
        or diag explain $ret;

    # Checking output/* files
    ok(
        -e "projects/" . $project_id . "/input/" . $project_id . "_import_gitlab_git_commits.json",
        "Check that file " . $project_id . "_import_gitlab_git_commits.json exists."
        );
    ok(
        -e "projects/" . $project_id . "/input/" . $project_id . "_import_gitlab_git_merge_requests.json",
        "Check that file " . $project_id . "_import_gitlab_git_merge_requests.json exists."
        );
    ok(
        -e "projects/" . $project_id . "/input/" . $project_id . "_import_gitlab_project_branches.json",
        "Check that file " . $project_id . "_import_gitlab_project_branches.json exists."
        );
    ok(
        -e "projects/" . $project_id . "/input/" . $project_id . "_import_gitlab_project_contributors.json",
        "Check that file " . $project_id . "_import_gitlab_project_contributors.json exists."
        );
    ok(
        -e "projects/" . $project_id . "/input/" . $project_id . "_import_gitlab_project_events.json",
        "Check that file " . $project_id . "_import_gitlab_project_events.json exists."
        );
    ok(
        -e "projects/" . $project_id . "/input/" . $project_id . "_import_gitlab_project_milestones.json",
        "Check that file " . $project_id . "_import_gitlab_project_milestones.json exists."
        );

    ok(
        -e "projects/" . $project_id . "/output/" . $project_id . "_gitlab_git_commits.csv",
        "Check that file " . $project_id . "_git_commits.csv exists."
        );
    ok(
        -e "projects/" . $project_id . "/output/" . $project_id . "_gitlab_git_commits.json",
        "Check that file " . $project_id . "_git_commits.json exists."
        );
    ok(
        -e "projects/" . $project_id . "/output/" . $project_id . "_gitlab_git_commits_hist.csv",
        "Check that file " . $project_id . "_git_commits_hist.csv exists."
        );
    ok(
        -e "projects/" . $project_id . "/output/" . $project_id . "_gitlab_git_merge_requests.csv",
        "Check that file " . $project_id . "_git_merge_requests.csv exists."
        );
    ok(
        -e "projects/" . $project_id . "/output/" . $project_id . "_gitlab_git_merge_requests.json",
        "Check that file " . $project_id . "_git_merge_requests.json exists."
        );
    ok(
        -e "projects/" . $project_id . "/output/" . $project_id . "_gitlab_project.inc",
        "Check that file " . $project_id . "_project.inc exists."
        );
    ok(
        -e "projects/" . $project_id . "/output/" . $project_id . "_gitlab_project_branches.csv",
        "Check that file " . $project_id . "_project_branches.csv exists."
        );
    ok(
        -e "projects/" . $project_id . "/output/" . $project_id . "_gitlab_project_milestones.csv",
        "Check that file " . $project_id . "_project_milestones.csv exists."
        );
    ok(
        -e "projects/" . $project_id . "/output/" . $project_id . "_info_gitlab_project.csv",
        "Check that file " . $project_id . "_info_gitlab_project.csv exists."
        );
    ok(
        -e "projects/" . $project_id . "/output/" . $project_id . "_metrics_gitlab_project.csv",
        "Check that file " . $project_id . "_metrics_gitlab_project.csv exists."
        );
    ok(
        -e "projects/" . $project_id . "/output/" . $project_id . "_metrics_gitlab_project.json",
        "Check that file " . $project_id . "_metrics_gitlab_project.json exists."
        );
}

done_testing();
exit;

