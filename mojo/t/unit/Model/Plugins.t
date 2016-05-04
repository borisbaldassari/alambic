#! perl -I../../lib/

use strict;
use warnings;

use Test::More;
use File::Path qw(remove_tree);

BEGIN { use_ok( 'Alambic::Model::Plugins' ); }

my $plugins = Alambic::Model::Plugins->new();
isa_ok( $plugins, 'Alambic::Model::Plugins' );

my $list = $plugins->get_list_all();
my $pv = 2;
ok( scalar @{$list} == $pv, "Plugin list has $pv entries." ) or diag explain $list;

note( "Loading EclipsePmi plugin." );
my $plugin_pmi = $plugins->get_plugin("EclipsePmi");
my $conf_pmi = $plugin_pmi->get_conf();
ok( $conf_pmi->{'id'} =~ m!EclipsePmi$!, "Eclipse PMI plugin has correct id." ) or diag explain $conf_pmi;
ok( $conf_pmi->{'name'} =~ m!Eclipse PMI$!, "Eclipse PMI plugin has correct name." ) or diag explain $conf_pmi;

note( "Executing EclipsePmi run_plugin without project_pmi." );
my $ret = $plugins->run_plugin( 'tools.cdt', 'EclipsePmi', {'project_pmi' => 'tools.cdt'} );
is( $ret->{'info'}{'bugzilla_product'}, 'CDT', "Bugzilla product is CDT.") or diag explain $ret;
is( $ret->{'info'}{'title'}, 'C/C++ Development Tooling (CDT)', "PMI title is correct.") or diag explain $ret;
is( $ret->{'log'}[0], '[Plugins::EclipsePmi] Using Eclipse PMI infra at [https://projects.eclipse.org/json/project/tools.cdt].', "Checking first line of log.") or diag explain $ret;
is( $ret->{'metrics'}{'PMI_ITS_INFO'}, 5, "Metric PMI_ITS_INFO is 5.") or diag explain $ret;

note( "Executing EclipsePmi run_plugin with project_pmi." );
$ret = $plugins->run_plugin( 'tools.cdt', 'EclipsePmi', {} );
is( $ret->{'info'}{'bugzilla_product'}, 'CDT', "Bugzilla product is CDT.") or diag explain $ret;
is( $ret->{'info'}{'title'}, 'C/C++ Development Tooling (CDT)', "PMI title is correct.") or diag explain $ret;
is( $ret->{'log'}[0], '[Plugins::EclipsePmi] Using Eclipse PMI infra at [https://projects.eclipse.org/json/project/tools.cdt].', "Checking first line of log.") or diag explain $ret;
is( $ret->{'metrics'}{'PMI_ITS_INFO'}, 5, "Metric PMI_ITS_INFO is 5.") or diag explain $ret;


#remove_tree('projects/tools.cdt');

done_testing(13);
