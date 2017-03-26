#! perl -I../../lib/

use strict;
use warnings;

use Data::Dumper;
use Test::More;
use File::Path qw(remove_tree);

BEGIN { use_ok('Alambic::Model::Models'); }

my $metrics = {
  'METRIC1' => {
    'mnemo' => "METRIC1",
    "name"  => "Metric 1",
    "desc"  => ["Desc"],
    "scale" => [1, 2, 3, 4]
  }
};
my $attributes
  = {
  'ATTR1' => {'mnemo' => "ATTR1", "name" => "Attribute 1", "desc" => ["Desc"],}
  };
my $qm = [
  {
    'mnemo'    => 'ATTR1',
    'type'     => 'attribute',
    'children' => [{'mnemo' => 'METRIC1', 'type' => 'metric'}]
  }
];
my $plugins = {
  'EclipseIts' => {
    'provides_data' =>
      {'metrics_its.json' => 'Metrics for the ITS plugin (JSON).',},
    'params'        => {'project_grim' => '',},
    'provides_recs' => ['ITS_CLOSE_BUGS',],
    'id'            => 'EclipseIts',
    'name'          => 'Eclipse ITS',
    'desc'          => ['Eclipse ITS description',],
    'ability' => ['metrics', 'recs', 'figs', 'viz',],
    'provides_figs'    => {'its_evol_ggplot.rmd' => 'its_evol_ggplot.html',},
    'provides_viz'     => {'eclipse_its.html'    => 'Eclipse ITS',},
    'provides_metrics' => {'METRIC1'             => 'METRIC1',},
    'provides_cdata'   => [],
    'provides_info'    => ['MLS_DEV',],
    'type'             => 'pre',
  }
};


my $models = Alambic::Model::Models->new($metrics, $attributes, $qm, $plugins);
isa_ok($models, 'Alambic::Model::Models');

my $qm_full     = $models->get_qm_full();
my $qm_full_ref = {
  'children' => [
    {
      'ind'      => undef,
      'children' => [
        {
          'ind'    => undef,
          'value'  => '0',
          'father' => 'ATTR1',
          'type'   => 'metric',
          'mnemo'  => 'METRIC1',
          'name'   => 'Metric 1'
        }
      ],
      'name'  => 'Attribute 1',
      'type'  => 'attribute',
      'mnemo' => 'ATTR1'
    }
  ],
  'version' => 'Sun Dec 25 15:55:41 2016',
  'name'    => 'Alambic Full Quality Model'
};
is_deeply(
  $qm_full->{'children'},
  $qm_full_ref->{'children'},
  "Full QM children tree is conform."
) or diag explain $qm_full->{'children'};
is($qm_full->{'name'}, $qm_full_ref->{'name'}, "Full QM name is conform.")
  or diag explain $qm_full->{'name'};

my $metr = $models->get_metric('METRIC1');
is_deeply($metr, $metrics->{'METRIC1'}, "Single metric retrieval is ok.")
  or diag explain $metr;

my $metrs = $models->get_metrics();
is_deeply($metrs, $metrics, "Metrics retrieved are ok.") or diag explain $metrs;

my $metrs_f = $models->get_metrics_full();
is_deeply($metrs_f->{'children'}{'METRIC1'}{'desc'},
  ['Desc'], "Get full metrics children tree is conform on desc.")
  or diag explain $metrs_f;
is_deeply(
  $metrs_f->{'children'}{'METRIC1'}{'parents'},
  {'ATTR1' => 1},
  "Get full metrics children tree is conform on parents."
) or diag explain $metrs_f;
is($metrs_f->{'name'}, "Alambic Metrics", "Full metrics name is conform.")
  or diag explain $metrs_f->{'name'};

my $metrs_a = $models->get_metrics_active();
is_deeply($metrs_a, ['METRIC1'], "Only one active metric is defined (METRIC1).")
  or diag explain $metrs_a;

my $metrs_r = $models->get_metrics_repos();
is_deeply(
  $metrs_r,
  {'EclipseIts' => 1},
  "get_metrics_repos is ok: one repository containing 1 metric."
) or diag explain $metrs_r;

my $attr = $models->get_attribute('ATTR1');
is_deeply($attr, $attributes->{'ATTR1'}, "Single attribute retrieval is ok.")
  or diag explain $metr;

my $attrs = $models->get_attributes();
is_deeply($attrs, $attributes, "Attributes retrieved are ok.")
  or diag explain $attrs;

my $attrs_f = $models->get_attributes_full();
is_deeply($attrs_f->{'children'}{'ATTR1'}{'desc'},
  ['Desc'], "Get full attributes children tree is conform on desc.")
  or diag explain $attrs_f;
is_deeply($attrs_f->{'children'}{'ATTR1'}{'name'},
  'Attribute 1', "Get full attributes children tree is conform on name.")
  or diag explain $attrs_f;
is($attrs_f->{'name'}, "Alambic Attributes", "Full attributes name is conform.")
  or diag explain $attrs_f->{'name'};

$qm = $models->get_qm();
my $qm_ref = [
  {
    'children' => [
      {
        'mnemo'  => 'METRIC1',
        'ind'    => undef,
        'type'   => 'metric',
        'value'  => '0',
        'name'   => 'Metric 1',
        'father' => 'ATTR1'
      }
    ],
    'mnemo' => 'ATTR1',
    'type'  => 'attribute',
    'ind'   => undef,
    'name'  => 'Attribute 1'
  }
];
is_deeply($qm, $qm_ref, "Quality model retrieval is ok.") or diag explain $qm;


my $models_ = Alambic::Model::Models->new();
$models->init_models($metrics, $attributes, $qm, $plugins);
isa_ok($models, 'Alambic::Model::Models');

$attrs = $models->get_attributes();
is_deeply($attrs, $attributes, "Attributes retrieved are ok.")
  or diag explain $attrs;

$metr = $models->get_metric('METRIC1');
is_deeply($metr, $metrics->{'METRIC1'}, "Single metric retrieved is ok.")
  or diag explain $metr;

$metrs = $models->get_metrics();
is_deeply($metrs, $metrics, "Metrics retrieved are ok.") or diag explain $metrs;

done_testing();
