#! perl -I../../lib/

use strict;
use warnings;

use Test::More;
use Mojo::JSON qw( decode_json);

BEGIN { use_ok( 'Alambic::Plugins::EclipseIts' ); }

my $plugin = Alambic::Plugins::EclipseIts->new();
isa_ok( $plugin, 'Alambic::Plugins::EclipseIts' );

my $ret = $plugin->run_plugin("tools.cdt", { 'project_grim' => 'tools.cdt' } );
is( $ret->{'metrics'}{'ITS_TRACKERS'}, 2, "Number of trackers is 2." ) or diag explain $ret;
is( scalar grep( /ITS_CLOSED/, keys %{$ret->{'metrics'}} ), 4, "There should be 4 ITS_CLOSED_*." ) or diag explain $ret;
is( scalar grep( /ITS_CLOSERS/, keys %{$ret->{'metrics'}} ), 4, "There should be 4 ITS_CLOSERS_*." ) or diag explain $ret;
is( scalar grep( /ITS_DIFF_/, keys %{$ret->{'metrics'}} ), 6, "There should be 6 ITS_DIFF_*.") or diag explain $ret;
is( scalar grep( /ITS_PERCENTAGE/, keys %{$ret->{'metrics'}} ), 6, "There should be 6 ITS_PERCENTAGE_*." ) or diag explain $ret;
ok( exists($ret->{'metrics'}{'ITS_CHANGED'}), "There should a metric called ITS_CHANGED." ) or diag explain $ret;
ok( exists($ret->{'metrics'}{'ITS_CHANGERS'}), "There should a metric called ITS_CHANGERS." ) or diag explain $ret;
ok( exists($ret->{'metrics'}{'ITS_OPENED'}), "There should a metric called ITS_OPENED." ) or diag explain $ret;
ok( exists($ret->{'metrics'}{'ITS_OPENERS'}), "There should a metric called ITS_OPENERS." ) or diag explain $ret;

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


done_testing(20);
