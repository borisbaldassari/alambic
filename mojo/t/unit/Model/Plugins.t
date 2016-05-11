#! perl -I../../lib/

use strict;
use warnings;

use Data::Dumper;
use Test::More;
use File::Path qw(remove_tree);

BEGIN { use_ok( 'Alambic::Model::Plugins' ); }

my $plugins = Alambic::Model::Plugins->new();
isa_ok( $plugins, 'Alambic::Model::Plugins' );

my $list = $plugins->get_names_all();
my $pv = 3;
ok( scalar(keys %{$list}) == $pv, "Plugin list has $pv entries." ) or diag explain @$list;

# Check plugins types
$list = $plugins->get_list_plugins_pre();
$pv = 2;
ok( scalar(@{$list}) == $pv, "List pre has $pv entries." ) or explain diag @$list;

$list = $plugins->get_list_plugins_cdata();
$pv = 1;
ok( scalar(@{$list}) == $pv, "List cdata has $pv entries." ) or explain diag @$list;

$list = $plugins->get_list_plugins_post();
$pv = 0;
ok( scalar(@{$list}) == $pv, "List post has $pv entries." ) or explain diag @$list;

$list = $plugins->get_list_plugins_global();
$pv = 0;
ok( scalar(@{$list}) == $pv, "List global has $pv entries." ) or explain diag @$list;

# Check plugins ability
$list = $plugins->get_list_plugins_data();
$pv = 1;
ok( scalar @{$list} == $pv, "List data has $pv entries." ) or explain diag @$list;

$list = $plugins->get_list_plugins_metrics();
$pv = 3;
ok( scalar @{$list} == $pv, "List metrics has $pv entries." ) or explain diag @$list;

$list = $plugins->get_list_plugins_figs();
$pv = 1;
ok( scalar(@{$list}) == $pv, "List figs has $pv entries." ) or explain diag @$list;

$list = $plugins->get_list_plugins_info();
$pv = 1;
ok( scalar(@{$list}) == $pv, "List info has $pv entries." ) or explain diag @$list;

$list = $plugins->get_list_plugins_recs();
$pv = 2;
ok( scalar(@{$list}) == $pv, "List recs has $pv entries." ) or explain diag @$list;

$list = $plugins->get_list_plugins_viz();
$pv = 3;
ok( scalar(@{$list}) == $pv, "List viz has $pv entries." ) or explain diag @$list;

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


done_testing(13);
