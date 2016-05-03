#! perl -I../../lib/

use strict;
use warnings;

use Test::More;

BEGIN { use_ok( 'Alambic::Model::Project' ); }

my $project = Alambic::Model::Project->new( 'tools.cdt', 'Tools CDT' );
isa_ok( $project, 'Alambic::Model::Project' );

my $id = $project->get_id();
ok( $id =~ m!^tools.cdt$!, 'Project id is tools.cdt.' ) or diag explain $id;

my $name = $project->get_name();
ok( $name =~ m!^Tools CDT$!, 'Project name is Tools CDT.' ) or diag explain $name;

note("Adding EclipseIts plugin.");
my %plugin_conf = (
    "project.id" => "tools.cdt",
    "project_grim" => "tools.cdt",
    );
my $ret = $project->add_plugin('EclipseIts', \%plugin_conf);

note("Running EclipseIts plugin.");
$ret = $project->run_plugin( 'EclipseIts' );
ok( grep( /^ERROR/ ) == 0, "Log has no error." ) or diag explain $ret;
ok( grep( /^\[Plugins::EclipseIts\] Starting retrieval/, @{$ret} ) == 1, "Log has Starting retrieval." ) or diag explain $ret;
ok( grep( /^\[Plugins::EclipseIts\] Retrieving static/, @{$ret} ) == 1, "Log has Retrieving static." ) or diag explain $ret;
ok( grep( /^\[Plugins::EclipseIts\] Retrieving evol/, @{$ret} ) == 1, "Log has Retrieving evol." ) or diag explain $ret;
ok( grep( /^\[Plugins::EclipseIts\] Executing R/, @{$ret} ) == 1, "Log has Executing R." ) or diag explain $ret;

# Check that files have been created.
ok( -e "projects/tools.cdt/input/tools.cdt_import_its.json", "Check that file import_its.json exists." );
ok( -e "projects/tools.cdt/input/tools.cdt_import_its_evol.json", "Check that file import_its_evol.json exists." );
ok( -e "projects/tools.cdt/output/its_evol_changed.html", "Check that file its_evol_changed.html exists." );
ok( -e "projects/tools.cdt/output/EclipseIts.inc", "Check that file EclipseIts.inc exists." );
ok( -e "projects/tools.cdt/output/its_evol_ggplot.html", "Check that file its_evol_ggplot.html exists." );
ok( -e "projects/tools.cdt/output/its_evol_opened.html", "Check that file its_evol_opened.html exists." );
ok( -e "projects/tools.cdt/output/its_evol_people.html", "Check that file its_evol_people.html exists." );
ok( -e "projects/tools.cdt/output/its_evol_summary.html", "Check that file its_evol_summary.html exists." );
ok( -e "projects/tools.cdt/output/tools.cdt_metrics_its.json", "Check that file tools.cdt_metrics_its.json exists." );

note("Get metrics from project.");
$ret = $project->metrics();
is( $ret->{'ITS_TRACKERS'}, 2, "Number of trackers is 2." ) or diag explain $ret;
is( scalar grep( /ITS_CLOSED/, keys %{$ret} ), 4, "There should be 4 ITS_CLOSED_*." ) or diag explain $ret;
is( scalar grep( /ITS_CLOSERS/, keys %{$ret} ), 4, "There should be 4 ITS_CLOSERS_*." ) or diag explain $ret;
is( scalar grep( /ITS_DIFF_/, keys %{$ret} ), 6, "There should be 6 ITS_DIFF_*.") or diag explain $ret;
is( scalar grep( /ITS_PERCENTAGE/, keys %{$ret} ), 6, "There should be 6 ITS_PERCENTAGE_*." ) or diag explain $ret;
ok( exists($ret->{'ITS_CHANGED'}), "There should be a metric called ITS_CHANGED." ) or diag explain $ret;
ok( exists($ret->{'ITS_CHANGERS'}), "There should be a metric called ITS_CHANGERS." ) or diag explain $ret;
ok( exists($ret->{'ITS_OPENED'}), "There should be a metric called ITS_OPENED." ) or diag explain $ret;
ok( exists($ret->{'ITS_OPENERS'}), "There should be a metric called ITS_OPENERS." ) or diag explain $ret;

done_testing();
