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

# Note:
# At the time of writing, there is no publicly available SonarQube 6.7 instance.
# So we use a 4.5 instance but don't test the new features (metrics namely).
# This should be changed when a 6.7 public instance is found.

use strict;
use warnings;

use Test::More;
use Mojo::JSON qw( decode_json);
use Data::Dumper;

BEGIN { use_ok('Alambic::Plugins::SonarQube67'); }

my $plugin = Alambic::Plugins::SonarQube67->new();
isa_ok($plugin, 'Alambic::Plugins::SonarQube67');

note("Checking the plugin parameters. ");
my $conf = $plugin->get_conf();

ok(grep(m!sonarqube_violations_bar.svg!, keys %{$conf->{'provides_figs'}}),
  "Conf has provides_figs > sonarqube_violations_bar");
ok(grep(m!sonarqube_violations_pie.html!, keys %{$conf->{'provides_figs'}}),
  "Conf has provides_figs > sonarqube_violations_pie");
ok(grep(m!sonarqube_summary.html!, keys %{$conf->{'provides_figs'}}),
  "Conf has provides_figs > sonarqube_summary");
ok(grep(m!sonarqube_violations.html!, keys %{$conf->{'provides_figs'}}),
  "Conf has provides_figs > sonarqube_violations");

ok(grep(m!public_api!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > public_api");
ok(grep(m!files!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > files");
ok(grep(m!function_complexity!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > function_complexity");
ok(grep(m!comment_lines!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > comment_lines");
ok(grep(m!ncloc!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > ncloc");
ok(grep(m!coverage!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > coverage");
ok(grep(m!comment_lines_density!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > comment_lines_density");
ok(grep(m!functions!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > functions");
ok(grep(m!file_complexity!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > file_complexity");
ok(grep(m!public_documented_api_density!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > public_documented_api_density");

ok(grep(m!metrics!, @{$conf->{'ability'}}), "Conf has ability > metrics");
ok(grep(m!figs!,    @{$conf->{'ability'}}), "Conf has ability > figs");
ok(grep(m!data!,    @{$conf->{'ability'}}), "Conf has ability > data");
ok(grep(m!info!,    @{$conf->{'ability'}}), "Conf has ability > info");
ok(grep(m!viz!,     @{$conf->{'ability'}}), "Conf has ability > viz");

ok(grep(m!sonar_project!, keys %{$conf->{'params'}}),
  "Conf has params > sonar_project");
ok(grep(m!sonar_project!, keys %{$conf->{'params'}}),
  "Conf has params > sonar_url");

ok(grep(m!sonarqube67.html!, keys %{$conf->{'provides_viz'}}),
  "Conf has provides_viz > sonarqube67");

my $in_sonar_url     = "https://sonar.eclipse.org";
my $in_sonar_project = "org.eclipse.sirius:sirius-parent";

# Delete files before creating them, so we don't test a previous run.
unlink (
    "projects/test.project/input/test.project_import_sq_issues_blocker.json",
    "projects/test.project/input/test.project_import_sq_issues_critical.json",
    "projects/test.project/input/test.project_import_sq_issues_major.json",
    "projects/test.project/output/test.project_sq_issues_blocker.csv",
    "projects/test.project/output/test.project_sq_issues_critical.csv",
    "projects/test.project/output/test.project_sq_issues_major.csv",
    "projects/test.project/output/test.project_sq_metrics.csv",
    );

note("Executing the plugin with Sirius project. ");
my $ret = $plugin->run_plugin("test.project",
  {'sonar_url' => $in_sonar_url, 'sonar_project' => $in_sonar_project});

# Test log
my @log = @{$ret->{'log'}};
ok(grep(!/^ERROR/, @log), "Log returns no ERROR") or diag explain @log;
ok(grep(m!^\[Plugins::SonarQube67\] Get issues from \[http!, @log),
  "Log returns get issues.")
  or diag explain @log;
ok(grep(m!^\[Plugins::SonarQube67\] Got \[\d+\] blocker issues.!, @log),
  "Log returns got blocker issues.")
  or diag explain @log;
ok(grep(m!^\[Plugins::SonarQube67\] Got \[\d+\] critical issues.!, @log),
  "Log returns got critical issues.")
  or diag explain @log;
ok(grep(m!^\[Plugins::SonarQube67\] Got \[\d+\] major issues.!, @log),
  "Log returns got major issues.")
  or diag explain @log;
ok(grep(m!^\[Plugins::SonarQube67\] Got \[35\] rules.!, @log),
  "Log returns 35 rules.")
  or diag explain @log;
ok(grep(m!^\[Plugins::SonarQube67\] Get resources from \[http!, @log),
  "Log returns get resources.")
  or diag explain @log;

# Checking output/*_sq_ files
ok(
  -e "projects/test.project/input/test.project_import_sq_issues_blocker.json",
  "Check that file test.project_import_sq_issues_blocker.json exists."
);
ok(
  -e "projects/test.project/input/test.project_import_sq_issues_critical.json",
  "Check that file test.project_import_sq_issues_critical.json exists."
);
ok(
  -e "projects/test.project/input/test.project_import_sq_issues_major.json",
  "Check that file test.project_import_sq_issues_major.json exists."
);
ok(
  -e "projects/test.project/output/test.project_sq_issues_blocker.csv",
  "Check that file test.project_sq_issues_blocker.csv exists."
);
ok(
  -e "projects/test.project/output/test.project_sq_issues_critical.csv",
  "Check that file test.project_sq_issues_critical.csv exists."
);
ok(
  -e "projects/test.project/output/test.project_sq_issues_major.csv",
  "Check that file test.project_sq_issues_major.csv exists."
);

# Checking sq_metrics file
ok(
  -e "projects/test.project/output/test.project_sq_metrics.csv",
  "Check that file test.project_sq_metrics.csv exists."
);

done_testing();
