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

BEGIN { use_ok('Alambic::Plugins::Bugzilla'); }

my $plugin = Alambic::Plugins::Bugzilla->new();
isa_ok($plugin, 'Alambic::Plugins::Bugzilla');

note("Checking the plugin parameters. ");
my $conf = $plugin->get_conf();

ok(grep(m!bugzilla_url!, keys %{$conf->{'params'}}), "Conf has params > bugzilla_url");
ok(grep(m!bugzilla_project!, keys %{$conf->{'params'}}),
  "Conf has params > bugzilla_project");
ok(grep(m!proxy!, keys %{$conf->{'params'}}),
  "Conf has params > proxy");

ok(grep(m!info!,    @{$conf->{'ability'}}), "Conf has ability > info");
ok(grep(m!metrics!, @{$conf->{'ability'}}), "Conf has ability > metrics");
ok(grep(m!data!,    @{$conf->{'ability'}}), "Conf has ability > data");
ok(grep(m!recs!,    @{$conf->{'ability'}}), "Conf has ability > recs");
ok(grep(m!figs!,    @{$conf->{'ability'}}), "Conf has ability > figs");
ok(grep(m!viz!,     @{$conf->{'ability'}}), "Conf has ability > viz");
ok(grep(m!users!,   @{$conf->{'ability'}}), "Conf has ability > users");

ok(grep(m!BZ_URL!, @{$conf->{'provides_info'}}),
  "Conf has provides_info > BZ_URL");

ok(grep(m!import_bugzilla.json!, keys %{$conf->{'provides_data'}}),
  "Conf has provides_data > import_bugzilla.json");
ok(grep(m!metrics_bugzilla.csv!, keys %{$conf->{'provides_data'}}),
  "Conf has provides_data > metrics_bugzilla.csv");
ok(grep(m!metrics_bugzilla.json!, keys %{$conf->{'provides_data'}}),
  "Conf has provides_data > metrics_bugzilla.json");
ok(grep(m!bugzilla_evol.csv!, keys %{$conf->{'provides_data'}}),
  "Conf has provides_data > bugzilla_evol.csv");
ok(grep(m!bugzilla_issues.csv!, keys %{$conf->{'provides_data'}}),
  "Conf has provides_data > bugzilla_issues.csv");
ok(grep(m!bugzilla_issues_open.csv!, keys %{$conf->{'provides_data'}}),
  "Conf has provides_data > bugzilla_issues_open.csv");
ok(grep(m!bugzilla_issues_open_unassigned.csv!, keys %{$conf->{'provides_data'}}),
  "Conf has provides_data > bugzilla_issues_open_unassigned.csv");
ok(grep(m!bugzilla_components.csv!, keys %{$conf->{'provides_data'}}),
  "Conf has provides_data > bugzilla_components.csv");
ok(grep(m!bugzilla_milestones.csv!, keys %{$conf->{'provides_data'}}),
  "Conf has provides_data > bugzilla_milestones.csv");
ok(grep(m!bugzilla_versions.csv!, keys %{$conf->{'provides_data'}}),
  "Conf has provides_data > bugzilla_versions.csv");


ok(grep(m!BZ_VOL!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > BZ_VOL");
ok(grep(m!BZ_AUTHORS!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > BZ_AUTHORS");
ok(grep(m!BZ_AUTHORS_1M!, keys %{$conf->{'provides_metrics'}}),
   "Conf has provides_metrics > BZ_AUTHORS_1M");
ok(grep(m!BZ_AUTHORS_1W!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > BZ_AUTHORS_1W");
ok(grep(m!BZ_AUTHORS_1Y!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > BZ_AUTHORS_1Y");
ok(grep(m!BZ_CREATED_1W!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > BZ_CREATED_1W");
ok(grep(m!BZ_UPDATED_1W!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > BZ_UPDATED_1W");
ok(grep(m!BZ_OPEN!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > BZ_OPEN");
ok(grep(m!BZ_OPEN_UNASSIGNED!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > BZ_OPEN_UNASSIGNED");

ok(grep(m!bugzilla_summary.html!, keys %{$conf->{'provides_figs'}}),
  "Conf has provides_figs > bugzilla_summary.html");

# Remove file before trying to create them.
unlink (
    "projects/test.bugzilla/input/test.bugzilla_import.json",
    "projects/test.bugzilla/output/test.bugzilla_metrics.bugzilla.csv",
    "projects/test.bugzilla/output/test.bugzilla_metrics.bugzilla.json",
    "projects/test.bugzilla/output/test.bugzilla_issues.csv",
    "projects/test.bugzilla/output/test.bugzilla_issues_open.csv",
    "projects/test.bugzilla/output/test.bugzilla_issues_open_unassigned.csv",
    "projects/test.bugzilla/output/test.bugzilla_components.csv",
    "projects/test.bugzilla/output/test.bugzilla_milestones.csv",
    "projects/test.bugzilla/output/test.bugzilla_versions.csv",
    );

note("Executing the plugin with acceleo project. ");
my $ret = $plugin->run_plugin(
  "test.bugzilla",
  {
    'bugzilla_url'         => 'https://bugs.eclipse.org/bugs',
    'bugzilla_project'     => 'acceleo',
  }
);

ok(
  grep(m!\[Plugins::Bugzilla\] Using URL \[https://bugs.eclipse.org/bugs/rest/bug!,
    @{$ret->{'log'}}),
  "Ret has log > using url."
) or print Dumper( $ret->{'log'} );
ok(grep(m!\[Plugins::Bugzilla\] Found \d+ issues.!, @{$ret->{'log'}}),
  "Ret has log > Found xxx issues.");
ok(grep(m!\[Plugins::Bugzilla\] Writing user events file!, @{$ret->{'log'}}),
  "Ret has log > Writing user events file.");
#ok(grep(/^\[Tools::R\] Exec \[Rsc.*bugzilla_its.Rmd/, @{$ret->{'log'}}) == 1,
#  "Checking if log contains bugzilla_its.Rmd R code exec.")
#  or diag explain $ret;
#ok(
#  grep(/^\[Tools::R\] Exec \[Rsc.*bugzilla_evol_authors.rmd/, @{$ret->{'log'}})
#    == 1,
#  "Checking if log contains bugzilla_evol_authors.rmd R code exec."
#) or diag explain $ret;
#ok(
#  grep(/^\[Tools::R\] Exec \[Rsc.*bugzilla_evol_created.rmd/, @{$ret->{'log'}})
#    == 1,
#  "Checking if log contains bugzilla_evol_created.rmd R code exec."
#) or diag explain $ret;
#ok(grep(/^\[Tools::R\] Exec \[Rsc.*bugzilla_summary.rmd/, @{$ret->{'log'}}) == 1,
#  "Checking if log contains bugzilla_summary.rmd R code exec.")
#  or diag explain $ret;

ok($ret->{'metrics'}{'BZ_VOL'} =~ /^\d+$/, "BZ_VOL is a digit.")
  or print Dumper($ret);
ok($ret->{'metrics'}{'BZ_OPEN'} =~ /^\d+$/, "BZ_OPEN is a digit.")
  or diag explain $ret;
ok($ret->{'metrics'}{'BZ_OPEN_PERCENT'} =~ /^\d\d?$/,
  "BZ_OPEN_PERCENT is a digit.")
  or diag explain $ret;
ok($ret->{'metrics'}{'BZ_OPEN_UNASSIGNED'} =~ /^\d+$/,
  "BZ_OPEN_UNASSIGNED is a digit.")
  or diag explain $ret;
ok($ret->{'metrics'}{'BZ_CREATED_1M'} =~ /^\d+$/,
  "BZ_CREATED_1M is a digit.")
  or diag explain $ret;
ok($ret->{'metrics'}{'BZ_CREATED_1Y'} =~ /^\d+$/,
  "BZ_CREATED_1Y is a digit.")
  or diag explain $ret;
ok($ret->{'metrics'}{'BZ_CREATED_1W'} =~ /^\d+$/,
  "BZ_CREATED_1W is a digit.")
  or diag explain $ret;
ok($ret->{'metrics'}{'BZ_UPDATED_1M'} =~ /^\d+$/,
  "BZ_UPDATED_1M is a digit.")
  or diag explain $ret;
ok($ret->{'metrics'}{'BZ_UPDATED_1W'} =~ /^\d+$/,
  "BZ_UPDATED_1W is a digit.")
  or diag explain $ret;
ok($ret->{'metrics'}{'BZ_UPDATED_1Y'} =~ /^\d+$/,
  "BZ_UPDATED_1Y is a digit.")
  or diag explain $ret;
ok($ret->{'metrics'}{'BZ_AUTHORS_1W'} =~ /^\d+$/,
  "BZ_AUTHORS_1W is a digit.")
  or diag explain $ret;
ok($ret->{'metrics'}{'BZ_AUTHORS_1M'} =~ /^\d+$/,
  "BZ_AUTHORS_1M is a digit.")
  or diag explain $ret;
ok($ret->{'metrics'}{'BZ_AUTHORS_1Y'} =~ /^\d+$/,
  "BZ_AUTHORS_1Y is a digit.")
  or diag explain $ret;
ok($ret->{'metrics'}{'BZ_AUTHORS'} =~ /^\d+$/, "BZ_AUTHORS is a digit.")
  or diag explain $ret;


#ok(scalar(@{$ret->{'recs'}}) == 1, "Ret has 1 rec.");
#ok($ret->{'recs'}[0]{'rid'} eq "JIRA_LATE_ISSUES",
#  "Ret has rec > JIRA_LATE_ISSUE.");

ok($ret->{'info'}{'BZ_URL'} eq 'https://bugs.eclipse.org/bugs//buglist.cgi?product=acceleo',
  "Ret has correct info BZ_URL.") or print Dumper($ret);


note("Check that files have been created. ");
ok(-e "projects/test.bugzilla/input/test.bugzilla_import_bugzilla.json",
  "Check that file import_bugzilla.json exists.");

ok(-e "projects/test.bugzilla/output/test.bugzilla_metrics_bugzilla.csv",
  "Check that file metrics_bugzilla.csv exists.");
ok(-e "projects/test.bugzilla/output/test.bugzilla_metrics_bugzilla.json",
  "Check that file metrics_bugzilla.json exists.");

ok(-e "projects/test.bugzilla/output/test.bugzilla_bugzilla_evol.csv",
  "Check that file bugzilla_evol.csv exists.");
ok(-e "projects/test.bugzilla/output/test.bugzilla_bugzilla_issues.csv",
  "Check that file bugzilla_issues.csv exists.");
ok(-e "projects/test.bugzilla/output/test.bugzilla_bugzilla_issues_open.csv",
  "Check that file bugzilla_issues_open.csv exists.");
ok(-e "projects/test.bugzilla/output/test.bugzilla_bugzilla_issues_open_unassigned.csv",
  "Check that file bugzilla_issues_open_unassigned.csv exists.");

ok(-e "projects/test.bugzilla/output/test.bugzilla_bugzilla_components.csv",
  "Check that file bugzilla_components.csv exists.");
ok(-e "projects/test.bugzilla/output/test.bugzilla_bugzilla_milestones.csv",
  "Check that file bugzilla_milestones.csv exists.");
ok(-e "projects/test.bugzilla/output/test.bugzilla_bugzilla_versions.csv",
  "Check that file bugzilla_versions.csv exists.");

#ok(-e "projects/test.bugzilla/output/test.bugzilla_bugzilla_summary.html",
#  "Check that file bugzilla_summary.html exists.");
#ok(-e "projects/test.bugzilla/output/test.bugzilla_bugzilla_its.inc",
#  "Check that file bugzilla_its.inc exists.");

# ok(-e "projects/test.bugzilla/output/test.bugzilla_bugzilla_evol_authors.html",
#   "Check that file bugzilla_evol_authors.html exists.");
# ok(-e "projects/test.bugzilla/output/test.bugzilla_bugzilla_evol_authors.svg",
#   "Check that file bugzilla_evol_authors.svg exists.");
# ok(-e "projects/test.bugzilla/output/test.bugzilla_bugzilla_evol_authors.png",
#   "Check that file bugzilla_evol_authors.png exists.");

# ok(-e "projects/test.bugzilla/output/test.bugzilla_bugzilla_evol_created.html",
#   "Check that file bugzilla_evol_created.html exists.");
# ok(-e "projects/test.bugzilla/output/test.bugzilla_bugzilla_evol_created.svg",
#   "Check that file bugzilla_evol_created.svg exists.");
# ok(-e "projects/test.bugzilla/output/test.bugzilla_bugzilla_evol_created.png",
#   "Check that file bugzilla_evol_created.png exists.");

done_testing();

