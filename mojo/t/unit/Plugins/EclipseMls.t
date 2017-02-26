#! perl -I../../lib/

use strict;
use warnings;

use Test::More;
use Mojo::JSON qw( decode_json);
use Data::Dumper;

BEGIN { use_ok( 'Alambic::Plugins::EclipseMls' ); }

my $plugin = Alambic::Plugins::EclipseMls->new();
isa_ok( $plugin, 'Alambic::Plugins::EclipseMls' );

note( "Checking the plugin parameters. ");
my $conf = $plugin->get_conf();

ok( grep( m!mls_evol_summary.html!, keys %{$conf->{'provides_figs'}} ), "Conf has provides_figs > mls_evol_summary" );
ok( grep( m!mls_evol_sent.html!, keys %{$conf->{'provides_figs'}} ), "Conf has provides_figs > mls_evol_sent" );
ok( grep( m!mls_evol_people.html!, keys %{$conf->{'provides_figs'}} ), "Conf has provides_figs > mls_evol_people" );

ok( grep( m!metrics_mls.json!, keys %{$conf->{'provides_data'}} ), "Conf has provides_data > metrics_mls.json" );
ok( grep( m!metrics_mls.csv!, keys %{$conf->{'provides_data'}} ), "Conf has provides_data > metrics_mls.csv" );
ok( grep( m!metrics_mls_evol.json!, keys %{$conf->{'provides_data'}} ), "Conf has provides_data > metrics_mls_evol.json" );
ok( grep( m!metrics_mls_evol.csv!, keys %{$conf->{'provides_data'}} ), "Conf has provides_data > metrics_mls_evol.csv" );

ok( grep( m!REPOSITORIES!, keys %{$conf->{'provides_metrics'}} ), "Conf has provides_metrics > REPOSITORIES" );
ok( grep( m!SENDERS!, keys %{$conf->{'provides_metrics'}} ), "Conf has provides_metrics > SENDERS" );
ok( grep( m!SENDERS_30!, keys %{$conf->{'provides_metrics'}} ), "Conf has provides_metrics > SENDERS_30" );
ok( grep( m!SENDERS_365!, keys %{$conf->{'provides_metrics'}} ), "Conf has provides_metrics > SENDERS_365" );
ok( grep( m!SENDERS_7!, keys %{$conf->{'provides_metrics'}} ), "Conf has provides_metrics > SENDERS_7" );
ok( grep( m!SENDERS_RESPONSE!, keys %{$conf->{'provides_metrics'}} ), "Conf has provides_metrics > SENDERS_RESPONSE" );
ok( grep( m!DIFF_NETSENDERS_30!, keys %{$conf->{'provides_metrics'}} ), "Conf has provides_metrics > DIFF_NETSENDERS_30" );
ok( grep( m!DIFF_NETSENDERS_365!, keys %{$conf->{'provides_metrics'}} ), "Conf has provides_metrics > DIFF_NETSENDERS_365" );
ok( grep( m!DIFF_NETSENDERS_7!, keys %{$conf->{'provides_metrics'}} ), "Conf has provides_metrics > DIFF_NETSENDERS_7" );
ok( grep( m!PERCENTAGE_SENDERS_30!, keys %{$conf->{'provides_metrics'}} ), "Conf has provides_metrics > PERCENTAGE_SENDERS_30" );
ok( grep( m!PERCENTAGE_SENDERS_365!, keys %{$conf->{'provides_metrics'}} ), "Conf has provides_metrics > PERCENTAGE_SENDERS_365" );
ok( grep( m!PERCENTAGE_SENDERS_7!, keys %{$conf->{'provides_metrics'}} ), "Conf has provides_metrics > PERCENTAGE_SENDERS_7" );
ok( grep( m!SENT!, keys %{$conf->{'provides_metrics'}} ), "Conf has provides_metrics > SENT" );
ok( grep( m!SENT_30!, keys %{$conf->{'provides_metrics'}} ), "Conf has provides_metrics > SENT_30" );
ok( grep( m!SENT_365!, keys %{$conf->{'provides_metrics'}} ), "Conf has provides_metrics > SENT_365" );
ok( grep( m!SENT_7!, keys %{$conf->{'provides_metrics'}} ), "Conf has provides_metrics > SENT_7" );
ok( grep( m!DIFF_NETSENT_30!, keys %{$conf->{'provides_metrics'}} ), "Conf has provides_metrics > DIFF_NETSENT_30" );
ok( grep( m!DIFF_NETSENT_365!, keys %{$conf->{'provides_metrics'}} ), "Conf has provides_metrics > DIFF_NETSENT_365" );
ok( grep( m!DIFF_NETSENT_7!, keys %{$conf->{'provides_metrics'}} ), "Conf has provides_metrics > DIFF_NETSENT_7" );
ok( grep( m!PERCENTAGE_SENT_30!, keys %{$conf->{'provides_metrics'}} ), "Conf has provides_metrics > PERCENTAGE_SENT_30" );
ok( grep( m!PERCENTAGE_SENT_365!, keys %{$conf->{'provides_metrics'}} ), "Conf has provides_metrics > PERCENTAGE_SENT_365" );
ok( grep( m!PERCENTAGE_SENT_7!, keys %{$conf->{'provides_metrics'}} ), "Conf has provides_metrics > PERCENTAGE_SENT_7" );
ok( grep( m!SENT_RESPONSE!, keys %{$conf->{'provides_metrics'}} ), "Conf has provides_metrics > SENT_RESPONSE" );
ok( grep( m!THREADS!, keys %{$conf->{'provides_metrics'}} ), "Conf has provides_metrics > THREADS" );

ok( grep( m!metrics!, @{$conf->{'ability'}} ), "Conf has ability > metrics" );
ok( grep( m!data!, @{$conf->{'ability'}} ), "Conf has ability > data" );
ok( grep( m!recs!, @{$conf->{'ability'}} ), "Conf has ability > recs" );
ok( grep( m!figs!, @{$conf->{'ability'}} ), "Conf has ability > figs" );
ok( grep( m!viz!, @{$conf->{'ability'}} ), "Conf has ability > viz" );

ok( grep( m!project_grim!, keys %{$conf->{'params'}} ), "Conf has params > project_grim" );

ok( grep( m!MLS_SENT!, @{$conf->{'provides_recs'}} ), "Conf has provides_recs > mls_sent" );

ok( grep( m!eclipse_mls.html!, keys %{$conf->{'provides_viz'}} ), "Conf has provides_figs > eclipse_mls" );

# Execute the plugin
note( "Executing the plugin with tools.cdt project. ");
my $ret = $plugin->run_plugin("tools.cdt", { 'project_grim' => 'tools.cdt' } ); 
is( scalar grep( /MLS_SENT/, keys %{$ret->{'metrics'}} ), 5, "There should be 5 MLS_SENT_*." ) or diag explain $ret;
is( scalar grep( /MLS_SENDERS/, keys %{$ret->{'metrics'}} ), 5, "There should be 5 MLS_SENDERS_*.") or diag explain $ret;

ok( exists($ret->{'metrics'}{'MLS_SENDERS'}), "There should be a metric called MLS_SENDERS." ) or diag explain $ret;
ok( exists($ret->{'metrics'}{'MLS_SENDERS_7'}), "There should be a metric called MLS_SENDERS_7." ) or diag explain $ret;
ok( exists($ret->{'metrics'}{'MLS_SENDERS_30'}), "There should be a metric called MLS_SENDERS_30." ) or diag explain $ret;
ok( exists($ret->{'metrics'}{'MLS_SENDERS_365'}), "There should be a metric called MLS_SENDERS_365." ) or diag explain $ret;
ok( exists($ret->{'metrics'}{'MLS_SENT'}), "There should be a metric called MLS_SENT." ) or diag explain $ret;
ok( exists($ret->{'metrics'}{'MLS_SENT_7'}), "There should be a metric called MLS_SENT_7." ) or diag explain $ret;
ok( exists($ret->{'metrics'}{'MLS_SENT_30'}), "There should be a metric called MLS_SENT_30." ) or diag explain $ret;
ok( exists($ret->{'metrics'}{'MLS_SENT_365'}), "There should be a metric called MLS_SENT_365." ) or diag explain $ret;
ok( exists($ret->{'metrics'}{'MLS_SENDERS'}), "There should be a metric called MLS_SENDERS." ) or diag explain $ret;
ok( exists($ret->{'metrics'}{'MLS_SENDERS_7'}), "There should be a metric called MLS_SENDERS_7." ) or diag explain $ret;
ok( exists($ret->{'metrics'}{'MLS_SENDERS_30'}), "There should be a metric called MLS_SENDERS_30." ) or diag explain $ret;
ok( exists($ret->{'metrics'}{'MLS_SENDERS_365'}), "There should be a metric called MLS_SENDERS_365." ) or diag explain $ret;

# Check that files have been created.
note( "Check that files have been created. ");
ok( -e "projects/tools.cdt/input/tools.cdt_import_mls.json", "Check that file import_mls.json exists." );
ok( -e "projects/tools.cdt/input/tools.cdt_import_mls_evol.json", "Check that file import_mls_evol.json exists." );
ok( -e "projects/tools.cdt/output/tools.cdt_eclipse_mls.inc", "Check that file EclipseMls.inc exists." );
ok( -e "projects/tools.cdt/output/tools.cdt_import_mls.json", "Check that file import_mls.json exists." );
ok( -e "projects/tools.cdt/output/tools.cdt_mls_evol_people.html", "Check that file mls_evol_people.html exists." );
ok( -e "projects/tools.cdt/output/tools.cdt_mls_evol_sent.html", "Check that file mls_evol_sent.html exists." );
ok( -e "projects/tools.cdt/output/tools.cdt_mls_evol_summary.html", "Check that file mls_evol_summary.html exists." );
ok( -e "projects/tools.cdt/output/tools.cdt_metrics_mls.csv", "Check that file tools.cdt_metrics_mls.csv exists." );
ok( -e "projects/tools.cdt/output/tools.cdt_metrics_mls.json", "Check that file tools.cdt_metrics_mls.json exists." );
ok( -e "projects/tools.cdt/output/tools.cdt_metrics_mls_evol.csv", "Check that file tools.cdt_metrics_mls_evol.csv exists." );
ok( -e "projects/tools.cdt/output/tools.cdt_metrics_mls_evol.json", "Check that file tools.cdt_metrics_mls_evol.json exists." );


done_testing();
