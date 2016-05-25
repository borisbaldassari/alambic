#! perl -I../../lib/

use strict;
use warnings;

use Test::More;
use Data::Dumper;
use Mojo::JSON qw( decode_json);

BEGIN { use_ok( 'Alambic::Plugins::EclipseReport' ); }

my $plugin = Alambic::Plugins::EclipseReport->new();
isa_ok( $plugin, 'Alambic::Plugins::EclipseReport' );

my $ret = $plugin->run_post("tools.cdt", 
			    { 'data' => { 'project_pmi' => 'tools.cdt' }, 'metrics' => { 'MLS_M_1' => 3 } }
    );
print Dumper(@$ret);
#ok( $ret->{'info'}->{'id'} =~ m!tools.cdt$!, "Project from PMI has correct id." ) or diag explain $ret;

# Check that files have been created.
ok( -e "projects/tools.cdt/input/tools.cdt_import_pmi.json", "Check that file import_pmi.json exists." );
ok( -e "projects/tools.cdt/output/tools.cdt_pmi.json", "Check that file tools.cdt_metrics_pmi.json exists." );
ok( -e "projects/tools.cdt/output/tools.cdt_pmi_checks.json", "Check that file tools.cdt_metrics_pmi_checks.json exists." );


done_testing(17);
