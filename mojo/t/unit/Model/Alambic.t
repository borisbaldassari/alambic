#! perl -I../../lib/

use strict;
use warnings;

use Test::More;
use Data::Dumper;

BEGIN { use_ok( 'Alambic::Model::Alambic' ); }

my $alambic = Alambic::Model::Alambic->new();
isa_ok( $alambic, 'Alambic::Model::Alambic' );

# Initialise the db.
$alambic->init();
my $db_ok = $alambic->is_db_ok();
ok( $db_ok == 1, "Is db ok alambic returns 1.") or diag explain $db_ok;
my $db_m_ok = $alambic->is_db_m_ok();
ok( $db_m_ok == 0, "Is db minion ok returns 0 (db was not defined).") or diag explain $db_m_ok;

my $conf = $alambic->instance_name();
is( $conf, 'DefaultName', "Instance has correct name") or diag explain $conf;
$conf = $alambic->instance_desc();
is( $conf, 'Default Description', "Instance has correct desc") or diag explain $conf;
$conf = $alambic->instance_pg_alambic();
is( $conf, '', "Instance has correct pg_alambic") or diag explain $conf;
$conf = $alambic->instance_pg_minion();
is( $conf, '', "Instance has correct pg_minion") or diag explain $conf;

# Run a db backup before creating project
my $sql = $alambic->backup();
ok( $sql =~ m!DROP TABLE IF EXISTS conf!, "SQL backup has drop table for conf.") or diag explain $sql;
ok( $sql =~ m!CREATE TABLE IF NOT EXISTS conf!, "SQL backup has create table for conf.") or diag explain $sql;
ok( $sql =~ m!INSERT INTO conf \(param, val\)\s*VALUES \('name', 'MyDBNameInit'\);!, "SQL backup has insert for name.") or diag explain $sql;
ok( $sql =~ m!INSERT INTO conf \(param, val\)\s*VALUES \('desc', 'MyDBDescInit'\);!, "SQL backup has insert for desc.") or diag explain $sql;

note("Create empty project from Alambic.");
my $project = $alambic->create_project( 'tools.cdt', 'Tools CDT' );
isa_ok( $project, 'Alambic::Model::Project' );
ok( $project != 0, "Project creation went well (!= 0)." ) or diag explain $project;

my $project_id = $project->get_id();
ok( $project_id =~ m!^tools.cdt$!, 'Project generated by Alambic has correct id.' ) or diag explain $project_id;

my $project_name = $project->get_name();
ok( $project_name =~ m!^Tools CDT$!, 'Project generated by Alambic has correct name.' ) or diag explain $project_name;

$project = $alambic->get_project('tools.cdt');
isa_ok( $project, 'Alambic::Model::Project' );

$project_id = $project->get_id();
ok( $project_id =~ m!^tools.cdt$!, 'Project retrieved by Alambic has correct id.' ) or diag explain $project_id;

$project_name = $project->get_name();
ok( $project_name =~ m!^Tools CDT$!, 'Project retrieved by Alambic has correct name.' ) or diag explain $project_name;

my $plugins = $alambic->get_plugins();
my $plugins_list = $plugins->get_list_all();
my $pv = 2;
ok( scalar @{$plugins_list} == $pv, "Plugins list has $pv entries." ) or diag explain $plugins_list;

my $projects_list = $alambic->get_projects_list();
ok( $projects_list->{'tools.cdt'} =~ m!^Tools CDT$!, "Projects list contains Tools CDT only." ) or diag explain $projects_list;

note("Run project from Alambic.");
my $ret = $alambic->run_project('tools.cdt');
ok( $ret > 0, "Adding run_project returns non-null id ($ret)." ) or diag explain $ret;

# Restore previous backup and make sure the created project is not there.
$alambic->restore($sql);
$project = $alambic->get_project('tools.cdt');
is( $project, undef, "Get project tools.cdt returns undef." );


done_testing(23);
