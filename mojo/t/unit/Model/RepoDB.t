#! perl -I../../lib/

use strict;
use warnings;

use Mojo::Pg;
use Test::More;
use Data::Dumper;

BEGIN { use_ok( 'Alambic::Model::RepoDB' ); }

my $pg = Mojo::Pg->new('postgresql://alambic:pass4alambic@/alambic_db');

my $repodb = Alambic::Model::RepoDB->new();
isa_ok( $repodb, 'Alambic::Model::RepoDB' );

my $is_init = $repodb->is_db_defined();
is( $is_init, 1, "DB is defined in module.");

my $version = $repodb->get_pg_version;
like( $version, qr/^PostgreSQL 9.4/, "Postgres has version 9.4." ) or diag explain $version;

note( "Initialising DB." );
$repodb->init_db();

my @tables;
push( @tables, $_->{'tablename'} ) for $pg->db->query("SELECT tablename FROM pg_catalog.pg_tables 
  WHERE schemaname != 'pg_catalog' AND schemaname != 'information_schema';")->hashes->each;
is( scalar @tables, 4, "Database has 4 tables defined.") or diag explain @tables;
ok( grep( /^conf$/, @tables ) == 1, "Table conf is defined.") or diag explain @tables;
ok( grep( /^conf_projects$/, @tables ) == 1, "Table conf_projects is defined.") or diag explain @tables;
ok( grep( /^projects$/, @tables ) == 1, "Table projects is defined.") or diag explain @tables;

note( "Table conf:" );
my %values;
my $results = $pg->db->query('select * from conf');
while (my $next = $results->hash) { 
    $values{ $next->{'param'} } = $next->{'val'}; 
}
#( $values{ $_->{'param'} } = $_->{'value'} && print Dumper($_) ) for $pg->db->query('select * from conf;')->hashes->each;
is( $values{'name'}, "MyDBNameInit", "Name in DB is MyDBNameInit." ) or diag explain %values;
is( $values{'desc'}, "MyDBDescInit", "Desc in DB is MyDBDescInit." ) or diag explain %values;

#note( "Get name MyDBNameInit." );
my $name = $repodb->name();
is( $name, 'MyDBNameInit', "Name from module is MyDBNameInit." ) or diag explain $name;
my $desc = $repodb->desc();
is( $desc, 'MyDBDescInit', "Desc from module is MyDBDescInit." ) or diag explain $name;

#$repodb->clean_db();

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

$repodb->clean_db();
@tables = ();
push( @tables, $_->{'tablename'} ) for $pg->db->query("SELECT tablename FROM pg_catalog.pg_tables 
  WHERE schemaname != 'pg_catalog' AND schemaname != 'information_schema';")->hashes->each;
is( scalar @tables, 1, "Database has 1 tables defined after clean_db.") or diag explain @tables;

done_testing();
