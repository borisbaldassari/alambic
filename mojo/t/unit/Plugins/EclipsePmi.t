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

BEGIN { use_ok('Alambic::Plugins::EclipsePmi'); }

my $plugin = Alambic::Plugins::EclipsePmi->new();
isa_ok($plugin, 'Alambic::Plugins::EclipsePmi');

note("Checking the plugin parameters. ");
my $conf = $plugin->get_conf();

ok(grep(m!PROJECT_MLS_DEV_URL!, @{$conf->{'provides_info'}}),
  "Conf has provides_info > PROJECT_MLS_DEV_URL");
ok(grep(m!PROJECT_MLS_USR_URL!, @{$conf->{'provides_info'}}),
  "Conf has provides_info > PROJECT_MLS_USR_URL");
ok(grep(m!PROJECT_URL!, @{$conf->{'provides_info'}}),
  "Conf has provides_info > PROJECT_URL");
ok(grep(m!PROJECT_WIKI_URL!, @{$conf->{'provides_info'}}),
  "Conf has provides_info > PROJECT_WIKI_URL");
ok(grep(m!PROJECT_DOWNLOAD_URL!, @{$conf->{'provides_info'}}),
  "Conf has provides_info > PROJECT_DOWNLOAD_URL");
ok(grep(m!PROJECT_SCM_URL!, @{$conf->{'provides_info'}}),
  "Conf has provides_info > PROJECT_SCM_URL");
ok(grep(m!PROJECT_ITS_URL!, @{$conf->{'provides_info'}}),
  "Conf has provides_info > PROJECT_ITS_URL");
ok(grep(m!PROJECT_CI_URL!, @{$conf->{'provides_info'}}),
  "Conf has provides_info > PROJECT_CI_URL");
ok(grep(m!PROJECT_DOC_URL!, @{$conf->{'provides_info'}}),
  "Conf has provides_info > PROJECT_DOC_URL");
ok(grep(m!PROJECT_NAME!, @{$conf->{'provides_info'}}),
  "Conf has provides_info > PROJECT_NAME ");
ok(grep(m!PROJECT_DESC!, @{$conf->{'provides_info'}}),
  "Conf has provides_info > PROJECT_DESC");
ok(grep(m!PROJECT_ID!, @{$conf->{'provides_info'}}),
  "Conf has provides_info > PROJECT_ID");

ok(grep(m!PMI_BUGZILLA_CREATE_URL!, @{$conf->{'provides_info'}}),
  "Conf has provides_info > PMI_BUGZILLA_CREATE_URL");
ok(grep(m!PMI_BUGZILLA_COMPONENT!, @{$conf->{'provides_info'}}),
  "Conf has provides_info > PMI_BUGZILLA_COMPONENT");
ok(grep(m!PMI_BUGZILLA_PRODUCT!, @{$conf->{'provides_info'}}),
  "Conf has provides_info > PMI_BUGZILLA_PRODUCT");
ok(grep(m!PMI_BUGZILLA_QUERY_URL!, @{$conf->{'provides_info'}}),
  "Conf has provides_info > PMI_BUGZILLA_QUERY_URL");
ok(grep(m!PMI_GETTINGSTARTED_URL!, @{$conf->{'provides_info'}}),
  "Conf has provides_info > PMI_GETTINGSTARTED_URL");
ok(grep(m!PMI_UPDATESITE_URL!, @{$conf->{'provides_info'}}),
  "Conf has provides_info > PMI_UPDATESITE_URL");

ok(grep(m!pmi.json!, keys %{$conf->{'provides_data'}}),
  "Conf has provides_data > pmi.json");
ok(grep(m!pmi_checks.json!, keys %{$conf->{'provides_data'}}),
  "Conf has provides_data > pmi_checks.json");
ok(grep(m!pmi_checks.csv!, keys %{$conf->{'provides_data'}}),
  "Conf has provides_data > pmi_checks.csv");

ok(grep(m!PROJECT_ITS_INFO!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > PROJECT_ITS_INFO");
ok(grep(m!PROJECT_SCM_INFO!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > PROJECT_SCM_INFO");
ok(grep(m!PROJECT_CI_INFO!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > PROJECT_CI_INFO");
ok(grep(m!PROJECT_ACCESS_INFO!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > PROJECT_ACCESS_INFO");
ok(grep(m!PROJECT_REL_VOL!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > PROJECT_REL_VOL");

ok(grep(m!metrics!, @{$conf->{'ability'}}), "Conf has ability > metrics");
ok(grep(m!data!,    @{$conf->{'ability'}}), "Conf has ability > data");
ok(grep(m!recs!,    @{$conf->{'ability'}}), "Conf has ability > recs");
ok(grep(m!info!,    @{$conf->{'ability'}}), "Conf has ability > info");
ok(grep(m!viz!,     @{$conf->{'ability'}}), "Conf has ability > viz");

ok(grep(m!project_pmi!, keys %{$conf->{'params'}}),
  "Conf has params > project_pmi");

ok(
  grep(m!PMI_EMPTY_BUGZILLA_CREATE!, @{$conf->{'provides_recs'}}),
  "Conf has provides_recs > PMI_EMPTY_BUGZILLA_CREATE"
);
ok(
  grep(m!PMI_NOK_BUGZILLA_CREATE!, @{$conf->{'provides_recs'}}),
  "Conf has provides_recs > PMI_NOK_BUGZILLA_CREATE"
);
ok(
  grep(m!PMI_EMPTY_BUGZILLA_QUERY!, @{$conf->{'provides_recs'}}),
  "Conf has provides_recs > PMI_EMPTY_BUGZILLA_QUERY"
);
ok(
  grep(m!PMI_NOK_BUGZILLA_QUERY!, @{$conf->{'provides_recs'}}),
  "Conf has provides_recs > PMI_NOK_BUGZILLA_QUERY"
);
ok(
  grep(m!PMI_EMPTY_TITLE!, @{$conf->{'provides_recs'}}),
  "Conf has provides_recs > PMI_EMPTY_TITLE"
);
ok(grep(m!PMI_NOK_WEB!, @{$conf->{'provides_recs'}}),
  "Conf has provides_recs > PMI_NOK_WEB");
ok(grep(m!PMI_EMPTY_WEB!, @{$conf->{'provides_recs'}}),
  "Conf has provides_recs > PMI_EMPTY_WEB");
ok(grep(m!PMI_NOK_WIKI!, @{$conf->{'provides_recs'}}),
  "Conf has provides_recs > PMI_NOK_WIKI");
ok(grep(m!PMI_EMPTY_WIKI!, @{$conf->{'provides_recs'}}),
  "Conf has provides_recs > PMI_EMPTY_WIKI");
ok(
  grep(m!PMI_NOK_DOWNLOAD!, @{$conf->{'provides_recs'}}),
  "Conf has provides_recs > PMI_NOK_DOWNLOAD"
);
ok(
  grep(m!PMI_EMPTY_DOWNLOAD!, @{$conf->{'provides_recs'}}),
  "Conf has provides_recs > PMI_EMPTY_DOWNLOAD"
);
ok(
  grep(m!PMI_NOK_GETTING_STARTED!, @{$conf->{'provides_recs'}}),
  "Conf has provides_recs > PMI_NOK_GETTING_STARTED"
);
ok(
  grep(m!PMI_EMPTY_GETTING_STARTED!, @{$conf->{'provides_recs'}}),
  "Conf has provides_recs > PMI_EMPTY_GETTING_STARTED"
);
ok(grep(m!PMI_NOK_DOC!, @{$conf->{'provides_recs'}}),
  "Conf has provides_recs > PMI_NOK_DOC");
ok(grep(m!PMI_EMPTY_DOC!, @{$conf->{'provides_recs'}}),
  "Conf has provides_recs > PMI_EMPTY_DOC");
ok(grep(m!PMI_NOK_PLAN!, @{$conf->{'provides_recs'}}),
  "Conf has provides_recs > PMI_NOK_PLAN");
ok(grep(m!PMI_EMPTY_PLAN!, @{$conf->{'provides_recs'}}),
  "Conf has provides_recs > PMI_EMPTY_PLAN");
ok(
  grep(m!PMI_NOK_PROPOSAL!, @{$conf->{'provides_recs'}}),
  "Conf has provides_recs > PMI_NOK_PROPOSAL"
);
ok(
  grep(m!PMI_EMPTY_PROPOSAL!, @{$conf->{'provides_recs'}}),
  "Conf has provides_recs > PMI_EMPTY_PROPOSAL"
);
ok(grep(m!PMI_NOK_DEV_ML!, @{$conf->{'provides_recs'}}),
  "Conf has provides_recs > PMI_NOK_DEV_ML");
ok(
  grep(m!PMI_EMPTY_DEV_ML!, @{$conf->{'provides_recs'}}),
  "Conf has provides_recs > PMI_EMPTY_DEV_ML"
);
ok(
  grep(m!PMI_NOK_USER_ML!, @{$conf->{'provides_recs'}}),
  "Conf has provides_recs > PMI_NOK_USER_ML"
);
ok(
  grep(m!PMI_EMPTY_USER_ML!, @{$conf->{'provides_recs'}}),
  "Conf has provides_recs > PMI_EMPTY_USER_ML"
);
ok(grep(m!PMI_NOK_SCM!, @{$conf->{'provides_recs'}}),
  "Conf has provides_recs > PMI_NOK_SCM");
ok(grep(m!PMI_EMPTY_SCM!, @{$conf->{'provides_recs'}}),
  "Conf has provides_recs > PMI_EMPTY_SCM");
ok(grep(m!PMI_NOK_UPDATE!, @{$conf->{'provides_recs'}}),
  "Conf has provides_recs > PMI_NOK_UPDATE");
ok(
  grep(m!PMI_EMPTY_UPDATE!, @{$conf->{'provides_recs'}}),
  "Conf has provides_recs > PMI_EMPTY_UPDATE"
);
ok(grep(m!PMI_NOK_CI!, @{$conf->{'provides_recs'}}),
  "Conf has provides_recs > PMI_NOK_CI");
ok(grep(m!PMI_EMPTY_CI!, @{$conf->{'provides_recs'}}),
  "Conf has provides_recs > PMI_EMPTY_CI");
ok(grep(m!PMI_EMPTY_REL!, @{$conf->{'provides_recs'}}),
  "Conf has provides_recs > PMI_EMPTY_REL");

ok(grep(m!pmi_checks!, keys %{$conf->{'provides_viz'}}),
  "Conf has provides_figs > pmi_checks");

# Execute the plugin
note("Execute the plugin with tools.cdt project. ");
my $ret = $plugin->run_plugin("tools.cdt", {'project_pmi' => 'tools.cdt', proxy => ''});
ok($ret->{'info'}->{'PROJECT_ID'} =~ m!tools.cdt$!,
  "Project has correct id.") or diag explain $ret;
ok($ret->{'info'}->{'PROJECT_DESC'} =~ m!\S+!,
  "Project desc is a string.") or diag explain $ret;
ok($ret->{'info'}->{'PROJECT_DOC_URL'} =~ m!^http://wiki.eclipse.org/index.php/CDT$!,
  "Project doc url is correct.") or diag explain $ret;
ok($ret->{'info'}->{'PROJECT_DOWNLOAD_URL'} =~ m!^http://www.eclipse.org/cdt/downloads.php$!,
  "Project dl url is correct.") or diag explain $ret;
ok($ret->{'info'}->{'PROJECT_MAIN_URL'} =~ m!^http://www.eclipse.org/cdt$!,
 "Project has correct main url.") or diag explain $ret;
ok($ret->{'info'}->{'PROJECT_WIKI_URL'} =~ m!^http://wiki.eclipse.org/index.php/CDT$!,
  "Project has correct wiki url.") or diag explain $ret;

is($ret->{'info'}{'PMI_BUGZILLA_PRODUCT'}, 'CDT', "Bugzilla product is CDT.")
  or diag explain $ret;
is(
  $ret->{'info'}{'PROJECT_NAME'},
  'Eclipse C/C++ Development Tooling (CDT)',
  "Project name is correct."
) or diag explain $ret;
is(
  $ret->{'log'}[0],
  '[Plugins::EclipsePmi] No proxy defined [].',
  "Checking first line of log."
) or diag explain $ret;
is(
  $ret->{'log'}[1],
  '[Plugins::EclipsePmi] Using Eclipse PMI infra at [https://projects.eclipse.org/json/project/tools.cdt].',
  "Checking first line of log."
) or diag explain $ret;
is($ret->{'metrics'}{'PROJECT_ITS_INFO'}, 5, "Metric PROJECT_ITS_INFO is 5.")
  or diag explain $ret;

# Check pmi checks
note("Checking retrieved file. ");
my $content;
my $file = "projects/tools.cdt/output/tools.cdt_pmi_checks.json";
do {
  local $/;
  open my $fh, '<', $file;
  $content = <$fh>;
  close $fh;
};
my $json = decode_json($content);

# generic information about the checks
is($json->{'id_pmi'}, 'tools.cdt', "Checks: id_pmi is ok.")
  or diag explain $json->{'id_pmi'};
is(
  $json->{'pmi_url'},
  'https://projects.eclipse.org/json/project/tools.cdt',
  "Checks: pmi_url is ok."
) or diag explain $json->{'pmi_url'};
is(
  $json->{'name'},
  'Eclipse C/C++ Development Tooling (CDT)',
  "Checks: name is ok."
) or diag explain $json->{'name'};

# now check checks themselves
is(
  $json->{'checks'}{'download_url'}{'value'},
  'http://www.eclipse.org/cdt/downloads.php',
  "Checks: download_url is ok."
) or diag explain $json->{'checks'}{'download_url'};
is($json->{'checks'}{'website_url'}{'value'},
  'http://www.eclipse.org/cdt', "Checks: website_url is ok.")
  or diag explain $json->{'checks'}{'website_url'};
is(
  $json->{'checks'}{'build_url'}{'results'}[0],
  'Failed: could not get CI URL [].',
  "Checks: build_url is ok (empty)."
) or diag explain $json->{'checks'}{'build_url'};
is(
  $json->{'checks'}{'title'}{'value'},
  'Eclipse C/C++ Development Tooling (CDT)',
  "Checks: title is ok."
) or diag explain $json->{'checks'}{'title'}{'value'};

# Check that files have been created.
note("Check that files have been created. ");
ok(-e "projects/tools.cdt/input/tools.cdt_import_pmi.json",
  "Check that file import_pmi.json exists.");
ok(
  -e "projects/tools.cdt/output/tools.cdt_pmi.json",
  "Check that file tools.cdt_metrics_pmi.json exists."
);
ok(
  -e "projects/tools.cdt/output/tools.cdt_pmi_checks.json",
  "Check that file tools.cdt_metrics_pmi_checks.json exists."
);
ok(
  -e "projects/tools.cdt/output/tools.cdt_pmi_checks.csv",
  "Check that file tools.cdt_metrics_pmi_checks.csv exists."
);


done_testing();

exit;

