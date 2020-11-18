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
use Mojo::JSON qw( decode_json );
use Data::Dumper;

BEGIN { use_ok('Alambic::Plugins::GitHubProject'); }

my $plugin = Alambic::Plugins::GitHubProject->new();
isa_ok($plugin, 'Alambic::Plugins::GitHubProject');

note("Checking the plugin parameters. ");
my $conf = $plugin->get_conf();

# Check params

ok(grep(m!github_url!, keys %{$conf->{'params'}}), "Conf has params > github_url");
ok(grep(m!github_user!, keys %{$conf->{'params'}}), "Conf has params > github_user");
ok(grep(m!github_repo!, keys %{$conf->{'params'}}), "Conf has params > github_repo");
ok(grep(m!github_token!, keys %{$conf->{'params'}}), "Conf has params > github_token");

# Check provides_data
### XXXfinish test implentation here
ok(grep(m!import_github_project.json!, keys %{$conf->{'provides_data'}}),
   "Conf has provides_data > import_github_project.json");
ok(grep(m!import_github_project_contributors.json!, keys %{$conf->{'provides_data'}}),
   "Conf has provides_data > import_github_project_contributors.json");
ok(grep(m!import_github_project_events.json!, keys %{$conf->{'provides_data'}}),
   "Conf has provides_data > import_github_project_events.json");
ok(grep(m!import_github_project_languages.json!, keys %{$conf->{'provides_data'}}),
   "Conf has provides_data > import_github_project_languages.json");
ok(grep(m!import_github_project_tags.json!, keys %{$conf->{'provides_data'}}),
   "Conf has provides_data > import_github_project_tags.json");

ok(grep(m!metrics_github_project.csv!, keys %{$conf->{'provides_data'}}),
   "Conf has provides_data > metrics_github_project.csv");
ok(grep(m!metrics_github_project.json!, keys %{$conf->{'provides_data'}}),
   "Conf has provides_data > metrics_github_project.json");
ok(grep(m!info_github_project.csv!, keys %{$conf->{'provides_data'}}),
   "Conf has provides_data > info_github_project.csv");

# Check provides_info

ok(grep(m!PROJECT_COMMITS_URL!, @{$conf->{'provides_info'}}),
   "Conf has provides_info > project_commits_url");
ok(grep(m!PROJECT_ID!, @{$conf->{'provides_info'}}),
   "Conf has provides_info > project_id");
ok(grep(m!PROJECT_URL!, @{$conf->{'provides_info'}}),
   "Conf has provides_info > project_url");
ok(grep(m!PROJECT_WEB_ENABLED!, @{$conf->{'provides_info'}}),
   "Conf has provides_info > project_web_enabled");
#ok(grep(m!PROJECT_WEB_URL!, @{$conf->{'provides_info'}}),
#   "Conf has provides_info > project_web_url");
ok(grep(m!PROJECT_OWNER_ID!, @{$conf->{'provides_info'}}),
   "Conf has provides_info > project_owner_id");
ok(grep(m!PROJECT_OWNER_NAME!, @{$conf->{'provides_info'}}),
   "Conf has provides_info > project_owner_name");
ok(grep(m!PROJECT_ISSUES_ENABLED!, @{$conf->{'provides_info'}}),
   "Conf has provides_info > project_issues_enabled");
ok(grep(m!PROJECT_ISSUES_URL!, @{$conf->{'provides_info'}}),
   "Conf has provides_info > project_issues_url");
#ok(grep(m!PROJECT_CI_ENABLED!, @{$conf->{'provides_info'}}),
#   "Conf has provides_info > project_ci_enabled");
#ok(grep(m!PROJECT_CI_URL!, @{$conf->{'provides_info'}}),
#   "Conf has provides_info > project_ci_url");
ok(grep(m!PROJECT_WIKI_ENABLED!, @{$conf->{'provides_info'}}),
   "Conf has provides_info > project_wiki_enabled");
ok(grep(m!PROJECT_WIKI_URL!, @{$conf->{'provides_info'}}),
   "Conf has provides_info > project_wiki_url");
#ok(grep(m!PROJECT_MRS_ENABLED!, @{$conf->{'provides_info'}}),
#   "Conf has provides_info > project_mrs_enabled");
#ok(grep(m!PROJECT_MRS_URL!, @{$conf->{'provides_info'}}),
#   "Conf has provides_info > project_mrs_url");
ok(grep(m!PROJECT_CREATED_AT!, @{$conf->{'provides_info'}}),
   "Conf has provides_info > project_created_at");
ok(grep(m!PROJECT_REPO_SSH!, @{$conf->{'provides_info'}}),
   "Conf has provides_info > project_repo_ssh");
ok(grep(m!PROJECT_REPO_HTTP!, @{$conf->{'provides_info'}}),
   "Conf has provides_info > project_repo_http");
ok(grep(m!PROJECT_REPO_GIT!, @{$conf->{'provides_info'}}),
   "Conf has provides_info > project_repo_git");

# Check provides_metrics
   
ok(grep(m!PROJECT_ISSUES_OPEN!, map { $conf->{'provides_metrics'}{$_} } keys %{$conf->{'provides_metrics'}}),
   "Conf has provides_metrics > project_issues_open");
ok(grep(m!PROJECT_FORKS!, map { $conf->{'provides_metrics'}{$_} } keys %{$conf->{'provides_metrics'}}),
   "Conf has provides_metrics > project_forks");
ok(grep(m!PROJECT_STARGAZERS!, map { $conf->{'provides_metrics'}{$_} } keys %{$conf->{'provides_metrics'}}),
   "Conf has provides_metrics > project_stargazers");
ok(grep(m!PROJECT_WATCHERS!, map { $conf->{'provides_metrics'}{$_} } keys %{$conf->{'provides_metrics'}}),
   "Conf has provides_metrics > project_watchers");
#   
#ok(grep(m!PROJECT_AUTHORS!, map { $conf->{'provides_metrics'}{$_} } keys %{$conf->{'provides_metrics'}}),
#  "Conf has provides_metrics > project_authors");
#ok(grep(m!PROJECT_AUTHORS_1W!, map { $conf->{'provides_metrics'}{$_} } keys %{$conf->{'provides_metrics'}}),
#  "Conf has provides_metrics > project_authors_1w");
#ok(grep(m!PROJECT_AUTHORS_1M!, map { $conf->{'provides_metrics'}{$_} } keys %{$conf->{'provides_metrics'}}),
#  "Conf has provides_metrics > project_authors_1m");
#ok(grep(m!PROJECT_AUTHORS_1Y!, map { $conf->{'provides_metrics'}{$_} } keys %{$conf->{'provides_metrics'}}),
#  "Conf has provides_metrics > project_authors_1y");
#
#ok(grep(m!PROJECT_COMMITS!, map { $conf->{'provides_metrics'}{$_} } keys %{$conf->{'provides_metrics'}}),
#  "Conf has provides_metrics > project_commits");
#ok(grep(m!PROJECT_COMMITS_1W!, map { $conf->{'provides_metrics'}{$_} } keys %{$conf->{'provides_metrics'}}),
#  "Conf has provides_metrics > project_commits_1w");
#ok(grep(m!PROJECT_COMMITS_1M!, map { $conf->{'provides_metrics'}{$_} } keys %{$conf->{'provides_metrics'}}),
#  "Conf has provides_metrics > project_commits_1m");
#ok(grep(m!PROJECT_COMMITS_1Y!, map { $conf->{'provides_metrics'}{$_} } keys %{$conf->{'provides_metrics'}}),
#  "Conf has provides_metrics > project_commits_1y");
#
#ok(grep(m!PROJECT_COMMITTERS!, map { $conf->{'provides_metrics'}{$_} } keys %{$conf->{'provides_metrics'}}),
#  "Conf has provides_metrics > project_committers");
#ok(grep(m!PROJECT_COMMITTERS_1W!, map { $conf->{'provides_metrics'}{$_} } keys %{$conf->{'provides_metrics'}}),
#  "Conf has provides_metrics > project_committers_1w");
#ok(grep(m!PROJECT_COMMITTERS_1M!, map { $conf->{'provides_metrics'}{$_} } keys %{$conf->{'provides_metrics'}}),
#  "Conf has provides_metrics > project_committers_1m");
#ok(grep(m!PROJECT_COMMITTERS_1Y!, map { $conf->{'provides_metrics'}{$_} } keys %{$conf->{'provides_metrics'}}),
#  "Conf has provides_metrics > project_committers_1y");
#
#ok(grep(m!PROJECT_MRS!, map { $conf->{'provides_metrics'}{$_} } keys %{$conf->{'provides_metrics'}}),
#  "Conf has provides_metrics > project_mrs");
#ok(grep(m!PROJECT_MRS_OPENED!, map { $conf->{'provides_metrics'}{$_} } keys %{$conf->{'provides_metrics'}}),
#  "Conf has provides_metrics > project_mrs_opened");
#ok(grep(m!PROJECT_MRS_OPENED_1W!, map { $conf->{'provides_metrics'}{$_} } keys %{$conf->{'provides_metrics'}}),
#  "Conf has provides_metrics > project_mrs_opened_1w");
#ok(grep(m!PROJECT_MRS_OPENED_1M!, map { $conf->{'provides_metrics'}{$_} } keys %{$conf->{'provides_metrics'}}),
#  "Conf has provides_metrics > project_mrs_opened_1m");
#ok(grep(m!PROJECT_MRS_OPENED_1Y!, map { $conf->{'provides_metrics'}{$_} } keys %{$conf->{'provides_metrics'}}),
#   "Conf has provides_metrics > project_mrs_opened_1y");
#
#ok(grep(m!PROJECT_MRS_OPENED_STILL!, map { $conf->{'provides_metrics'}{$_} } keys %{$conf->{'provides_metrics'}}),
#  "Conf has provides_metrics > project_mrs_opened_still");
#ok(grep(m!PROJECT_MRS_OPENED_STILL_1W!, map { $conf->{'provides_metrics'}{$_} } keys %{$conf->{'provides_metrics'}}),
#  "Conf has provides_metrics > project_mrs_opened_still_1w");
#ok(grep(m!PROJECT_MRS_OPENED_STILL_1M!, map { $conf->{'provides_metrics'}{$_} } keys %{$conf->{'provides_metrics'}}),
#  "Conf has provides_metrics > project_mrs_opened_still_1m");
#ok(grep(m!PROJECT_MRS_OPENED_STILL_1Y!, map { $conf->{'provides_metrics'}{$_} } keys %{$conf->{'provides_metrics'}}),
#  "Conf has provides_metrics > project_mrs_opened_still_1y");
#ok(grep(m!PROJECT_MRS_OPENED_STALED_1M!, map { $conf->{'provides_metrics'}{$_} } keys %{$conf->{'provides_metrics'}}),
#  "Conf has provides_metrics > project_mrs_opened_staled_1m");
#
#ok(grep(m!PROJECT_MRS_CLOSED!, map { $conf->{'provides_metrics'}{$_} } keys %{$conf->{'provides_metrics'}}),
#  "Conf has provides_metrics > project_mrs_closed");
#ok(grep(m!PROJECT_MRS_MERGED!, map { $conf->{'provides_metrics'}{$_} } keys %{$conf->{'provides_metrics'}}),
#  "Conf has provides_metrics > project_mrs_merged");


ok(grep(m!metrics!, @{$conf->{'ability'}}), "Conf has ability > metrics");
ok(grep(m!info!,    @{$conf->{'ability'}}), "Conf has ability > info");
ok(grep(m!figs!,    @{$conf->{'ability'}}) == 0, "Conf has NO ability > figs");
ok(grep(m!data!,    @{$conf->{'ability'}}), "Conf has ability > data");
ok(grep(m!recs!,    @{$conf->{'ability'}}) == 0, "Conf has NO ability > recs");
ok(grep(m!viz!,     @{$conf->{'ability'}}), "Conf has ability > viz");


# Delete files before creating them, so we don't test a previous run.
my @files = (
    "projects/test.github.project/input/test.github.project_github_project.json",
    "projects/test.github.project/input/test.github.project_github_project_contributors.json",
    "projects/test.github.project/input/test.github.project_github_project_events.json",
    "projects/test.github.project/input/test.github.project_github_project_languages.json",
    "projects/test.github.project/input/test.github.project_github_project_tags.json",
    "projects/test.github.project/input/test.github.project_github_project_commits_hourly.json",
    "projects/test.github.project/input/test.github.project_github_project_commits_weekly.json",
    "projects/test.github.project/output/test.github.project_github_project.inc",
    "projects/test.github.project/output/test.github.project_github_project_contributors.csv",
    "projects/test.github.project/output/test.github.project_github_project_languages.csv",
    "projects/test.github.project/output/test.github.project_github_project_tags.csv",
    "projects/test.github.project/output/test.github.project_github_project_commits_hourly.csv",
    "projects/test.github.project/output/test.github.project_github_project_commits_weekly.csv",
    "projects/test.github.project/output/test.github.project_info_github_project.csv",
    "projects/test.github.project/output/test.github.project_metrics_github_project.csv",
    "projects/test.github.project/output/test.github.project_metrics_github_project.json",
    );

unlink( @files );

# Exec plugin

note("Executing the plugin with Crossminer/Crossflow PRIVATE project. ");
my $ret = $plugin->run_plugin(
    "test.github.project",
    { 'github_url' => '',  
      'github_user' => 'crossminer',
      'github_repo' => 'crossflow',
      'github_token' => '' });

my @log = @{$ret->{'log'}}; 
ok(scalar grep(/ERROR/, @log) == 1, "Log returns ERROR for no auth.") or diag explain @log;
sleep(2);

note("Executing the plugin with borisbaldassari/test public project. ");
$ret = $plugin->run_plugin(
    "test.github.project",
    { 'github_url' => '',  
      'github_user' => 'borisbaldassari',
      'github_repo' => 'test',
      'github_token' => '' });

# Test log
@log = @{$ret->{'log'}}; 
ok(scalar(grep(/ERROR/, @log)) == 0, "Log returns no ERROR") or diag explain @log;
ok(grep(m!^\[Plugins::GitHubProject\] Targeting data from .* for project \[borisbaldassari/test\]!, @log),
  "Log returns Retrieving data from project.")
  or diag explain @log;
ok(grep(m!^\[Plugins::GitHubProject\] Retrieving Repository data.!, @log),
  "Log returns Retrieving Repository data.")
  or diag explain @log;
ok(grep(m!^\[Plugins::GitHubProject\] Retrieving Languages data!, @log),
  "Log returns Retrieving Languages data.")
  or diag explain @log;
ok(grep(m!^\[Plugins::GitHubProject\] Retrieving Contributors data.!, @log),
  "Log returns Retrieving Contributors data.")
  or diag explain @log;
ok(grep(m!^\[Plugins::GitHubProject\] Retrieving Tags data.!, @log),
  "Log returns Retrieving Tags data.")
  or diag explain @log;
ok(grep(m!^\[Plugins::GitHubProject\] Retrieving Participation data.!, @log),
  "Log returns Retrieving Participation data.")
  or diag explain @log;
ok(grep(m!^\[Plugins::GitHubProject\] Retrieving Punch Card data.!, @log),
  "Log returns Retrieving Punch Card data.")
  or diag explain @log;
ok(grep(m!^\[Plugins::GitHubProject\] Retrieving Events data.!, @log),
  "Log returns Retrieving Events data.")
  or diag explain @log;
ok(grep(m!^\[Tools::R\] Exec \[Rscript -e .library\(rmarkdown\).!, @log),
  "Log returns R exec.")
  or diag explain @log;
ok(grep(m!^\[Tools::R\] Moved main file!, @log),
  "Log returns R moved main file.")
  or diag explain @log;

# Test metrics
#ok($ret->{'metrics'}{'PROJECT_COMMITS'} =~ /\d+/,
#  "Metric PROJECT_COMMITS is a digit " . $ret->{'metrics'}{'PROJECT_COMMITS'} . ".")
#    or diag explain $ret;
#ok($ret->{'metrics'}{'PROJECT_COMMITS_1W'} =~ /\d+/,
#  "Metric PROJECT_COMMITS_1W is a digit " . $ret->{'metrics'}{'PROJECT_COMMITS_1W'} . ".")
#  or diag explain $ret;
#ok($ret->{'metrics'}{'PROJECT_COMMITS_1M'} =~ /\d+/,
#  "Metric PROJECT_COMMITS_1M is a digit " . $ret->{'metrics'}{'PROJECT_COMMITS_1M'} . ".")
#  or diag explain $ret;
#ok($ret->{'metrics'}{'PROJECT_COMMITS_1Y'} =~ /\d+/,
#  "Metric PROJECT_COMMITS_1Y is a digit " . $ret->{'metrics'}{'PROJECT_COMMITS_1Y'} . ".")
#  or diag explain $ret;

#ok($ret->{'metrics'}{'PROJECT_AUTHORS'} =~ /\d+/,
#  "Metric PROJECT_AUTHORS is a digit " . $ret->{'metrics'}{'PROJECT_AUTHORS'} . ".")
#  or diag explain $ret;
#ok($ret->{'metrics'}{'PROJECT_AUTHORS_1W'} =~ /\d+/,
#  "Metric PROJECT_AUTHORS_1W is a digit " . $ret->{'metrics'}{'PROJECT_AUTHORS_1W'} . ".")
#  or diag explain $ret;
#ok($ret->{'metrics'}{'PROJECT_AUTHORS_1M'} =~ /\d+/,
#  "Metric PROJECT_AUTHORS_1M is a digit " . $ret->{'metrics'}{'PROJECT_AUTHORS_1M'} . ".")
#  or diag explain $ret;
#ok($ret->{'metrics'}{'PROJECT_AUTHORS_1Y'} =~ /\d+/,
#  "Metric PROJECT_AUTHORS_1Y is a digit " . $ret->{'metrics'}{'PROJECT_AUTHORS_1Y'} . ".")
#    or diag explain $ret;

#ok($ret->{'metrics'}{'PROJECT_COMMITTERS'} =~ /\d+/,
#  "Metric PROJECT_COMMITTERS is a digit " . $ret->{'metrics'}{'PROJECT_COMMITTERS'} . ".")
#  or diag explain $ret;
#ok($ret->{'metrics'}{'PROJECT_COMMITTERS_1W'} =~ /\d+/,
#  "Metric PROJECT_COMMITTERS_1W is a digit " . $ret->{'metrics'}{'PROJECT_COMMITTERS_1W'} . ".")
#  or diag explain $ret;
#ok($ret->{'metrics'}{'PROJECT_COMMITTERS_1M'} =~ /\d+/,
#  "Metric PROJECT_COMMITTERS_1M is a digit " . $ret->{'metrics'}{'PROJECT_COMMITTERS_1M'} . ".")
#    or diag explain $ret;
#ok($ret->{'metrics'}{'PROJECT_COMMITTERS_1Y'} =~ /\d+/,
#  "Metric PROJECT_COMMITTERS_1Y is a digit " . $ret->{'metrics'}{'PROJECT_COMMITTERS_1Y'} . ".")
#    or diag explain $ret;


#ok($ret->{'metrics'}{'PROJECT_MRS'} =~ /\d+/,
#  "Metric PROJECT_MRS is a digit " . $ret->{'metrics'}{'PROJECT_MRS'} . ".")
#    or diag explain $ret;
#ok($ret->{'metrics'}{'PROJECT_MRS_CLOSED'} =~ /\d+/,
#  "Metric PROJECT_MRS_CLOSED is a digit " . $ret->{'metrics'}{'PROJECT_MRS_CLOSED'} . ".")
#    or diag explain $ret;
#ok($ret->{'metrics'}{'PROJECT_MRS_MERGED'} =~ /\d+/,
#  "Metric PROJECT_MRS_MERGED is a digit " . $ret->{'metrics'}{'PROJECT_MRS_MERGED'} . ".")
#  or diag explain $ret;
#ok($ret->{'metrics'}{'PROJECT_MRS_OPENED'} =~ /\d+/,
#  "Metric PROJECT_MRS_OPENED is a digit " . $ret->{'metrics'}{'PROJECT_MRS_OPENED'} . ".")
#  or diag explain $ret;
#ok($ret->{'metrics'}{'PROJECT_MRS_OPENED_1W'} =~ /\d+/,
#  "Metric PROJECT_MRS_OPENED_1W is a digit " . $ret->{'metrics'}{'PROJECT_MRS_OPENED_1W'} . ".")
#  or diag explain $ret;
#ok($ret->{'metrics'}{'PROJECT_MRS_OPENED_1M'} =~ /\d+/,
#  "Metric PROJECT_MRS_OPENED_1M is a digit " . $ret->{'metrics'}{'PROJECT_MRS_OPENED_1M'} . ".")
#    or diag explain $ret;
#ok($ret->{'metrics'}{'PROJECT_MRS_OPENED_1Y'} =~ /\d+/,
#  "Metric PROJECT_MRS_OPENED_1Y is a digit " . $ret->{'metrics'}{'PROJECT_MRS_OPENED_1Y'} . ".")
#  or diag explain $ret;
#
#ok($ret->{'metrics'}{'PROJECT_MRS_OPENED_STILL_1W'} =~ /\d+/,
#  "Metric PROJECT_MRS_OPENED_STILL_1W is a digit " . $ret->{'metrics'}{'PROJECT_MRS_OPENED_STILL_1W'} . ".")
#  or diag explain $ret;
#ok($ret->{'metrics'}{'PROJECT_MRS_OPENED_STILL_1M'} =~ /\d+/,
#  "Metric PROJECT_MRS_OPENED_STILL_1M is a digit " . $ret->{'metrics'}{'PROJECT_MRS_OPENED_STILL_1M'} . ".")
#  or diag explain $ret;
#ok($ret->{'metrics'}{'PROJECT_MRS_OPENED_STILL_1Y'} =~ /\d+/,
#  "Metric PROJECT_MRS_OPENED_STILL_1Y is a digit " . $ret->{'metrics'}{'PROJECT_MRS_OPENED_STILL_1Y'} . ".")
#    or diag explain $ret;
#
#ok($ret->{'metrics'}{'PROJECT_MRS_OPENED_STALED_1M'} =~ /\d+/,
#  "Metric PROJECT_MRS_OPENED_STALED_1M is a digit " . $ret->{'metrics'}{'PROJECT_MRS_OPENED_STALED_1M'} . ".")
#    or diag explain $ret;

# Test info results
#ok($ret->{'info'}{'PROJECT_CI_ENABLED'} == 1,
#  "Info PROJECT_CI_ENABLED is 1.")
#  or diag explain $ret;
#ok($ret->{'info'}{'PROJECT_CI_URL'} =~ m!https://www.github.com/bbaldassari/Alambic/pipelines!,
#  "Info PROJECT_CI_URL is correct.")
#  or diag explain $ret;
ok($ret->{'info'}{'PROJECT_ID'} =~ m!313579412!,
  "Info PROJECT_ID is correct.")
  or diag explain $ret;
ok($ret->{'info'}{'PROJECT_URL'} =~ m!https://github.com/borisbaldassari/test!,
  "Info PROJECT_URL is correct.")
  or diag explain $ret;
ok($ret->{'info'}{'PROJECT_WEB_ENABLED'},
  "Info PROJECT_WEB_ENABLED is enabled.")
  or diag explain $ret;
ok($ret->{'info'}{'PROJECT_ISSUES_ENABLED'},
  "Info PROJECT_ISSUES_ENABLED is 1.")
  or diag explain $ret;
ok($ret->{'info'}{'PROJECT_ISSUES_URL'} =~ m!https://github.com/borisbaldassari/test/issues!,
  "Info PROJECT_ISSUES_URL is correct.")
  or diag explain $ret;
ok($ret->{'info'}{'PROJECT_WIKI_ENABLED'},
  "Info PROJECT_WIKI_ENABLED is 1.")
  or diag explain $ret; 
ok($ret->{'info'}{'PROJECT_WIKI_URL'} =~ m!https://github.com/borisbaldassari/test/wiki!,
  "Info PROJECT_WIKI_URL is correct.")
  or diag explain $ret;
ok($ret->{'info'}{'PROJECT_COMMITS_URL'} =~ m!https://github.com/borisbaldassari/test/commits!,
  "Info PROJECT_COMMITS_URL is correct.")
  or diag explain $ret;
ok($ret->{'info'}{'PROJECT_CREATED_AT'} =~ m!2020-11-17T10:10:40Z!,
  "Info PROJECT_CREATED_AT is correct.")
  or diag explain $ret;
ok($ret->{'info'}{'PROJECT_LAST_ACTIVITY_AT'} =~ m!2020-11-17T11:50:11Z!,
  "Info PROJECT_LAST_ACTIVITY_AT is correct.")
  or diag explain $ret;
#ok($ret->{'info'}{'PROJECT_MRS_ENABLED'} == 1,
#  "Info PROJECT_MRS_ENABLED is 1.")
#  or diag explain $ret;
#ok($ret->{'info'}{'PROJECT_MRS_URL'} =~ m!https://www.github.com/bbaldassari/Alambic/merge_requests!,
#  "Info PROJECT_MRS_URL is correct.")
#  or diag explain $ret;
ok($ret->{'info'}{'PROJECT_OWNER_ID'} =~ m!5849071!,
  "Info PROJECT_OWNER_ID is correct.")
  or diag explain $ret;
ok($ret->{'info'}{'PROJECT_OWNER_NAME'} =~ m!borisbaldassari!,
  "Info PROJECT_OWNER_NAME is correct.")
  or diag explain $ret;
ok($ret->{'info'}{'PROJECT_REPO_HTTP'} =~ m!https://github.com/borisbaldassari/test.git!,
  "Info PROJECT_REPO_HTTP is correct.")
  or diag explain $ret;
ok($ret->{'info'}{'PROJECT_REPO_SSH'} =~ m!git\@github.com:borisbaldassari/test.git!,
  "Info PROJECT_REPO_SSH is correct.")
  or diag explain $ret;
ok($ret->{'info'}{'PROJECT_REPO_GIT'} =~ m!git://github.com/borisbaldassari/test.git!,
  "Info PROJECT_REPO_GIT is correct.")
  or diag explain $ret;
#ok($ret->{'info'}{'PROJECT_VISIBILITY'} =~ m!public!,
#  "Info PROJECT_VISIBILITY is correct.")
#  or diag explain $ret;
#ok($ret->{'info'}{'PROJECT_WEB'} =~ m!https://github.com/bbaldassari/Alambic!,
#  "Info PROJECT_WEB is correct.")
#  or diag explain $ret;

# Checking input/* and output/* files
foreach my $f (@files) {
    ok( -e $f, "Check that file $f exists." );
}

done_testing();


