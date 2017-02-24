#! perl -I../../lib/

use strict;
use warnings;

use Test::More;
use Mojo::JSON qw( decode_json);

BEGIN { use_ok( 'Alambic::Plugins::EclipsePmi' ); }

my $plugin = Alambic::Plugins::EclipsePmi->new();
isa_ok( $plugin, 'Alambic::Plugins::EclipsePmi' );

my $ret = $plugin->run_plugin("tools.cdt", { 'project_pmi' => 'tools.cdt' } );
ok( $ret->{'info'}->{'id'} =~ m!tools.cdt$!, "Project from PMI has correct id." ) or diag explain $ret;
is( $ret->{'info'}{'bugzilla_product'}, 'CDT', "Bugzilla product is CDT.") or diag explain $ret;
is( $ret->{'info'}{'title'}, 'C/C++ Development Tooling (CDT)', "PMI title is correct.") or diag explain $ret;
is( $ret->{'log'}[0], '[Plugins::EclipsePmi] Using Eclipse PMI infra at [https://projects.eclipse.org/json/project/tools.cdt].', "Checking first line of log.") or diag explain $ret;
is( $ret->{'metrics'}{'PMI_ITS_INFO'}, 5, "Metric PMI_ITS_INFO is 5.") or diag explain $ret;

# Check pmi checks
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
is( $json->{'id_pmi'}, 'tools.cdt', "Checks: id_pmi is ok." ) or diag explain $json->{'id_pmi'};
is( $json->{'pmi_url'}, 'https://projects.eclipse.org/json/project/tools.cdt', "Checks: pmi_url is ok." ) or diag explain $json->{'pmi_url'};
is( $json->{'name'}, 'C/C++ Development Tooling (CDT)', "Checks: name is ok." ) or diag explain $json->{'name'};

# now check checks themselves
is( $json->{'checks'}{'download_url'}{'value'}, 'http://www.eclipse.org/cdt/downloads.php', "Checks: download_url is ok." ) or diag explain $json->{'checks'}{'download_url'};
is( $json->{'checks'}{'website_url'}{'value'}, 'http://www.eclipse.org/cdt', "Checks: website_url is ok." ) or diag explain $json->{'checks'}{'website_url'};
is( $json->{'checks'}{'build_url'}{'results'}[0], 'Failed: could not get CI URL [].', "Checks: build_url is ok (empty)." ) or diag explain $json->{'checks'}{'build_url'};
is( $json->{'checks'}{'title'}{'value'}, 'C/C++ Development Tooling (CDT)', "Checks: title is ok." ) or diag explain $json->{'checks'}{'title'}{'value'};

# Check that files have been created.
ok( -e "projects/tools.cdt/input/tools.cdt_import_pmi.json", "Check that file import_pmi.json exists." );
ok( -e "projects/tools.cdt/output/tools.cdt_pmi.json", "Check that file tools.cdt_metrics_pmi.json exists." );
ok( -e "projects/tools.cdt/output/tools.cdt_pmi_checks.json", "Check that file tools.cdt_metrics_pmi_checks.json exists." );


done_testing(17);
