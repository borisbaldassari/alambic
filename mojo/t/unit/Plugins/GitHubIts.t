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

BEGIN { use_ok('Alambic::Plugins::GitHubIts'); }

my $plugin = Alambic::Plugins::GitHubIts->new();
isa_ok($plugin, 'Alambic::Plugins::GitHubIts');

note("Checking the plugin parameters. ");
my $conf = $plugin->get_conf();

# Check params

ok(grep(m!github_url!, keys %{$conf->{'params'}}), "Conf has params > github_url");
ok(grep(m!github_user!, keys %{$conf->{'params'}}), "Conf has params > github_user");
ok(grep(m!github_repo!, keys %{$conf->{'params'}}), "Conf has params > github_repo");
ok(grep(m!github_token!, keys %{$conf->{'params'}}), "Conf has params > github_token");

# Check provides_data
ok(grep(m!import_github_issues.json!, keys %{$conf->{'provides_data'}}),
   "Conf has provides_data > import_github_issues.json");
ok(grep(m!github_issues.csv!, keys %{$conf->{'provides_data'}}),
   "Conf has provides_data > github_issues.csv");
ok(grep(m!github_issues_open.csv!, keys %{$conf->{'provides_data'}}),
   "Conf has provides_data > github_issues_open.csv");

# Check provides_info

ok(grep(m!ITS_URL!, @{$conf->{'provides_info'}}),
   "Conf has provides_info > its_url");

# Check provides_metrics
   
ok(grep(m!ITS_ISSUES!, map { $conf->{'provides_metrics'}{$_} } keys %{$conf->{'provides_metrics'}}),
   "Conf has provides_metrics > its_issues");
ok(grep(m!ITS_ISSUES_OPEN!, map { $conf->{'provides_metrics'}{$_} } keys %{$conf->{'provides_metrics'}}),
   "Conf has provides_metrics > its_issues_open");
ok(grep(m!ITS_AUTHORS!, map { $conf->{'provides_metrics'}{$_} } keys %{$conf->{'provides_metrics'}}),
   "Conf has provides_metrics > its_authors");
ok(grep(m!ITS_AUTHORS_1W!, map { $conf->{'provides_metrics'}{$_} } keys %{$conf->{'provides_metrics'}}),
   "Conf has provides_metrics > its_authors_1w");
ok(grep(m!ITS_AUTHORS_1M!, map { $conf->{'provides_metrics'}{$_} } keys %{$conf->{'provides_metrics'}}),
   "Conf has provides_metrics > its_authors_1m");
ok(grep(m!ITS_AUTHORS_1Y!, map { $conf->{'provides_metrics'}{$_} } keys %{$conf->{'provides_metrics'}}),
   "Conf has provides_metrics > its_authors_1y");
ok(grep(m!ITS_CREATED_1W!, map { $conf->{'provides_metrics'}{$_} } keys %{$conf->{'provides_metrics'}}),
   "Conf has provides_metrics > its_CREATED_1w");
ok(grep(m!ITS_CREATED_1M!, map { $conf->{'provides_metrics'}{$_} } keys %{$conf->{'provides_metrics'}}),
   "Conf has provides_metrics > its_CREATED_1m");
ok(grep(m!ITS_CREATED_1Y!, map { $conf->{'provides_metrics'}{$_} } keys %{$conf->{'provides_metrics'}}),
   "Conf has provides_metrics > its_CREATED_1y");
ok(grep(m!ITS_UPDATED_1W!, map { $conf->{'provides_metrics'}{$_} } keys %{$conf->{'provides_metrics'}}),
   "Conf has provides_metrics > its_UPDATED_1w");
ok(grep(m!ITS_UPDATED_1M!, map { $conf->{'provides_metrics'}{$_} } keys %{$conf->{'provides_metrics'}}),
   "Conf has provides_metrics > its_UPDATED_1m");
ok(grep(m!ITS_UPDATED_1Y!, map { $conf->{'provides_metrics'}{$_} } keys %{$conf->{'provides_metrics'}}),
   "Conf has provides_metrics > its_UPDATED_1y");


ok(grep(m!metrics!, @{$conf->{'ability'}}), "Conf has ability > metrics");
ok(grep(m!info!,    @{$conf->{'ability'}}), "Conf has ability > info");
ok(grep(m!figs!,    @{$conf->{'ability'}}) == 0, "Conf has NO ability > figs");
ok(grep(m!data!,    @{$conf->{'ability'}}), "Conf has ability > data");
ok(grep(m!recs!,    @{$conf->{'ability'}}) == 0, "Conf has NO ability > recs");
ok(grep(m!viz!,     @{$conf->{'ability'}}), "Conf has ability > viz");

# Exec plugin

my $in_github_user      = "borisbaldassari";
my $in_github_repo      = "test";
my $in_github_token   = "f2a70262b45afff6abf513f2633b4b326cc23b8f";


# Delete files before creating them, so we don't test a previous run.
my @files = (
    "projects/test.github.its/input/test.github.its_import_github_issues.json",
    "projects/test.github.its/output/test.github.its_info_github_issues.inc",
    "projects/test.github.its/output/test.github.its_github_issues_authors_pie.html",
    "projects/test.github.its/output/test.github.its_github_issues_open.csv",
    "projects/test.github.its/output/test.github.its_info_github_issues.csv",
    "projects/test.github.its/output/test.github.its_metrics_github_issues.csv",
    "projects/test.github.its/output/test.github.its_metrics_github_issues.json",
    );

unlink( @files );

note("Executing the plugin with borisbaldassari/test project. ");
my $ret = $plugin->run_plugin(
    "test.github.its",
    { 'github_url' => '', 
      'github_user' => $in_github_user,
      'github_repo' => $in_github_repo,
      'github_token' => $in_github_token });

# Test log
my @log = @{$ret->{'log'}}; 
ok(grep(!/^ERROR/, @log), "Log returns no ERROR") or diag explain @log;
ok(grep(m!^\[Plugins::GitHubIts\] Targeting data from .* for project \[borisbaldassari/test\]!, @log),
  "Log returns Retrieving data from project.")
  or diag explain @log;
ok(grep(m!^\[Plugins::GitHubIts\] Retrieving Issues data.!, @log),
  "Log returns Retrieving Repository data.")
  or diag explain @log;
ok(grep(m!^\[Tools::R\] Exec \[Rscript -e .library\(rmarkdown\).!, @log),
  "Log returns R exec.")
  or diag explain @log;
ok(grep(m!^\[Tools::R\] Moved main file!, @log),
  "Log returns R moved main file.")
  or diag explain @log;

# Test metrics
ok($ret->{'metrics'}{'ITS_ISSUES_ALL'} == 4,
  "Metric ITS_ISSUES is 4 == " . $ret->{'metrics'}{'ITS_ISSUES_ALL'} . ".")
  or diag explain $ret;
ok($ret->{'metrics'}{'ITS_ISSUES_OPEN'} == 3,
  "Metric ITS_ISSUES_OPEN is 3 == " . $ret->{'metrics'}{'ITS_ISSUES_OPEN'} . ".")
  or diag explain $ret;
ok($ret->{'metrics'}{'ITS_AUTHORS'} =~ /2/,
  "Metric ITS_AUTHORS is 2 == " . $ret->{'metrics'}{'ITS_AUTHORS'} . ".")
  or diag explain $ret; 
ok($ret->{'metrics'}{'ITS_AUTHORS_1W'} =~ /\d+/,
  "Metric ITS_AUTHORS_1W is a digit " . $ret->{'metrics'}{'ITS_AUTHORS_1W'} . ".")
  or diag explain $ret; 
ok($ret->{'metrics'}{'ITS_AUTHORS_1M'} =~ /\d+/,
  "Metric ITS_AUTHORS_1M is a digit " . $ret->{'metrics'}{'ITS_AUTHORS_1M'} . ".")
  or diag explain $ret; 
ok($ret->{'metrics'}{'ITS_AUTHORS_1Y'} =~ /\d+/,
  "Metric ITS_AUTHORS_1Y is a digit " . $ret->{'metrics'}{'ITS_AUTHORS_1Y'} . ".")
  or diag explain $ret; 
ok($ret->{'metrics'}{'ITS_CREATED_1W'} =~ /\d+/,
  "Metric ITS_CREATED_1W is a digit " . $ret->{'metrics'}{'ITS_CREATED_1W'} . ".")
  or diag explain $ret; 
ok($ret->{'metrics'}{'ITS_CREATED_1M'} =~ /\d+/,
  "Metric ITS_CREATED_1M is a digit " . $ret->{'metrics'}{'ITS_CREATED_1M'} . ".")
  or diag explain $ret; 
ok($ret->{'metrics'}{'ITS_CREATED_1Y'} =~ /\d+/,
  "Metric ITS_CREATED_1Y is a digit " . $ret->{'metrics'}{'ITS_CREATED_1Y'} . ".")
  or diag explain $ret; 
ok($ret->{'metrics'}{'ITS_UPDATED_1W'} =~ /\d+/,
  "Metric ITS_UPDATED_1W is a digit " . $ret->{'metrics'}{'ITS_UPDATED_1W'} . ".")
  or diag explain $ret; 
ok($ret->{'metrics'}{'ITS_UPDATED_1M'} =~ /\d+/,
  "Metric ITS_UPDATED_1M is a digit " . $ret->{'metrics'}{'ITS_UPDATED_1M'} . ".")
  or diag explain $ret; 
ok($ret->{'metrics'}{'ITS_UPDATED_1Y'} =~ /\d+/,
  "Metric ITS_UPDATED_1Y is a digit " . $ret->{'metrics'}{'ITS_UPDATED_1Y'} . ".")
  or diag explain $ret; 

# Test info results
ok($ret->{'info'}{'ITS_URL'} =~ m!^http!,
  "Info ITS_URL is correct.")
  or diag explain $ret;

# Checking input/* and output/* files
foreach my $f (@files) {
    ok( -e $f, "Check that file $f exists." );
}

done_testing();


