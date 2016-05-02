package Alambic::Model::RepoDB;

use warnings;
use strict;

use Alambic::Model::Config;

use Mojo::Pg;
#use File::Copy;
use Data::Dumper;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw( 
                     name
                     desc
                     init_db
                     get_pg_version
                   );  

my $config;
my $pg;

# Create a new RepoDB object.
sub new { 
    my ($class, $dbh, $args) = @_;

    $config = Alambic::Model::Config->new();

    if (defined($dbh)) {
	$pg = $dbh;
    } else {
	my $config_url = $config->get_pg_alambic();
	my $db_url = ( defined($config_url) && $config_url =~ /^postgres/ ) ? 
	    $config_url : 
	    "postgresql://alambic:pass4alambic@/alambic_db";
	$pg = Mojo::Pg->new($db_url);
    }
    
    return bless {}, $class;
}


sub init_db() {
    &_db_init();
}


sub get_pg_version() {
    return $pg->db->query('select version() as version;')->hash->{version};
}


sub _db_init() {

    my $migrations = $pg->migrations();
	#Mojo::Pg::Migrations->new(pg => $pg);
#    my $active = $migrations->active;
#    print "Active migration is $active.\n";
    
    $migrations = $migrations->from_string(
"-- 1 up
DROP TABLE if exists conf;
DROP TABLE if exists conf_projects;
DROP TABLE if exists projects;

CREATE TABLE if not exists conf (
    param text, 
    val text,
    PRIMARY KEY( param )
);
INSERT INTO conf VALUES ('name', 'MyDBNameInit');
INSERT INTO conf VALUES ('desc', 'MyDBDescInit');

CREATE TABLE if not exists conf_projects (
    id text, 
    name text,
    plugins jsonb,
    PRIMARY KEY( id )
);

CREATE TABLE if not exists projects (
    id text, 
    metrics jsonb,
    questions jsonb,
    attributes jsonb,
    recs jsonb,
    PRIMARY KEY( id )
);
-- 1 down
DROP TABLE if exists conf;
DROP TABLE if exists conf_projects;
DROP TABLE if exists projects;
");

    $migrations->migrate(1)->migrate;
    
    # my $results = $pg->db->query('select * from conf');
    # while (my $next = $results->hash) {
    # 	print "### " . $next->{'param'} . " " . $next->{'val'} . ".\n";
    # }
	
#    my $test = $pg->db->query("SELECT * FROM conf;")->hash;
#    print( $_->{'param'} . ":" . $_->{'val'} . "\n" ) for $pg->db->query('select * from conf')->hashes->each;
#    print "##########################\n" . Dumper($test) . "##########################\n";
    
#    $active = $migrations->active;
#    print "Active migration is $active.\n";
	
}


sub clean_db() {    
    my $active = $pg->migrations()->active;
    $pg->migrations()->migrate(0);
    $active = $pg->migrations()->active;
}


sub is_db_defined() {
    if (defined $pg) {
	return 1;
    } else {
	return 0;
    }
}


sub name($) {
    my ($self, $name) = @_;

    my $ret;
    if (scalar @_ > 1) {
	$pg->db->query("UPDATE conf SET val='$name' WHERE param='name';");
	$ret = $name;
    } else {
	my $test = $pg->db->query("SELECT val FROM conf WHERE param='name';")->hash;
	$ret = $test->{'val'};
    }
    
    return $ret;
}


sub desc($) {
    my ($self, $desc) = @_;

    my $ret;
    if (scalar @_ > 1) {
	$pg->db->query("UPDATE conf SET val='$desc' WHERE param='desc';");
	$ret = $desc;
    } else {
	my $test = $pg->db->query("SELECT val FROM conf WHERE param='desc';")->hash;
	$ret = $test->{'val'};
    }
    
    return $ret;
}


sub write_input($$$) {
    my ($self, $project_id, $file_name, $content) = @_;

    # Create projects input dir if it does not exist
    if (not -d 'projects/' . $project_id ) { 
        mkdir( 'projects/' . $project_id );
    }
    if (not -d 'projects/' . $project_id . '/input') { 
        mkdir( 'projects/' . $project_id . '/input');
    }

    my $file_content_out = "projects/" . $project_id . "/input/" . $project_id . "_" . $file_name;
    open my $fh, ">", $file_content_out;
    print $fh $content;
    close $fh;
}


1;

