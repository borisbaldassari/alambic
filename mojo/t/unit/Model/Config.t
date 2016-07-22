#! perl -I../../lib/

use strict;
use warnings;

use Test::More;

BEGIN { use_ok( 'Alambic::Model::Config' ); }


#################################
# Default config is used
note("Config is default");

my $config = Alambic::Model::Config->new();
isa_ok($config, 'Alambic::Model::Config');

# Check that basic info is ok.
my $name = $config->get_name();
ok( $name =~ m!DefaultName!, 'Default name is DefaultName') or diag explain $name;

my $desc = $config->get_desc();
ok( $desc =~ m!Default Description!, 'Defalt desc is Default Description') or diag explain $desc;

my $dir_projects = $config->get_dir_projects();
ok( $dir_projects =~ m!projects/!, 'Default dir for projects is projects/') or diag explain $dir_projects;

my $pg_minion = $config->get_pg_minion();
ok( $pg_minion =~ m!^$!, 'Default pg_minion is correct') or diag explain $pg_minion;

my $pg_alambic = $config->get_pg_alambic();
ok( $pg_alambic =~ m!^$!, 'Default pg_alambic is correct') or diag explain $pg_alambic;

# Check full config hash
my $config_ref = {
    'name' => 'DefaultName',
    'desc' => 'Default Description',
    'dir_projects' => 'projects/',
    'conf_pg_minion' => '',
    'conf_pg_alambic' => '',
};    
my $config_test = $config->get_conf();
is_deeply( $config_test, $config_ref, 'Default config is ok') or diag explain $config_test;

#################################
# Config is provided
note("Config is provided");

$config_ref = {
    'name' => 'SpecificName',
    'desc' => 'Specific Description',
    'dir_projects' => 'projects2/',
    'conf_pg_minion' => 'postgresql://alambic:pass4alambic@/minion_db',
    'conf_pg_alambic' => 'postgresql://alambic:pass4alambic@/alambic_db',
};    

$config = Alambic::Model::Config->new($config_ref);
isa_ok($config, 'Alambic::Model::Config');

# Check that basic info is ok.
$name = $config->get_name();
ok( $name =~ m!SpecificName!, 'Updated name is SpecificName') or diag explain $name;

$desc = $config->get_desc();
ok( $desc =~ m!Specific Description!, 'Updated desc is Specific Description') or diag explain $desc;

$dir_projects = $config->get_dir_projects();
ok( $dir_projects =~ m!projects2/!, 'Updated dir for projects is projects2/') or diag explain $dir_projects;

$pg_minion = $config->get_pg_minion();
ok( $pg_minion =~ m!^postgresql://alambic:pass4alambic@/minion_db$!, 'Updated pg_minion is correct') or diag explain $pg_minion;

$pg_alambic = $config->get_pg_alambic();
ok( $pg_alambic =~ m!^postgresql://alambic:pass4alambic@/alambic_db$!, 'Updated pg_alambic is correct') or diag explain $pg_alambic;

# Check full config hash
$config_test = $config->get_conf();
is_deeply( $config_test, $config_ref, 'Updated config is ok') or diag explain $config_test;


done_testing(15);
