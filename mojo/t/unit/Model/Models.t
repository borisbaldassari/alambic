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
	    'METRIC1' => 'METRIC1',
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

my $metr = $models->get_metric('METRIC1');
is_deeply( $metr, $metrics->{'METRIC1'}, "Single metric retrieved is ok." ) or diag explain $metr;

my $metrs = $models->get_metrics();
is_deeply( $metrs, $metrics, "Metrics retrieved are ok." ) or diag explain $metrs;

done_testing();
