#! perl -I../../lib/

#########################################################
#
# Copyright (c) 2015-2017 Castalia Solutions and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
#
# Contributors:
#   Boris Baldassari - Castalia Solutions
#
#########################################################


use strict;
use warnings;

use Mojo::Pg;
use Mojo::JSON qw(decode_json encode_json);
use Test::More;
use Data::Dumper;
use POSIX;

BEGIN { use_ok('Alambic::Model::RepoDB'); }

my $clean_db  = 1;
my $file_conf = "alambic.conf";
my $conf;
{
  open(my $fh, "<", $file_conf) or die "Could not open [$file_conf].\n";
  local $/;
  $conf = <$fh>;
  close $fh;
}

my $conf_e  = eval $conf;
my $conf_db = $conf_e->{'conf_pg_alambic_test'};

# If no database is defined, skip all tests.
my ($pg, $repodb, $is_init);
$pg     = Mojo::Pg->new($conf_db);
$repodb = Alambic::Model::RepoDB->new();
isa_ok($repodb, 'Alambic::Model::RepoDB');

$is_init = $repodb->is_db_defined();
is($is_init, 1, "DB is defined in module.");

SKIP: {
  my $version;
  eval { $version = $repodb->get_pg_version; };

  if ($@) {
    $clean_db = 0;
    skip 'Tests irrelevant when no database is defined.', 56;
  }


  like($version, qr/^PostgreSQL 9.5/, "Postgres has version 9.5.")
    or diag explain $version;

  my @tables;

  # We want to clean the db afterwards even if tests fail.
  eval {

    note("Initialising DB.");
    $repodb->init_db();

    my $is_ok = $repodb->is_db_ok();
    is($is_ok, 1, "DB is_ok is 1 so db has more than 1 table.");

    # Checking database.
    push(@tables, $_->{'tablename'})
      for $pg->db->query(
      "SELECT tablename FROM pg_catalog.pg_tables 
	      WHERE schemaname != 'pg_catalog' AND schemaname != 'information_schema';"
      )->hashes->each;
    is(scalar @tables, 10, "Database has 10 tables defined.")
      or diag explain @tables;
    ok(grep(/^conf$/, @tables) == 1, "Table conf is defined.")
      or diag explain @tables;
    ok(grep(/^projects_conf$/, @tables) == 1, "Table projects_conf is defined.")
      or diag explain @tables;
    ok(grep(/^projects_runs$/, @tables) == 1, "Table projects_runs is defined.")
      or diag explain @tables;
    ok(
      grep(/^projects_cdata$/, @tables) == 1,
      "Table projects_cdata is defined."
    ) or diag explain @tables;
    ok(grep(/^projects_info$/, @tables) == 1, "Table projects_info is defined.")
      or diag explain @tables;
    ok(
      grep(/^models_metrics$/, @tables) == 1,
      "Table models_metrics is defined."
    ) or diag explain @tables;
    ok(
      grep(/^models_attributes$/, @tables) == 1,
      "Table models_attributes is defined."
    ) or diag explain @tables;
    ok(grep(/^models_qms$/, @tables) == 1, "Table models_qms is defined.")
      or diag explain @tables;
    ok(grep(/^users$/, @tables) == 1, "Table users is defined.")
      or diag explain @tables;

    my %values;
    my $results = $pg->db->query('select * from conf');
    while (my $next = $results->hash) {
      $values{$next->{'param'}} = $next->{'val'};
    }
    is($values{'name'}, "MyDBNameInit", "Name in DB is MyDBNameInit.")
      or diag explain %values;
    is($values{'desc'}, "MyDBDescInit", "Desc in DB is MyDBDescInit.")
      or diag explain %values;

    my $name = $repodb->name();
    is($name, 'MyDBNameInit', "Name from module is MyDBNameInit.")
      or diag explain $name;
    my $desc = $repodb->desc();
    is($desc, 'MyDBDescInit', "Desc from module is MyDBDescInit.")
      or diag explain $name;

    # Check instance information.
    note("Check instance information.");

    $name = $repodb->name("OtherName");
    is($name, 'OtherName', "Name set from module is OtherName.")
      or diag explain $name;
    $desc = $repodb->desc("OtherDesc");
    is($desc, 'OtherDesc', "Desc set from module is OtherDesc.")
      or diag explain $desc;

    $name = $repodb->name();
    is($name, 'OtherName', "Name from module is OtherName.")
      or diag explain $name;
    $desc = $repodb->desc();
    is($desc, 'OtherDesc', "Desc from module is OtherDesc.")
      or diag explain $desc;

    $name = $repodb->name("MyDBNameInit");
    is($name, 'MyDBNameInit', "Name set from module is MyDBNameInit.")
      or diag explain $name;
    $desc = $repodb->desc("MyDBDescInit");
    is($desc, 'MyDBDescInit', "Desc set from module is MyDBDescInit.")
      or diag explain $desc;

    $name = $repodb->name();
    is($name, 'MyDBNameInit', "Name from module is MyDBNameInit.")
      or diag explain $name;
    $desc = $repodb->desc();
    is($desc, 'MyDBDescInit', "Desc from module is MyDBDescInit.")
      or diag explain $desc;


    my $metric = $repodb->get_metrics();
    is_ok(ref($metric) =~ m!^HASH$!,
      "get_metrics() Get all metrics returns empty hash when there is none.")
      or diag explain $metric;

    note("Adding metric through sql.");
    @tables = ();
    push(@tables, $_->{'tablename'})
      for $pg->db->query(
      "SELECT tablename FROM pg_catalog.pg_tables 
	      WHERE schemaname != 'pg_catalog' AND schemaname != 'information_schema';"
      )->hashes->each;
    is(scalar @tables, 10, "Database has still 10 tables defined.")
      or diag explain @tables;

    my ($mnemo, $scale, $ret);
    ($mnemo, $name, $desc, $scale)
      = ('mnemo', 'name', encode_json(['desc']), encode_json([1, 2, 3, 4]));
    my $query
      = "INSERT INTO models_metrics (mnemo, name, description, scale) VALUES "
      . "(?, ?, ?, ?) ON CONFLICT (mnemo) DO UPDATE SET (mnemo, name, description, scale) "
      . "= (?, ?, ?, ?)";
    eval {
      $ret
        = $pg->db->query($query,
        ($mnemo, $name, $desc, $scale, $mnemo, $name, $desc, $scale));
    };
    ok($@ eq '', "Add a metric through sql.");

    eval {
      $metric
        = $repodb->set_metric('METRIC1', 'Metric 1', ['description'],
        [1, 2, 3, 4]);
    };
    ok($@ eq '', "Add a metric through set_metric.");

    my $metric_ref = {
      'METRIC1' => {
        'scale'       => [1, 2, 3, 4],
        'description' => ['description'],
        'name'        => 'Metric 1',
        'mnemo'       => 'METRIC1'
      },
      'mnemo' => {
        'scale'       => [1, 2, 3, 4],
        'description' => ['desc'],
        'name'        => 'name',
        'mnemo'       => 'mnemo'
      }
    };

    $metric = $repodb->get_metric('METRIC1');
    is_deeply(
      $metric->{'METRIC1'},
      $metric_ref->{'METRIC1'},
      "get_metrics() Get all metrics returns METRIC1."
    ) or diag explain $metric;

    # Check projects_conf information
    note("Check projects_conf information.");
    $ret
      = $repodb->set_project_conf('modeling.sirius', 'Sirius',
      'Sirius is a great tool.',
      0, '{}');
    ok($ret == 1, "First update of project_info returns 1.")
      or diag explain $ret;

    my $ret_ok = {
      'desc'      => 'Sirius is a great tool.',
      'name'      => 'Sirius',
      'is_active' => 0,
      'last_run'  => '',
      'plugins'   => '{}'
    };
    $ret = $repodb->get_project_conf('modeling.sirius');
    is_deeply($ret, $ret_ok,
      "Get project has correct name, desc and empty plugins.")
      or diag explain $ret;

    $ret = $repodb->get_project_conf('wrong.project');
    is($ret, undef, "Getting a wrong project returns undef.");

    my $projects_list = $repodb->get_projects_list();
    is($projects_list->{'modeling.sirius'},
      "Sirius", "Projects list has modeling.sirius.")
      or diag explain $projects_list;

    $ret
      = $repodb->set_project_conf('modeling.sirius', 'SiriusChanged',
      'Sirius is a great tool Changed.',
      '0', '{ "EclipseIts": {"project_grim": "modeling.sirius"} }');
    ok($ret == 1, "Second update of project_info is an update.")
      or diag explain $ret;

    $ret_ok = {
      'desc'      => 'Sirius is a great tool Changed.',
      'name'      => 'SiriusChanged',
      'last_run'  => '',
      'is_active' => 0,
      'plugins'   => '{ "EclipseIts": {"project_grim": "modeling.sirius"} }'
    };
    $ret = $repodb->get_project_conf('modeling.sirius');
    is_deeply($ret, $ret_ok, "Get project has correct name, desc and plugins.")
      or diag explain $ret;

    # Check projects_run information
    note("Check projects_run information.");
    my $run_time = strftime("%Y-%m-%d %H:%M:%S\n", localtime(time));
    $ret = $repodb->add_project_run(
      'modeling.sirius',
      {"timestamp" => "$run_time", "delay" => 13, "user" => "none"},
      {'WEBSITE'     => "http://www.example.com"},
      {'MYMETRIC'    => 5},
      {'MYINDIC'     => 6},
      {'MYATTR'      => 8},
      {'MYATTR_CONF' => "1 / 2"},
      [{'MYREC' => {'rid' => 'REC_PMI_1', 'desc' => 'This is a description.'}}]
    );
    ok($ret > 0, "Adding project run returns a non-null id ($ret).");

    $results = $repodb->get_project_last_run('modeling.sirius');
    is_deeply(
      $results->{'metrics'},
      {'MYMETRIC' => 5},
      "Metrics retrieved from last run are ok."
    ) or diag explain $results;
    is_deeply(
      $results->{'indicators'},
      {'MYINDIC' => 6},
      "Indicators retrieved from last run are ok."
    ) or diag explain $results;
    is_deeply(
      $results->{'attributes'},
      {'MYATTR' => 8},
      "Attributes retrieved from last run are ok."
    ) or diag explain $results;
    is_deeply(
      $results->{'attributes_conf'},
      {'MYATTR_CONF' => "1 / 2"},
      "Attributes conf retrieved from last run are ok."
    ) or diag explain $results;
    is_deeply(
      $results->{'recs'},
      [
        {
          'MYREC' => {'rid' => 'REC_PMI_1', 'desc' => 'This is a description.',}
        }
      ],
      "Recs retrieved from last run are ok."
    ) or diag explain $results;

    my $getinfo = $repodb->get_info('modeling.sirius');
    is_deeply(
      $getinfo->{'info'},
      {'WEBSITE' => "http://www.example.com"},
      "Get info returns website."
    ) or diag explain $getinfo;

    # Second run
    $run_time = strftime("%Y-%m-%d %H:%M:%S\n", localtime(time));
    $ret = $repodb->add_project_run(
      'modeling.sirius',
      {"timestamp" => "$run_time", "delay" => 113, "user" => "none"},
      {'WEBSITE'     => "http://www.example.com"},
      {'MYMETRIC'    => 15},
      {'MYINDIC'     => 16},
      {'MYATTR'      => 18},
      {'MYATTR_CONF' => "10 / 20"},
      [
        {
          'MYREC' => {'rid' => 'REC_PMI_11', 'desc' => 'This is a description.'}
        }
      ]
    );
    ok($ret > 0, "Adding project run returns a non-null id ($ret).");

    $results = $repodb->get_project_last_run('modeling.sirius');
    is_deeply(
      $results->{'metrics'},
      {'MYMETRIC' => 15},
      "Metrics retrieved from last run are ok."
    ) or diag explain $results;
    is_deeply(
      $results->{'indicators'},
      {'MYINDIC' => 16},
      "Indicators retrieved from last run are ok."
    ) or diag explain $results;
    is_deeply(
      $results->{'attributes'},
      {'MYATTR' => 18},
      "Attributes retrieved from last run are ok."
    ) or diag explain $results;
    is_deeply(
      $results->{'attributes_conf'},
      {'MYATTR_CONF' => "10 / 20"},
      "Attributes conf retrieved from last run are ok."
    ) or diag explain $results;
    is_deeply(
      $results->{'recs'},
      [
        {
          'MYREC' => {'rid' => 'REC_PMI_11', 'desc' => 'This is a description.'}
        }
      ],
      "Recs retrieved from last run are ok."
    ) or diag explain $results;

    $results = $repodb->get_project_all_runs('modeling.sirius');
    is(scalar @$results, 2, "Get all runs has two entries.")
      or diag explain $results;
    my $runs_ref = [
      {
        'id'         => 2,
        'project_id' => 'modeling.sirius',
        'run_delay'  => 113,
        'run_time'   => '2016-05-08 16:53:57',
        'run_user'   => 'none'
      },
      {
        'id'         => 1,
        'project_id' => 'modeling.sirius',
        'run_delay'  => 13,
        'run_time'   => '2016-05-08 16:53:57',
        'run_user'   => 'none'
      }
    ];
    is($runs_ref->[0]->{'id'}, 2, "First row has 2 as id.")
      or diag explain $results;
    is($runs_ref->[0]->{'project_id'},
      'modeling.sirius', "First row has modeling.sirius as project_id.")
      or diag explain $results;
    is($runs_ref->[0]->{'run_delay'}, 113, "First row has 113 as run_delay.")
      or diag explain $results;

    $results = $repodb->delete_project('modeling.sirius');
    is($results, 1, "Delete project returns 1.");

    $projects_list = $repodb->get_projects_list();
    ok(scalar grep(/modeling.sirius/, keys %$projects_list) == 0,
      "Projects list does not contain sirius.")
      or diag explain $projects_list;

    $repodb->clean_db() if $clean_db;
    @tables = ();
    push(@tables, $_->{'tablename'})
      for $pg->db->query(
      "SELECT tablename FROM pg_catalog.pg_tables 
	      WHERE schemaname != 'pg_catalog' AND schemaname != 'information_schema';"
      )->hashes->each;
    is(scalar @tables, 1, "Database has 1 tables defined after clean_db.")
      or diag explain @tables;
  };

  END {
    # Clean database, re-init tables.
    $repodb->clean_db() if $clean_db;
  }
}

done_testing();
