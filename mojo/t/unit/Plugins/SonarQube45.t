#! perl -I../../lib/

use strict;
use warnings;

use Test::More;
use Mojo::JSON qw( decode_json);
use Data::Dumper;

BEGIN { use_ok('Alambic::Plugins::SonarQube45'); }

my $plugin = Alambic::Plugins::SonarQube45->new();
isa_ok($plugin, 'Alambic::Plugins::SonarQube45');

note("Checking the plugin parameters. ");
my $conf = $plugin->get_conf();

ok(grep(m!sonar_coverage.html!, keys %{$conf->{'provides_figs'}}),
  "Conf has provides_figs > sonar_coverage");
ok(grep(m!sonar_rules.html!, keys %{$conf->{'provides_figs'}}),
  "Conf has provides_figs > sonar_rules");

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
ok(grep(m!recs!,    @{$conf->{'ability'}}), "Conf has ability > recs");
ok(grep(m!figs!,    @{$conf->{'ability'}}), "Conf has ability > figs");
ok(grep(m!viz!,     @{$conf->{'ability'}}), "Conf has ability > viz");

ok(grep(m!sonar_project!, keys %{$conf->{'params'}}),
  "Conf has params > sonar_project");
ok(grep(m!sonar_project!, keys %{$conf->{'params'}}),
  "Conf has params > sonar_url");

ok(grep(m!sonar.html!, keys %{$conf->{'provides_viz'}}),
  "Conf has provides_figs > sonar_coverage");

my $in_sonar_url     = "http://localhost:9000";
my $in_sonar_project = "log4j";

note("Executing the plugin with log4j project. ");
my $ret = $plugin->run_plugin("test.project",
  {'sonar_url' => $in_sonar_url, 'sonar_project' => $in_sonar_project});

# Test log
my @log = @{$ret->{'log'}};
ok(grep(!/^ERROR/, @log), "Log returns no ERROR") or diag explain @log;
ok(grep(m!^\[Plugins::SonarQube45\] Get issues from \[http://localhost!, @log),
  "Log returns get issues.")
  or diag explain @log;
ok(grep(m!^\[Plugins::SonarQube45\] Got \[\d+\] blocker issues.!, @log),
  "Log returns got blocker issues.")
  or diag explain @log;
ok(grep(m!^\[Plugins::SonarQube45\] Got \[\d+\] critical issues.!, @log),
  "Log returns got critical issues.")
  or diag explain @log;
ok(grep(m!^\[Plugins::SonarQube45\] Got \[\d+\] major issues.!, @log),
  "Log returns got major issues.")
  or diag explain @log;
ok(grep(m!^\[Plugins::SonarQube45\] Got \[37\] rules.!, @log),
  "Log returns 37 rules.")
  or diag explain @log;
ok(
  grep(m!^\[Plugins::SonarQube45\] Get resources from \[http://localhost!,
    @log),
  "Log returns get resources."
) or diag explain @log;
ok(grep(m!^\[Plugins::SonarQube45\] Got \[12\] metrics.!, @log),
  "Log returns got 12 metrics.")
  or diag explain @log;

# Test metrics
ok($ret->{'metrics'}{'SQ_COMR'},
  "Metric COMR is " . $ret->{'metrics'}{'SQ_COMR'} . ".")
  or diag explain $ret;
ok($ret->{'metrics'}{'SQ_PUBLIC_API'},
  "Metric PUBLIC_API is " . $ret->{'metrics'}{'SQ_PUBLIC_API'} . ".")
  or diag explain $ret;
ok($ret->{'metrics'}{'SQ_FILES'},
  "Metric FILES is " . $ret->{'metrics'}{'SQ_FILES'} . ".")
  or diag explain $ret;
ok($ret->{'metrics'}{'SQ_PUBLIC_API_DOC_DENSITY'},
  "Metric PUBLIC_API_DOC_DENSITY is "
    . $ret->{'metrics'}{'SQ_PUBLIC_API_DOC_DENSITY'} . ".")
  or diag explain $ret;
ok($ret->{'metrics'}{'SQ_CPX_FUNC_IDX'},
  "Metric CPX_FUNC_IDX is " . $ret->{'metrics'}{'SQ_CPX_FUNC_IDX'} . ".")
  or diag explain $ret;
ok($ret->{'metrics'}{'SQ_COMMENT_LINES'},
  "Metric COMMENT_LINES is " . $ret->{'metrics'}{'SQ_COMMENT_LINES'} . ".")
  or diag explain $ret;
ok($ret->{'metrics'}{'SQ_CPX_FILE_IDX'},
  "Metric CPX_FILE_IDX is " . $ret->{'metrics'}{'SQ_CPX_FILE_IDX'} . ".")
  or diag explain $ret;
ok($ret->{'metrics'}{'SQ_NCLOC'},
  "Metric NCLOC is " . $ret->{'metrics'}{'SQ_NCLOC'} . ".")
  or diag explain $ret;
ok($ret->{'metrics'}{'SQ_FUNCS'},
  "Metric FUNCS is " . $ret->{'metrics'}{'SQ_FUNCS'} . ".")
  or diag explain $ret;

done_testing();
exit;

note("Check that files have been created. ");
ok(-e "projects/tools.cdt/input/tools.cdt_import_its.json",
  "Check that file import_its.json exists.");
ok(-e "projects/tools.cdt/input/tools.cdt_import_its_evol.json",
  "Check that file import_its_evol.json exists.");
ok(
  -e "projects/tools.cdt/output/its_evol_changed.html",
  "Check that file its_evol_changed.html exists."
);
ok(
  -e "projects/tools.cdt/output/eclipse_its.inc",
  "Check that file EclipseIts.inc exists."
);
ok(
  -e "projects/tools.cdt/output/its_evol_opened.html",
  "Check that file its_evol_opened.html exists."
);
ok(
  -e "projects/tools.cdt/output/its_evol_people.html",
  "Check that file its_evol_people.html exists."
);
ok(
  -e "projects/tools.cdt/output/its_evol_summary.html",
  "Check that file its_evol_summary.html exists."
);
ok(
  -e "projects/tools.cdt/output/tools.cdt_metrics_its.json",
  "Check that file tools.cdt_metrics_its.json exists."
);


done_testing(19);
