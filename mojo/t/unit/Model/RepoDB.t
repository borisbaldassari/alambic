#! perl -I../../lib/

use strict;
use warnings;

use Mojo::Pg;
use Test::More;
use Data::Dumper;
use POSIX;

BEGIN { use_ok( 'Alambic::Model::RepoDB' ); }

my $clean_db = 1;

my $pg = Mojo::Pg->new('postgresql://alambic:pass4alambic@/alambic_db');

my $repodb = Alambic::Model::RepoDB->new();
isa_ok( $repodb, 'Alambic::Model::RepoDB' );

my $is_init = $repodb->is_db_defined();
is( $is_init, 1, "DB is defined in module.");

my $version = $repodb->get_pg_version;
like( $version, qr/^PostgreSQL 9.4/, "Postgres has version 9.4." ) or diag explain $version;

my @tables;

# We want to clean the db afterwards even if tests fail.
eval {
    
    note( "Initialising DB." );
    $repodb->init_db();

    my $is_ok = $repodb->is_db_ok();
    is( $is_ok, 1, "DB is_ok has more than 1 table.");

    # Checking database.
    push( @tables, $_->{'tablename'} ) for $pg->db->query("SELECT tablename FROM pg_catalog.pg_tables 
      WHERE schemaname != 'pg_catalog' AND schemaname != 'information_schema';")->hashes->each;
    is( scalar @tables, 4, "Database has 4 tables defined.") or diag explain @tables;
    ok( grep( /^conf$/, @tables ) == 1, "Table conf is defined.") or diag explain @tables;
    ok( grep( /^conf_projects$/, @tables ) == 1, "Table conf_projects is defined.") or diag explain @tables;
    ok( grep( /^projects$/, @tables ) == 1, "Table projects is defined.") or diag explain @tables;
    
    my %values;
    my $results = $pg->db->query('select * from conf');
    while (my $next = $results->hash) { 
	$values{ $next->{'param'} } = $next->{'val'}; 
    }
    is( $values{'name'}, "MyDBNameInit", "Name in DB is MyDBNameInit." ) or diag explain %values;
    is( $values{'desc'}, "MyDBDescInit", "Desc in DB is MyDBDescInit." ) or diag explain %values;
    
    my $name = $repodb->name();
    is( $name, 'MyDBNameInit', "Name from module is MyDBNameInit." ) or diag explain $name;
    my $desc = $repodb->desc();
    is( $desc, 'MyDBDescInit', "Desc from module is MyDBDescInit." ) or diag explain $name;

    # Check instance information.
    note( "Check instance information." );

    $name = $repodb->name("OtherName");
    is( $name, 'OtherName', "Name set from module is OtherName." ) or diag explain $name;
    $desc = $repodb->desc("OtherDesc");
    is( $desc, 'OtherDesc', "Desc set from module is OtherDesc." ) or diag explain $desc;

    $name = $repodb->name();
    is( $name, 'OtherName', "Name from module is OtherName." ) or diag explain $name;
    $desc = $repodb->desc();
    is( $desc, 'OtherDesc', "Desc from module is OtherDesc." ) or diag explain $desc;

    $name = $repodb->name("MyDBNameInit");
    is( $name, 'MyDBNameInit', "Name set from module is MyDBNameInit." ) or diag explain $name;
    $desc = $repodb->desc("MyDBDescInit");
    is( $desc, 'MyDBDescInit', "Desc set from module is MyDBDescInit." ) or diag explain $desc;

    $name = $repodb->name();
    is( $name, 'MyDBNameInit', "Name from module is MyDBNameInit." ) or diag explain $name;
    $desc = $repodb->desc();
    is( $desc, 'MyDBDescInit', "Desc from module is MyDBDescInit." ) or diag explain $desc;

    # Check conf_projects information
    note( "Check conf_projects information." );

    my $ret = $repodb->set_project_conf('modeling.sirius', 'Sirius', 'Sirius is a great tool.', 0, '{}');
    ok( $ret == 2, "First update of project_info is an insert.") or diag explain $ret;

    my $ret_ok = {
	'desc' => 'Sirius is a great tool.',
	'name' => 'Sirius',
	'plugins' => '{}'
    };
    $ret = $repodb->get_project_conf('modeling.sirius');
    is_deeply($ret, $ret_ok, "Get project has correct name, desc and empty plugins.") or diag explain $ret;

    $ret = $repodb->get_project_conf('wrong.project');
    is_deeply($ret, {}, "Getting a wrong project returns {}.");
    
    my $projects_list = $repodb->get_projects_list();
    is_deeply( $projects_list, {"modeling.sirius" => "Sirius"}, "Projects list has modeling.sirius.") or diag explain $projects_list;

    $ret = $repodb->set_project_conf('modeling.sirius', 'SiriusChanged', 'Sirius is a great tool Changed.', '0', '{ "EclipseIts": {"project_grim": "modeling.sirius"} }');
    ok( $ret == 1, "Second update of project_info is an update.") or diag explain $ret;

    $ret_ok = {
	'desc' => 'Sirius is a great tool Changed.',
	'name' => 'SiriusChanged',
	'plugins' => '{ "EclipseIts": {"project_grim": "modeling.sirius"} }'
    };
    $ret = $repodb->get_project_conf('modeling.sirius');
    is_deeply($ret, $ret_ok, "Get project has correct name, desc and plugins.") or diag explain $ret;

    # Check projects_run information
    note( "Check projects_run information." );
    my $run_time = strftime("%Y-%m-%d %H:%M:%S\n", localtime(time));
    $ret = $repodb->add_project_run( 'modeling.sirius', 
				     {
					 "timestamp" => "$run_time", 
					 "delay" => 13, 
					 "user" => "none"
				     }, 
				     {'MYMETRIC' => 5}, 
				     {'MYINDIC' => 6}, 
				     {'MYQUEST' => 7}, 
				     {'MYATTR' => 8} , 
				     {'MYREC' => {
					 'rid' => 'REC_PMI_1', 
					 'desc' => 'This is a description.'
				      }
				     } );
    ok( $ret > 0, "Adding project run returns a non-null id ($ret)." );

    $results = $repodb->get_project_last_run('modeling.sirius');
    is_deeply( $results->{'metrics'}, {'MYMETRIC' => 5}, "Metrics retrieved from last run are ok.") or diag explain $results;
    is_deeply( $results->{'indicators'}, {'MYINDIC' => 6}, "Indicators retrieved from last run are ok.") or diag explain $results;
    is_deeply( $results->{'questions'}, {'MYQUEST' => 7}, "Questions retrieved from last run are ok.") or diag explain $results;
    is_deeply( $results->{'attributes'}, {'MYATTR' => 8}, "Attributes retrieved from last run are ok.") or diag explain $results;
    is_deeply( $results->{'recs'}, {'MYREC' => {
					 'rid' => 'REC_PMI_1', 
					 'desc' => 'This is a description.'
				      }
				     }, "Recs retrieved from last run are ok.") or diag explain $results;

    # Second run
    $run_time = strftime("%Y-%m-%d %H:%M:%S\n", localtime(time));
    $ret = $repodb->add_project_run( 'modeling.sirius', 
				     {
					 "timestamp" => "$run_time", 
					 "delay" => 113, 
					 "user" => "none"
				     }, 
				     {'MYMETRIC' => 15}, 
				     {'MYINDIC' => 16}, 
				     {'MYQUEST' => 17}, 
				     {'MYATTR' => 18} , 
				     {'MYREC' => {
					 'rid' => 'REC_PMI_11', 
					 'desc' => 'This is a description.'
				      }
				     } );
    ok( $ret > 0, "Adding project run returns a non-null id ($ret)." );

    $results = $repodb->get_project_last_run('modeling.sirius');
    is_deeply( $results->{'metrics'}, {'MYMETRIC' => 15}, "Metrics retrieved from last run are ok.") or diag explain $results;
    is_deeply( $results->{'indicators'}, {'MYINDIC' => 16}, "Indicators retrieved from last run are ok.") or diag explain $results;
    is_deeply( $results->{'questions'}, {'MYQUEST' => 17}, "Questions retrieved from last run are ok.") or diag explain $results;
    is_deeply( $results->{'attributes'}, {'MYATTR' => 18}, "Attributes retrieved from last run are ok.") or diag explain $results;
    is_deeply( $results->{'recs'}, {'MYREC' => {
					 'rid' => 'REC_PMI_11', 
					 'desc' => 'This is a description.'
				    }
	                           }, "Recs retrieved from last run are ok.") or diag explain $results;

};

if ($clean_db) {
    # Clean database, re-init tables.
    
    $repodb->clean_db();
    @tables = ();
    push( @tables, $_->{'tablename'} ) for $pg->db->query("SELECT tablename FROM pg_catalog.pg_tables 
      WHERE schemaname != 'pg_catalog' AND schemaname != 'information_schema';")->hashes->each;
    is( scalar @tables, 1, "Database has 1 tables defined after clean_db.") or diag explain @tables;
}

done_testing(40);
