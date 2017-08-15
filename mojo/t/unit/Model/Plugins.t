#! perl -I../../lib/

use strict;
use warnings;

use Data::Dumper;
use Test::More;
use File::Path qw(remove_tree);

BEGIN { use_ok('Alambic::Model::Plugins'); }

my $plugins = Alambic::Model::Plugins->new();
isa_ok($plugins, 'Alambic::Model::Plugins');

my $list = $plugins->get_names_all();
my $pv   = 6;
ok(scalar(keys %{$list}) == $pv,
  "get_names_all there is a total of $pv plugins detected.")
  or explain %$list;

$list = $plugins->get_conf_all();
ok(scalar(keys %{$list}) == $pv, "get_conf_all has $pv entries.")
  or explain Dumper %$list;

# Check plugins types
$list = $plugins->get_list_plugins_pre();
$pv   = 5;
ok(scalar(@{$list}) == $pv, "get_list_plugins_pre List pre has $pv entries.")
  or explain Dumper @$list;

$list = $plugins->get_list_plugins_cdata();
$pv   = 0;
ok(scalar(@{$list}) == $pv,
  "get_list_plugins_cdata List cdata has $pv entries.")
  or explain Dumper @$list;

$list = $plugins->get_list_plugins_post();
$pv   = 1;
ok(scalar(@{$list}) == $pv, "get_list_plugins_post List post has $pv entries.")
  or explain Dumper @$list;

$list = $plugins->get_list_plugins_global();
$pv   = 0;
ok(scalar(@{$list}) == $pv,
  "get_list_plugins_global List global has $pv entries.")
  or explain Dumper @$list;

# Check plugins ability
$list = $plugins->get_list_plugins_data();
$pv   = 3;
ok(scalar @{$list} == $pv, "List data has $pv entries.")
  or explain Dumper @$list;

$list = $plugins->get_list_plugins_metrics();
$pv   = 4;
ok(scalar @{$list} == $pv, "List metrics has $pv entries.")
  or explain Dumper @$list;

$list = $plugins->get_list_plugins_figs();
$pv   = 4;
ok(scalar(@{$list}) == $pv, "List figs has $pv entries.")
  or explain Dumper @$list;

$list = $plugins->get_list_plugins_info();
$pv   = 2;
ok(scalar(@{$list}) == $pv, "List info has $pv entries.")
  or explain Dumper @$list;

$list = $plugins->get_list_plugins_recs();
$pv   = 5;
ok(scalar(@{$list}) == $pv, "List recs has $pv entries.")
  or explain Dumper @$list;

$list = $plugins->get_list_plugins_viz();
$pv   = 6;
ok(scalar(@{$list}) == $pv, "List viz has $pv entries.")
  or explain Dumper @$list;

note("Loading EclipsePmi plugin.");
my $plugin_pmi = $plugins->get_plugin("EclipsePmi");
my $conf_pmi   = $plugin_pmi->get_conf();
ok($conf_pmi->{'id'} =~ m!EclipsePmi$!, "Eclipse PMI plugin has correct id.")
  or Dumper explain $conf_pmi;
ok(
  $conf_pmi->{'name'} =~ m!Eclipse PMI$!,
  "Eclipse PMI plugin has correct name."
) or Dumper explain $conf_pmi;

note("Executing EclipsePmi run_plugin without project_pmi.");
my $ret = $plugins->run_plugin('tools.cdt', 'EclipsePmi',
  {'project_pmi' => 'tools.cdt'});
is($ret->{'info'}{'PMI_BUGZILLA_PRODUCT'}, 'CDT', "Bugzilla product is CDT.")
  or Dumper explain $ret;
is(
  $ret->{'info'}{'PMI_TITLE'},
  'Eclipse C/C++ Development Tooling (CDT)',
  "PMI title is correct."
) or Dumper explain $ret;
is(
  $ret->{'log'}[0],
  '[Plugins::EclipsePmi] Using Eclipse PMI infra at [https://projects.eclipse.org/json/project/tools.cdt].',
  "Checking first line of log: using eclipse pmi infra at..."
) or Dumper explain $ret;
is($ret->{'metrics'}{'PMI_ITS_INFO'}, 5, "Metric PMI_ITS_INFO is 5.")
  or Dumper explain $ret;

note("Executing EclipsePmi run_plugin with project_pmi.");
$ret = $plugins->run_plugin('tools.cdt', 'EclipsePmi', {});
is($ret->{'info'}{'PMI_BUGZILLA_PRODUCT'}, 'CDT', "Bugzilla product is CDT.")
  or Dumper explain $ret;
is(
  $ret->{'info'}{'PMI_TITLE'},
  'Eclipse C/C++ Development Tooling (CDT)',
  "PMI title is correct."
) or Dumper explain $ret;
is(
  $ret->{'log'}[0],
  '[Plugins::EclipsePmi] Using Eclipse PMI infra at [https://projects.eclipse.org/json/project/tools.cdt].',
  "Checking first line of log."
) or Dumper explain $ret;
is($ret->{'metrics'}{'PMI_ITS_INFO'}, 5, "Metric PMI_ITS_INFO is 5.")
  or Dumper explain $ret;


#note( "Loading EclipseReport post plugin." );
#my $plugin_report = $plugins->get_plugin("EclipseReport");
#my $conf_report = $plugin_report->get_conf();
#ok( $conf_report->{'id'} eq 'EclipseReport', 'Check name of post plugin.') or Dumper $conf_report;
#is_deeply( $conf_report->{'provides_data'}, {'EclipseReport.pdf' => 'A PDF report on the project\'s current status.'}, 'Check provided data of post plugin.') or Dumper $conf_report;

#$ret = $plugins->run_post( 'tools.cdt', 'EclipseReport', {'project_id' => 'tools.cdt'} );
#print Dumper($ret);


done_testing(24);
