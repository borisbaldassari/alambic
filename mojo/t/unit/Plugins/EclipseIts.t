#! perl -I../../lib/

use strict;
use warnings;

use Test::More;
use Mojo::JSON qw( decode_json);
use Data::Dumper;

BEGIN { use_ok( 'Alambic::Plugins::EclipseIts' ); }

my $plugin = Alambic::Plugins::EclipseIts->new();
isa_ok( $plugin, 'Alambic::Plugins::EclipseIts' );

note( "Checking the plugin parameters. ");
my $conf = $plugin->get_conf();

ok( grep( m!its_evol_summary.html!, keys %{$conf->{'provides_figs'}} ), "Conf has provides_figs > its_evol_summary" );
ok( grep( m!its_evol_changed.html!, keys %{$conf->{'provides_figs'}} ), "Conf has provides_figs > its_evol_changed" );
ok( grep( m!its_evol_opened.html!, keys %{$conf->{'provides_figs'}} ), "Conf has provides_figs > its_evol_opened" );
ok( grep( m!its_evol_people.html!, keys %{$conf->{'provides_figs'}} ), "Conf has provides_figs > its_evol_people" );

ok( grep( m!metrics_its.json!, keys %{$conf->{'provides_data'}} ), "Conf has provides_data > metrics_its.json" );
ok( grep( m!metrics_its.csv!, keys %{$conf->{'provides_data'}} ), "Conf has provides_data > metrics_its.csv" );
ok( grep( m!metrics_its_evol.json!, keys %{$conf->{'provides_data'}} ), "Conf has provides_data > metrics_its_evol.json" );
ok( grep( m!metrics_its_evol.csv!, keys %{$conf->{'provides_data'}} ), "Conf has provides_data > metrics_its_evol.csv" );

ok( grep( m!CHANGED!, keys %{$conf->{'provides_metrics'}} ), "Conf has provides_metrics > CHANGED" );
ok( grep( m!CHANGERS!, keys %{$conf->{'provides_metrics'}} ), "Conf has provides_metrics > CHANGERS" );
ok( grep( m!CLOSED!, keys %{$conf->{'provides_metrics'}} ), "Conf has provides_metrics > CLOSED" );
ok( grep( m!CLOSED_30!, keys %{$conf->{'provides_metrics'}} ), "Conf has provides_metrics > CLOSED_30" );
ok( grep( m!CLOSED_365!, keys %{$conf->{'provides_metrics'}} ), "Conf has provides_metrics > CLOSED_365" );
ok( grep( m!CLOSED_7!, keys %{$conf->{'provides_metrics'}} ), "Conf has provides_metrics > CLOSED_7" );
ok( grep( m!DIFF_NETCLOSED_30!, keys %{$conf->{'provides_metrics'}} ), "Conf has provides_metrics > DIFF_NETCLOSED_30" );
ok( grep( m!DIFF_NETCLOSED_365!, keys %{$conf->{'provides_metrics'}} ), "Conf has provides_metrics > DIFF_NETCLOSED_365" );
ok( grep( m!DIFF_NETCLOSED_7!, keys %{$conf->{'provides_metrics'}} ), "Conf has provides_metrics > DIFF_NETCLOSED_7" );
ok( grep( m!PERCENTAGE_CLOSED_30!, keys %{$conf->{'provides_metrics'}} ), "Conf has provides_metrics > PERCENTAGE_CLOSED_30" );
ok( grep( m!PERCENTAGE_CLOSED_365!, keys %{$conf->{'provides_metrics'}} ), "Conf has provides_metrics > PERCENTAGE_CLOSED_365" );
ok( grep( m!PERCENTAGE_CLOSED_7!, keys %{$conf->{'provides_metrics'}} ), "Conf has provides_metrics > PERCENTAGE_CLOSED_7" );
ok( grep( m!CLOSERS!, keys %{$conf->{'provides_metrics'}} ), "Conf has provides_metrics > CLOSERS" );
ok( grep( m!CLOSERS_30!, keys %{$conf->{'provides_metrics'}} ), "Conf has provides_metrics > CLOSERS_30" );
ok( grep( m!CLOSERS_365!, keys %{$conf->{'provides_metrics'}} ), "Conf has provides_metrics > CLOSERS_365" );
ok( grep( m!CLOSERS_7!, keys %{$conf->{'provides_metrics'}} ), "Conf has provides_metrics > CLOSERS_7" );
ok( grep( m!DIFF_NETCLOSERS_30!, keys %{$conf->{'provides_metrics'}} ), "Conf has provides_metrics > DIFF_NETCLOSERS_30" );
ok( grep( m!DIFF_NETCLOSERS_365!, keys %{$conf->{'provides_metrics'}} ), "Conf has provides_metrics > DIFF_NETCLOSERS_365" );
ok( grep( m!DIFF_NETCLOSERS_7!, keys %{$conf->{'provides_metrics'}} ), "Conf has provides_metrics > DIFF_NETCLOSERS_7" );
ok( grep( m!PERCENTAGE_CLOSERS_30!, keys %{$conf->{'provides_metrics'}} ), "Conf has provides_metrics > PERCENTAGE_CLOSERS_30" );
ok( grep( m!PERCENTAGE_CLOSERS_365!, keys %{$conf->{'provides_metrics'}} ), "Conf has provides_metrics > PERCENTAGE_CLOSERS_365" );
ok( grep( m!PERCENTAGE_CLOSERS_7!, keys %{$conf->{'provides_metrics'}} ), "Conf has provides_metrics > PERCENTAGE_CLOSERS_7" );
ok( grep( m!TRACKERS!, keys %{$conf->{'provides_metrics'}} ), "Conf has provides_metrics > TRACKERS" );
ok( grep( m!OPENED!, keys %{$conf->{'provides_metrics'}} ), "Conf has provides_metrics > OPENED" );
ok( grep( m!OPENERS!, keys %{$conf->{'provides_metrics'}} ), "Conf has provides_metrics > OPENERS" );

ok( grep( m!metrics!, @{$conf->{'ability'}} ), "Conf has ability > metrics" );
ok( grep( m!data!, @{$conf->{'ability'}} ), "Conf has ability > data" );
ok( grep( m!recs!, @{$conf->{'ability'}} ), "Conf has ability > recs" );
ok( grep( m!figs!, @{$conf->{'ability'}} ), "Conf has ability > figs" );
ok( grep( m!viz!, @{$conf->{'ability'}} ), "Conf has ability > viz" );

ok( grep( m!project_grim!, keys %{$conf->{'params'}} ), "Conf has params > project_grim" );

ok( grep( m!ITS_OPEN_BUGS!, @{$conf->{'provides_recs'}} ), "Conf has provides_recs > its_open_bugs" );
ok( grep( m!ITS_CLOSERS!, @{$conf->{'provides_recs'}} ), "Conf has provides_recs > its_closers" );

ok( grep( m!eclipse_its.html!, keys %{$conf->{'provides_viz'}} ), "Conf has provides_figs > eclipse_its" );

# Execute the plugin
note( "Executing the plugin with tools.cdt project. ");
my $ret = $plugin->run_plugin("tools.cdt", { 'project_grim' => 'tools.cdt' } ); 
is( $ret->{'metrics'}{'ITS_TRACKERS'}, 2, "Number of trackers is 2." ) or diag explain $ret;
is( scalar grep( /ITS_CLOSED/, keys %{$ret->{'metrics'}} ), 4, "There should be 4 ITS_CLOSED_*." ) or diag explain $ret;
is( scalar grep( /ITS_CLOSERS/, keys %{$ret->{'metrics'}} ), 4, "There should be 4 ITS_CLOSERS_*." ) or diag explain $ret;
is( scalar grep( /ITS_DIFF_/, keys %{$ret->{'metrics'}} ), 6, "There should be 6 ITS_DIFF_*.") or diag explain $ret;
is( scalar grep( /ITS_PERCENTAGE/, keys %{$ret->{'metrics'}} ), 6, "There should be 6 ITS_PERCENTAGE_*." ) or diag explain $ret;
ok( exists($ret->{'metrics'}{'ITS_CHANGED'}), "There should be a metric called ITS_CHANGED." ) or diag explain $ret;
ok( exists($ret->{'metrics'}{'ITS_CHANGERS'}), "There should be a metric called ITS_CHANGERS." ) or diag explain $ret;
ok( exists($ret->{'metrics'}{'ITS_OPENED'}), "There should be a metric called ITS_OPENED." ) or diag explain $ret;
ok( exists($ret->{'metrics'}{'ITS_OPENERS'}), "There should be a metric called ITS_OPENERS." ) or diag explain $ret;

# Check that files have been created.
note( "Check that files have been created. ");
ok( -e "projects/tools.cdt/input/tools.cdt_import_its.json", "Check that file import_its.json exists." );
ok( -e "projects/tools.cdt/input/tools.cdt_import_its_evol.json", "Check that file import_its_evol.json exists." );
ok( -e "projects/tools.cdt/output/tools.cdt_import_its.json", "Check that file import_its.json exists." );
ok( -e "projects/tools.cdt/output/tools.cdt_its_evol_changed.html", "Check that file its_evol_changed.html exists." );
ok( -e "projects/tools.cdt/output/tools.cdt_its_evol_opened.html", "Check that file its_evol_opened.html exists." );
ok( -e "projects/tools.cdt/output/tools.cdt_its_evol_people.html", "Check that file its_evol_people.html exists." );
ok( -e "projects/tools.cdt/output/tools.cdt_its_evol_summary.html", "Check that file its_evol_summary.html exists." );
ok( -e "projects/tools.cdt/output/tools.cdt_eclipse_its.inc", "Check that file EclipseIts.inc exists." );
ok( -e "projects/tools.cdt/output/tools.cdt_metrics_its.csv", "Check that file tools.cdt_metrics_its.csv exists." );
ok( -e "projects/tools.cdt/output/tools.cdt_metrics_its.json", "Check that file tools.cdt_metrics_its.json exists." );
ok( -e "projects/tools.cdt/output/tools.cdt_metrics_its_evol.csv", "Check that file tools.cdt_metrics_its_evol.csv exists." );
ok( -e "projects/tools.cdt/output/tools.cdt_metrics_its_evol.json", "Check that file tools.cdt_metrics_its_evol.json exists." );


done_testing();
