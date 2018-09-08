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


ok(grep(m!ITS_ISSUES_ALL!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > ITS_ISSUES_ALL");
ok(grep(m!ITS_AUTHORS!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > ITS_AUTHORS");
ok(grep(m!ITS_AUTHORS_1M!, keys %{$conf->{'provides_metrics'}}),
   "Conf has provides_metrics > ITS_AUTHORS_1M");
ok(grep(m!ITS_AUTHORS_1W!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > ITS_AUTHORS_1W");
ok(grep(m!ITS_AUTHORS_1Y!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > ITS_AUTHORS_1Y");
ok(grep(m!ITS_CREATED_1M!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > ITS_CREATED_1M");
ok(grep(m!ITS_CREATED_1W!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > ITS_CREATED_1W");
ok(grep(m!ITS_CREATED_1Y!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > ITS_CREATED_1Y");
ok(grep(m!ITS_UPDATED_1M!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > ITS_UPDATED_1M");
ok(grep(m!ITS_UPDATED_1W!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > ITS_UPDATED_1W");
ok(grep(m!ITS_UPDATED_1Y!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > ITS_UPDATED_1Y");
ok(grep(m!ITS_OPEN!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > ITS_OPEN");
ok(grep(m!ITS_OPEN_UNASSIGNED!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > ITS_OPEN_UNASSIGNED");

ok(grep(m!bugzilla_evol_summary.html!, keys %{$conf->{'provides_figs'}}),
  "Conf has provides_figs > bugzilla_evol_summary.html");
ok(grep(m!bugzilla_components.html!, keys %{$conf->{'provides_figs'}}),
  "Conf has provides_figs > bugzilla_components.html");
ok(grep(m!bugzilla_versions.html!, keys %{$conf->{'provides_figs'}}),
  "Conf has provides_figs > bugzilla_versions.html");

# Remove file before trying to create them.
unlink (
    "projects/test.bugzilla/input/test.bugzilla_import_bugzilla.json",
    "projects/test.bugzilla/output/test.bugzilla_metrics.bugzilla.csv",
    "projects/test.bugzilla/output/test.bugzilla_metrics.bugzilla.json",
    "projects/test.bugzilla/output/test.bugzilla_bugzilla_issues.csv",
    "projects/test.bugzilla/output/test.bugzilla_bugzilla_evol.csv",
    "projects/test.bugzilla/output/test.bugzilla_bugzilla_issues_open.csv",
    "projects/test.bugzilla/output/test.bugzilla_bugzilla_issues_open_unassigned.csv",
    "projects/test.bugzilla/output/test.bugzilla_bugzilla_components.csv",
    "projects/test.bugzilla/output/test.bugzilla_bugzilla_milestones.csv",
    "projects/test.bugzilla/output/test.bugzilla_bugzilla_versions.csv",
    "projects/test.bugzilla/output/test.bugzilla_bugzilla_components.html",
    "projects/test.bugzilla/output/test.bugzilla_bugzilla_versions.html",
    "projects/test.bugzilla/output/test.bugzilla_bugzilla_evol_summary.html",
    );

note("Executing the plugin with acceleo project. ");
my $ret = $plugin->run_plugin(
  "test.bugzilla",
  {
    'bugzilla_url'         => 'https://bugs.eclipse.org/bugs/',
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

ok(grep(/^\[Tools::R\] Exec \[Rsc.*bugzilla.Rmd/, @{$ret->{'log'}}) == 1,
 "Checking if log contains bugzilla.Rmd R code exec.")
 or diag explain $ret;
ok(
 grep(/^\[Tools::R\] Exec \[Rsc.*bugzilla_evol_summary.rmd/, @{$ret->{'log'}})
   == 1,
 "Checking if log contains bugzilla_evol_summary.rmd R code exec."
) or diag explain $ret;
ok(
 grep(/^\[Tools::R\] Exec \[Rsc.*bugzilla_components.rmd/, @{$ret->{'log'}})
   == 1,
 "Checking if log contains bugzilla_components.rmd R code exec."
) or diag explain $ret;
ok(
 grep(/^\[Tools::R\] Exec \[Rsc.*bugzilla_versions.rmd/, @{$ret->{'log'}})
   == 1,
 "Checking if log contains bugzilla_versions.rmd R code exec."
) or diag explain $ret;

ok($ret->{'metrics'}{'ITS_ISSUES_ALL'} =~ /^\d+$/, "ITS_ISSUES_ALL is a digit.")
  or print Dumper($ret);
ok($ret->{'metrics'}{'ITS_OPEN'} =~ /^\d+$/, "ITS_OPEN is a digit.")
  or diag explain $ret;
ok($ret->{'metrics'}{'ITS_OPEN_OLD'} =~ /^\d+$/, "ITS_OPEN_OLD is a digit.")
  or diag explain $ret;
ok($ret->{'metrics'}{'ITS_OPEN_PERCENT'} =~ /^\d\d?$/,
  "ITS_OPEN_PERCENT is a digit.")
  or diag explain $ret;
ok($ret->{'metrics'}{'ITS_OPEN_UNASSIGNED'} =~ /^\d+$/,
  "ITS_OPEN_UNASSIGNED is a digit.")
  or diag explain $ret;
ok($ret->{'metrics'}{'ITS_CREATED_1M'} =~ /^\d+$/,
  "ITS_CREATED_1M is a digit.")
  or diag explain $ret;
ok($ret->{'metrics'}{'ITS_CREATED_1Y'} =~ /^\d+$/,
  "ITS_CREATED_1Y is a digit.")
  or diag explain $ret;
ok($ret->{'metrics'}{'ITS_CREATED_1W'} =~ /^\d+$/,
  "ITS_CREATED_1W is a digit.")
  or diag explain $ret;
ok($ret->{'metrics'}{'ITS_UPDATED_1M'} =~ /^\d+$/,
  "ITS_UPDATED_1M is a digit.")
  or diag explain $ret;
ok($ret->{'metrics'}{'ITS_UPDATED_1W'} =~ /^\d+$/,
  "ITS_UPDATED_1W is a digit.")
  or diag explain $ret;
ok($ret->{'metrics'}{'ITS_UPDATED_1Y'} =~ /^\d+$/,
  "ITS_UPDATED_1Y is a digit.")
  or diag explain $ret;
ok($ret->{'metrics'}{'ITS_AUTHORS_1W'} =~ /^\d+$/,
  "ITS_AUTHORS_1W is a digit.")
  or diag explain $ret;
ok($ret->{'metrics'}{'ITS_AUTHORS_1M'} =~ /^\d+$/,
  "ITS_AUTHORS_1M is a digit.")
  or diag explain $ret;
ok($ret->{'metrics'}{'ITS_AUTHORS_1Y'} =~ /^\d+$/,
  "ITS_AUTHORS_1Y is a digit.")
  or diag explain $ret;
ok($ret->{'metrics'}{'ITS_AUTHORS'} =~ /^\d+$/, "ITS_AUTHORS is a digit.")
  or diag explain $ret;


ok($ret->{'info'}{'BZ_URL'} eq 'https://bugs.eclipse.org/bugs//buglist.cgi?product=acceleo',
  "Ret has correct info ITS_URL.") or print Dumper($ret);


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

ok(-e "projects/test.bugzilla/output/test.bugzilla_bugzilla.inc",
  "Check that file bugzilla.inc exists.");

ok(-e "projects/test.bugzilla/output/test.bugzilla_bugzilla_evol_summary.html",
  "Check that file bugzilla_evol_summary.html exists.");
ok(-e "projects/test.bugzilla/output/test.bugzilla_bugzilla_components.html",
  "Check that file bugzilla_components.html exists.");
ok(-e "projects/test.bugzilla/output/test.bugzilla_bugzilla_versions.html",
  "Check that file bugzilla_versions.html exists.");

note("Executing the plugin with mozilla project. ");
my $ret = $plugin->run_plugin(
  "test.bugzilla2",
  {
    'bugzilla_url'         => 'https://bugzilla.mozilla.org/',
    'bugzilla_project'     => 'Data Platform and Tools',
  }
);


ok(
  grep(m!\[Plugins::Bugzilla\] Using URL \[https://bugzilla.mozilla.org/rest/bug!,
    @{$ret->{'log'}}),
  "Ret has log > using url."
) or print Dumper( $ret->{'log'} );
ok(grep(m!\[Plugins::Bugzilla\] Found \d+ issues.!, @{$ret->{'log'}}),
  "Ret has log > Found xxx issues.");
ok(grep(m!\[Plugins::Bugzilla\] Writing user events file!, @{$ret->{'log'}}),
  "Ret has log > Writing user events file.");

ok(grep(/^\[Tools::R\] Exec \[Rsc.*bugzilla.Rmd/, @{$ret->{'log'}}) == 1,
 "Checking if log contains bugzilla.Rmd R code exec.")
 or diag explain $ret;
ok(
 grep(/^\[Tools::R\] Exec \[Rsc.*bugzilla_evol_summary.rmd/, @{$ret->{'log'}})
   == 1,
 "Checking if log contains bugzilla_evol_summary.rmd R code exec."
) or diag explain $ret;
ok(
 grep(/^\[Tools::R\] Exec \[Rsc.*bugzilla_components.rmd/, @{$ret->{'log'}})
   == 1,
 "Checking if log contains bugzilla_components.rmd R code exec."
) or diag explain $ret;
ok(
 grep(/^\[Tools::R\] Exec \[Rsc.*bugzilla_versions.rmd/, @{$ret->{'log'}})
   == 1,
 "Checking if log contains bugzilla_versions.rmd R code exec."
) or diag explain $ret;

ok($ret->{'metrics'}{'ITS_ISSUES_ALL'} =~ /^\d+$/, "ITS_ISSUES_ALL is a digit.")
  or print Dumper($ret);
ok($ret->{'metrics'}{'ITS_OPEN'} =~ /^\d+$/, "ITS_OPEN is a digit.")
  or diag explain $ret;
ok($ret->{'metrics'}{'ITS_OPEN_OLD'} =~ /^\d+$/, "ITS_OPEN_OLD is a digit.")
  or diag explain $ret;
ok($ret->{'metrics'}{'ITS_OPEN_PERCENT'} =~ /^\d\d?$/,
  "ITS_OPEN_PERCENT is a digit.")
  or diag explain $ret;
ok($ret->{'metrics'}{'ITS_OPEN_UNASSIGNED'} =~ /^\d+$/,
  "ITS_OPEN_UNASSIGNED is a digit.")
  or diag explain $ret;
ok($ret->{'metrics'}{'ITS_CREATED_1M'} =~ /^\d+$/,
  "ITS_CREATED_1M is a digit.")
  or diag explain $ret;
ok($ret->{'metrics'}{'ITS_CREATED_1Y'} =~ /^\d+$/,
  "ITS_CREATED_1Y is a digit.")
  or diag explain $ret;
ok($ret->{'metrics'}{'ITS_CREATED_1W'} =~ /^\d+$/,
  "ITS_CREATED_1W is a digit.")
  or diag explain $ret;
ok($ret->{'metrics'}{'ITS_UPDATED_1M'} =~ /^\d+$/,
  "ITS_UPDATED_1M is a digit.")
  or diag explain $ret;
ok($ret->{'metrics'}{'ITS_UPDATED_1W'} =~ /^\d+$/,
  "ITS_UPDATED_1W is a digit.")
  or diag explain $ret;
ok($ret->{'metrics'}{'ITS_UPDATED_1Y'} =~ /^\d+$/,
  "ITS_UPDATED_1Y is a digit.")
  or diag explain $ret;
ok($ret->{'metrics'}{'ITS_AUTHORS_1W'} =~ /^\d+$/,
  "ITS_AUTHORS_1W is a digit.")
  or diag explain $ret;
ok($ret->{'metrics'}{'ITS_AUTHORS_1M'} =~ /^\d+$/,
  "ITS_AUTHORS_1M is a digit.")
  or diag explain $ret;
ok($ret->{'metrics'}{'ITS_AUTHORS_1Y'} =~ /^\d+$/,
  "ITS_AUTHORS_1Y is a digit.")
  or diag explain $ret;
ok($ret->{'metrics'}{'ITS_AUTHORS'} =~ /^\d+$/, "ITS_AUTHORS is a digit.")
  or diag explain $ret;

ok($ret->{'info'}{'BZ_URL'} eq 'https://bugzilla.mozilla.org//buglist.cgi?product=Data Platform and Tools',
  "Ret has correct info ITS_URL.") or print Dumper($ret);

note("Check that files have been created. ");
ok(-e "projects/test.bugzilla2/input/test.bugzilla2_import_bugzilla.json",
  "Check that file import_bugzilla.json exists.");

ok(-e "projects/test.bugzilla2/output/test.bugzilla2_metrics_bugzilla.csv",
  "Check that file metrics_bugzilla.csv exists.");
ok(-e "projects/test.bugzilla2/output/test.bugzilla2_metrics_bugzilla.json",
  "Check that file metrics_bugzilla.json exists.");

ok(-e "projects/test.bugzilla2/output/test.bugzilla2_bugzilla_evol.csv",
  "Check that file bugzilla_evol.csv exists.");
ok(-e "projects/test.bugzilla2/output/test.bugzilla2_bugzilla_issues.csv",
  "Check that file bugzilla_issues.csv exists.");
ok(-e "projects/test.bugzilla2/output/test.bugzilla2_bugzilla_issues_open.csv",
  "Check that file bugzilla_issues_open.csv exists.");
ok(-e "projects/test.bugzilla2/output/test.bugzilla2_bugzilla_issues_open_unassigned.csv",
  "Check that file bugzilla_issues_open_unassigned.csv exists.");

ok(-e "projects/test.bugzilla2/output/test.bugzilla2_bugzilla_components.csv",
  "Check that file bugzilla_components.csv exists.");
ok(-e "projects/test.bugzilla2/output/test.bugzilla2_bugzilla_milestones.csv",
  "Check that file bugzilla_milestones.csv exists.");
ok(-e "projects/test.bugzilla2/output/test.bugzilla2_bugzilla_versions.csv",
  "Check that file bugzilla_versions.csv exists.");

ok(-e "projects/test.bugzilla2/output/test.bugzilla2_bugzilla.inc",
  "Check that file bugzilla.inc exists.");

ok(-e "projects/test.bugzilla2/output/test.bugzilla2_bugzilla_evol_summary.html",
  "Check that file bugzilla_evol_summary.html exists.");
ok(-e "projects/test.bugzilla2/output/test.bugzilla2_bugzilla_components.html",
  "Check that file bugzilla_components.html exists.");
ok(-e "projects/test.bugzilla2/output/test.bugzilla2_bugzilla_versions.html",
  "Check that file bugzilla_versions.html exists.");


done_testing();

