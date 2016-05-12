#! perl -I../../lib/

use strict;
use warnings;

use Data::Dumper;
use Test::More;
use File::Path qw(remove_tree);

BEGIN { use_ok( 'Alambic::Model::Models' ); }

my $metrics = { 
    'METRIC1' => {
	'mnemo' => "METRIC1", "name" => "Metric 1", 
	"desc" => ["Desc"], "scale" => [1,2,3,4]
    } 
};
my $attributes = { 
    'ATTR1' => {
	'mnemo' => "ATTR1", "name" => "Attribute 1", "desc" => ["Desc"],
    }
};
my $qm = [ {'mnemo' => 'ATTR1', 'type' => 'attribute', 'children' => [{'mnemo' => 'METRIC1', 'type' => 'metric'}]} ];
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
	    'ITS_WATCH_BUGS',
	    ],
	'id' => 'EclipseIts',
	'name' => 'Eclipse ITS',
	'desc' => [
	    'Eclipse ITS retrieves bug tracking system data from the Eclipse dashboard repository. This plugin will look for a file named project-its-prj-static.json on <a href="http://dashboard.eclipse.org/data/json/">the Eclipse dashboard</a>. This plugin is redundant with the EclipseGrimoire plugin',
	    '<code>project_grim</code> is the id used to identified the project in the PMI. Look for it in the URL of the project on <a href="http://projects.eclipse.org">http://projects.eclipse.org</a>.',
	    'See <a href="https://bitbucket.org/BorisBaldassari/alambic/wiki/Plugins/3.x/EclipseIts">the project\'s wiki</a> for more information.',
	],
	'ability' => [
	    'metrics',
	    'recs',
	    'figs',
	    'viz',
	],
	'provides_figs' => {
	    'its_evol_ggplot.rmd' => 'its_evol_ggplot.html',
	    'its_evol_changed.rmd' => 'its_evol_changed.html',
	    'its_evol_summary.rmd' => 'its_evol_summary.html',
	    'its_evol_people.rmd' => 'its_evol_people.html',
	    'its_evol_opened.rmd' => 'its_evol_opened.html',
        },
	'provides_viz' => {
	    'eclipse_its.html' => 'Eclipse ITS',
	},
	'provides_metrics' => {
	    'PERCENTAGE_CLOSERS_7' => 'ITS_PERCENTAGE_CLOSERS_7',
	    'CHANGERS' => 'ITS_CHANGERS',
	    'CLOSED' => 'ITS_CLOSED',
	    'DIFF_NETCLOSERS_365' => 'ITS_DIFF_NETCLOSERS_365',
	    'OPENED' => 'ITS_OPENED',
	    'TRACKERS' => 'ITS_TRACKERS',
	    'DIFF_NETCLOSED_30' => 'ITS_DIFF_NETCLOSED_30',
	    'PERCENTAGE_CLOSED_7' => 'ITS_PERCENTAGE_CLOSED_7',
	    'DIFF_NETCLOSERS_7' => 'ITS_DIFF_NETCLOSERS_7',
	    'DIFF_NETCLOSED_7' => 'ITS_DIFF_NETCLOSED_7',
	    'CLOSERS_30' => 'ITS_CLOSERS_30',
	    'PERCENTAGE_CLOSED_365' => 'ITS_PERCENTAGE_CLOSED_365',
	    'CLOSERS_365' => 'ITS_CLOSERS_365',
	    'PERCENTAGE_CLOSED_30' => 'ITS_PERCENTAGE_CLOSED_30',
	    'PERCENTAGE_CLOSERS_30' => 'ITS_PERCENTAGE_CLOSERS_30',
	    'PERCENTAGE_CLOSERS_365' => 'ITS_PERCENTAGE_CLOSERS_365',
	    'DIFF_NETCLOSED_365' => 'ITS_DIFF_NETCLOSED_365',
	    'DIFF_NETCLOSERS_30' => 'ITS_DIFF_NETCLOSERS_30',
	    'CLOSED_7' => 'ITS_CLOSED_7',
	    'OPENERS' => 'ITS_OPENERS',
	    'CLOSED_30' => 'ITS_CLOSED_30',
	    'CHANGED' => 'ITS_CHANGED',
	    'CLOSED_365' => 'ITS_CLOSED_365',
	    'CLOSERS_7' => 'ITS_CLOSERS_7',
	    'CLOSERS' => 'ITS_CLOSERS',
	},
	'provides_cdata' => [],
	'provides_info' => [
	    'MLS_DEV',
	],
	'type' => 'pre',
    }
};
    
    
my $models = Alambic::Model::Models->new($metrics, $attributes, $qm, $plugins);
isa_ok( $models, 'Alambic::Model::Models' );

my $attrs = $models->get_attributes();
is_deeply( $attrs, $attributes, "Attributes retrieved are ok." ) or diag explain $attrs;

my $metrs = $models->get_metrics();
is_deeply( $metrs, $metrics, "Metrics retrieved are ok." ) or diag explain $metrs;

done_testing();
