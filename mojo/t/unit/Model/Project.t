#! perl -I../../lib/

use strict;
use warnings;

use Alambic::Model::Models;
use Test::More;
use Data::Dumper;

BEGIN { use_ok( 'Alambic::Model::Project' ); }

my $plugins_conf = {
    "EclipseIts" => {
	"project_grim" => "tools.cdt",
    }
};

my $metrics = { 
    'ITS_CLOSED' => {
	'mnemo' => "ITS_CLOSED", "name" => "Its Closed", 
	"desc" => ["Desc"], "scale" => [1,2,3,4]
    } ,
    'ITS_CLOSERS' => {
	'mnemo' => "ITS_CLOSERS", "name" => "Its Closers", 
	"desc" => ["Desc"], "scale" => [1,2,3,4]
    } 
};
my $attributes = { 
    'ATTR1' => {
	'mnemo' => "ATTR1", "name" => "Attribute 1", "desc" => ["Desc"],
    }
};
my $qm = [ {'mnemo' => 'ATTR1', 'active' => 'true', 'type' => 'attribute', 'children' => [{'mnemo' => 'ITS_CLOSED', 'active' => 'true', 'type' => 'metric'}, {'mnemo' => 'ITS_CLOSERS', 'active' => 'true', 'type' => 'metric'}] } ];
my $plugins = {
    'EclipseIts' => {
	'provides_data' => {
	    'metrics_its.json' => 'Metrics for the ITS plugin (JSON).',
	},
	'params' => {
	    'project_grim' => '',
	},
	'provides_recs' => [
	    'ITS_CLOSE_BUGS',
	    ],
	'id' => 'EclipseIts',
	'name' => 'Eclipse ITS',
	'desc' => [
	    'Eclipse ITS retrieves bug tracking system data from the Eclipse dashboard repository. This plugin will look for a file named project-its-prj-static.json on <a href="http://dashboard.eclipse.org/data/json/">the Eclipse dashboard</a>. This plugin is redundant with the EclipseGrimoire plugin',
	],
	'ability' => [
	    'metrics',
	    'recs',
	    'figs',
	    'viz',
	],
	'provides_figs' => {
	    'its_evol_ggplot.rmd' => 'its_evol_ggplot.html',
        },
	'provides_viz' => {
	    'eclipse_its.html' => 'Eclipse ITS',
	},
	'provides_metrics' => {
	    'ITS_CLOSED' => 'ITS_CLOSED',
	    'ITS_CLOSERS' => 'ITS_CLOSERS',
	},
	'provides_cdata' => [],
	'provides_info' => [
	    'MLS_DEV',
	],
	'type' => 'pre',
    }
};
my $models = Alambic::Model::Models->new($metrics, $attributes, $qm, $plugins);

my $project = Alambic::Model::Project->new( 'tools.cdt', 'Tools CDT', 'TRUE', '', $plugins_conf );
isa_ok( $project, 'Alambic::Model::Project' );

my $id = $project->get_id();
ok( $id =~ m!^tools.cdt$!, 'Project id is tools.cdt.' ) or diag explain $id;

my $name = $project->get_name();
ok( $name =~ m!^Tools CDT$!, 'Project name is Tools CDT.' ) or diag explain $name;

note("Running EclipseIts plugin.");
my $ret = $project->run_plugin( 'EclipseIts' );
$ret = $ret->{'log'};
ok( grep( /^ERROR/, @{$ret} ) == 0, "Log has no error." ) or diag explain $ret;
ok( grep( /^\[Plugins::EclipseIts\] Starting retrieval/, @{$ret} ) == 1, "Log has Starting retrieval." ) or diag explain $ret;
ok( grep( /^\[Plugins::EclipseIts\] Retrieving static/, @{$ret} ) == 1, "Log has Retrieving static." ) or diag explain $ret;
ok( grep( /^\[Plugins::EclipseIts\] Retrieving evol/, @{$ret} ) == 1, "Log has Retrieving evol." ) or diag explain $ret;
ok( grep( /^\[Plugins::EclipseIts\] Executing R/, @{$ret} ) >= 1, "Log has Executing R." ) or diag explain $ret;

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

note("Run plugins.");

$ret = $project->run_plugins();
ok( exists($ret->{'metrics'}{'ITS_CLOSED'}), "ITS_CLOSED metrics exists in run after plugins." ) or diag explain $ret;
ok( exists($ret->{'metrics'}{'ITS_CLOSERS'}), "ITS_CLOSERS metrics exists in run after plugins." ) or diag explain $ret;
ok( grep( m!Retrieving static \[http://dashboard.eclipse.org/data/json/tools.cdt-its-prj-static.json\]!, @{$ret->{'log'}} ), "Log of run after plugins has info static url." ) or diag explain $ret;
ok( grep( m!Retrieving evol \[http://dashboard.eclipse.org/data/json/tools.cdt-its-prj-evolutionary.json\]!, @{$ret->{'log'}} ), "Log of run after plugins has evol url" ) or diag explain $ret;
ok( grep( /Executing R main file./, @{$ret->{'log'}} ), "Log of run after plugins has R main." ) or diag explain $ret;
ok( grep( /Executing R fig file \[its_evol_summary.rmd\]/, @{$ret->{'log'}} ), "Log of run after plugins has R fig." ) or diag explain $ret;

note("Run qm.");
$ret = $project->run_qm($models);
ok( grep( /Aggregating data/, @{$ret->{'log'}} ), "After qm run log has aggregating data." ) or diag explain $ret;
ok( exists($ret->{'attrs'}{'ATTR1'}), "After qm run attr1 is in ret." ) or diag explain $ret;
ok( exists($ret->{'inds'}{'ITS_CLOSED'}), "After qm run inds its_closed is in ret." ) or diag explain $ret;
ok( exists($ret->{'inds'}{'ITS_CLOSERS'}), "After qm run inds its_closers is in ret." ) or diag explain $ret;
ok( exists($ret->{'attrs_conf'}{'ATTR1'}), "After qm run attrs_conf is in ret." ) or diag explain $ret;
print Dumper $ret;

done_testing(38);
