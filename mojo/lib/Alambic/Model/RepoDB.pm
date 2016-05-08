package Alambic::Model::RepoDB;

use warnings;
use strict;

use Mojo::Pg;
use Mojo::JSON qw( decode_json encode_json );
#use File::Copy;
use Data::Dumper;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw( 
                     init_db
                     backup_db
                     restore_db
                     get_pg_version
                     clean_db
                     is_db_defined
                     is_db_ok
                     name
                     desc
                     set_project_conf
                     delete_project
                     get_project_conf
                     get_projects_list
                     add_project_run
                     get_project_last_run
                     get_project_all_runs
                   );  

my $pg;

# Create a new RepoDB object.
sub new { 
    my ($class, $alambic_db, $args) = @_;

    my $db_url = "postgresql://alambic:pass4alambic@/alambic_db";

    if (defined($alambic_db) && $alambic_db =~ /^postgres/) {
	$db_url = $alambic_db;
    }

    $pg = Mojo::Pg->new($db_url);
    
    return bless {}, $class;
}


sub init_db() {
    &_db_init();
}


sub backup_db() {
    my ($self) = @_;
    
    my $sql_out = '
DROP TABLE IF EXISTS conf;
DROP TABLE IF EXISTS conf_projects;
DROP TABLE IF EXISTS projects;

CREATE TABLE IF NOT EXISTS conf (
    param TEXT NOT NULL, 
    val TEXT,
    PRIMARY KEY( param )
);

CREATE TABLE IF NOT EXISTS conf_projects (
    id TEXT, 
    name TEXT, 
    description TEXT, 
    is_active BOOLEAN, 
    plugins JSONB,
    PRIMARY KEY( id )
);

CREATE TABLE IF NOT EXISTS projects (
    id BIGSERIAL, 
    project_id TEXT NOT NULL, 
    run_time TIMESTAMP,
    run_delay INT,
    run_user TEXT,
    metrics JSONB,
    indicators JSONB,
    attributes JSONB,
    recs JSONB,
    PRIMARY KEY( id )
);
';
    
    my $results = $pg->db->query("SELECT * FROM conf");
    while (my $next = $results->hash) {
	my $insert_statement = qq{INSERT INTO conf (param, val)\n VALUES (};
	$insert_statement .= "'" . $next->{'param'} . "', '" . $next->{'val'} . "');\n";
	$sql_out .= $insert_statement;
    }

    $results = $pg->db->query("SELECT * FROM conf_projects");
    while (my $next = $results->hash) {
	my $insert_statement = qq{INSERT INTO conf_projects (id, name, description, is_active, plugins)\n VALUES (};
	$insert_statement .= "'" . $next->{'id'} . "', '" . $next->{'name'} . "', '"
	. $next->{'description'} . "', '" . $next->{'is_active'} . "', '"
	. $next->{'plugins'} . "');\n";
	$sql_out .= $insert_statement;
    }
    
    $results = $pg->db->query("SELECT * FROM projects");
    my $fields = "id, project_id, run_time, run_delay, run_user, metrics, indicators, attributes, recs";
    while (my $next = $results->hash) {
	my $insert_statement = qq{INSERT INTO projects ($fields)\n VALUES (};
	$insert_statement .= "'" . $next->{'id'} . "', '" . $next->{'project_id'} . "', '"
	. $next->{'run_time'} . "', '" . $next->{'run_delay'} . "', '"
	. $next->{'run_user'} . "', '" . $next->{'metrics'} . "', '"
	. $next->{'indicators'} . "', '" . $next->{'attributes'} . "', '"
	. $next->{'recs'} . "');\n";
	$sql_out .= $insert_statement;
    }

    return $sql_out;
}


sub restore_db($) {
    my ($self, $sql_in) = @_;

    my $results = $pg->db->query($sql_in);

    return 1;
}


sub get_pg_version() {
    return $pg->db->query('select version() as version;')->hash->{'version'};
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


sub is_db_ok() {
    my $rows = $pg->db->query("SELECT tablename FROM pg_catalog.pg_tables 
      WHERE schemaname != 'pg_catalog' AND schemaname != 'information_schema';")->rows;

    return $rows > 1 ? 1 : 0;
}


# Get or set the Alambic instance name.
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


# Get or set the Alambic instance description.
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


# Add or edit a project in the list of projects, with its name, desc, and plugins.
#
# Params:
#   - $id a string for the uniq identifier of the project (e.g. modeling.sirius).
#   - $name a string for the name of the project.
#   - $desc a string for the description of the project.
#   - \%plugins a hash ref to the configuration of plugins.
sub set_project_conf($$$$$) {
    my $self = shift;
    my $id = shift;
    my $name = shift || '';
    my $desc = shift || '';
    my $is_active = shift || 0;
    my $plugins = shift;

    my $ret = 0;
    
    # See if the project exists
    my %values; 
    my $exists = 0;
    my $results = $pg->db->query("SELECT name, description, is_active, plugins FROM conf_projects WHERE id='$id';");

    # There should be only 1 row with this id.
    while (my $next = $results->hash) {
	$exists = 1;
	$values{'name'} = $next->{'name'}; 
	$values{'desc'} = $next->{'description'}; 
	$values{'is_active'} = $next->{'is_active'} || 0; 
	$values{'plugins'} = $next->{'plugins'}; 
    }

    my $plugins_json = encode_json($plugins);
    if ($exists) {
	$pg->db->query("UPDATE conf_projects SET name='$name', description='$desc', is_active='${is_active}', plugins='$plugins_json' WHERE id='$id';");
	$ret = 1;
    } else {
	my $ret_q = $pg->db->query("INSERT INTO conf_projects VALUES ('$id', '$name', '$desc', '${is_active}', '$plugins_json');");
	$ret = 2;
    }
    
    return $ret;
}


# Delete from db all entries relatives to a project.
sub delete_project() {
    my ($self, $project_id) = @_;

    # Remove project from table conf_projects
    my $results = $pg->db->query("DELETE FROM conf_projects WHERE id='$project_id';");
    
    # Remove project runs from table projects
    $results = $pg->db->query("DELETE FROM projects WHERE project_id='$project_id';");

    return 1;
}


# Get the configuration of a project as a hash.
sub get_project_conf($) {
    my ($self, $id) = @_;

    # See if the project exists
    my %values; 
    my $exists = 0;
    my $results = $pg->db->query("SELECT name, description, is_active, plugins FROM conf_projects WHERE id='$id';");
    # There should be 0 or 1 row with this id.
    while (my $next = $results->hash) {
	$exists = 1;
	$values{'name'} = $next->{'name'}; 
	$values{'desc'} = $next->{'description'};
	$values{'is_active'} = $next->{'is_active'};
	$values{'plugins'} = decode_json( $next->{'plugins'} ); 
    }

    return $exists ? \%values : undef;
}


# Returns a hash of projects id/names defined in the db.
sub get_projects_list() {
    my ($self) = @_;

    my %projects_list; 
    my $results = $pg->db->query("SELECT id, name FROM conf_projects;");
    while (my $next = $results->hash) {
	$projects_list{$next->{'id'}} = $next->{'name'}; 
    }

    return \%projects_list;
}


# Stores the results of a job run in Alambic.
#
# Params
#  - $id the id of the project, e.g. modeling.sirus.
#  - \%run a hash ref with info about the run: timestamp, delay, user.
#  - \%metrics a hash ref of metrics.
#  - \%indicators a hash ref of indicators.
#  - \%attributes a hash ref of attributes.
#  - \%recs a hash ref of recs.
sub add_project_run($$$$$$$) {
    my ($self, $project_id, $run, $metrics, $indicators, $attributes, $recs) = @_;

    # Expand information..
    my $run_time = $run->{'timestamp'};
    my $run_delay = $run->{'delay'};
    my $run_user = $run->{'user'};

    my $metrics_json = encode_json($metrics);
    my $indicators_json = encode_json($indicators);
    my $attributes_json = encode_json($attributes);
    my $recs_json = encode_json($recs);

    # Execute insert in db.
    my $query = "INSERT INTO projects 
        ( project_id, run_time, run_delay, run_user, metrics, indicators, attributes, recs ) 
      VALUES 
        ('$project_id', '$run_time', '$run_delay', '$run_user', 
        '$metrics_json', '$indicators_json', '$attributes_json', '$recs_json') 
        returning id;";

    my $id = 0;
    eval {
	$id = $pg->db->query($query)->hash->{'id'};
    };
    
    return $id;
}


# Returns the results of the last job run in Alambic for the specified project.
# {
#   'attributes' => {
#     'MYATTR' => 18
#   },
#   'id' => 2,
#   'indicators' => {
#     'MYINDIC' => 16
#   },
#   'metrics' => {
#     'MYMETRIC' => 15
#   },
#   'project_id' => 'modeling.sirius',
#   'recs' => {
#     'MYREC' => {
#       'desc' => 'This is a description.',
#       'rid' => 'REC_PMI_11'
#     }
#   },
#   'run_delay' => 113,
#   'run_time' => '2016-05-08 16:53:57',
#   'run_user' => 'none'
# }
#
# Params
#  - $id the id of the project, e.g. modeling.sirus.
sub get_project_last_run() {
    my ($self, $id) = @_;

    my %project;
    
    # Execute insert in db.
    my $results = $pg->db->query("SELECT * FROM projects WHERE project_id='$id' ORDER BY id DESC LIMIT 1");
    while (my $next = $results->hash) {
	$project{'id'} = $next->{'id'}; 
	$project{'project_id'} = $next->{'project_id'}; 
	$project{'run_time'} = $next->{'run_time'}; 
	$project{'run_delay'} = $next->{'run_delay'}; 
	$project{'run_user'} = $next->{'run_user'}; 
	$project{'metrics'} = decode_json( $next->{'metrics'} ); 
	$project{'indicators'} = decode_json( $next->{'indicators'} ); 
	$project{'attributes'} = decode_json( $next->{'attributes'} ); 
	$project{'recs'} = decode_json($next->{'recs'} ); 
    }

    return \%project;
}


# Returns an array of results of all runs in Alambic for the specified project.
# [
#   {
#     'id' => 2,
#     'project_id' => 'modeling.sirius',
#     'run_delay' => 113,
#     'run_time' => '2016-05-08 16:53:20',
#     'run_user' => 'none'
#   },
#   {
#     'id' => 1,
#     'project_id' => 'modeling.sirius',
#     'run_delay' => 13,
#     'run_time' => '2016-05-08 16:53:20',
#     'run_user' => 'none'
#   }
# ]
#
# Params
#  - $id the id of the project, e.g. modeling.sirus.
sub get_project_all_runs() {
    my ($self, $id) = @_;

    my $project;
    
    # Execute insert in db.
    my $results = $pg->db->query("SELECT id, project_id, run_time, run_delay, run_user FROM projects WHERE project_id='$id' ORDER BY id DESC");
    my $row = 0;
    while (my $next = $results->hash) {
	$project->[$row]{'id'} = $next->{'id'}; 
	$project->[$row]{'project_id'} = $next->{'project_id'}; 
	$project->[$row]{'run_time'} = $next->{'run_time'}; 
	$project->[$row]{'run_delay'} = $next->{'run_delay'}; 
	$project->[$row]{'run_user'} = $next->{'run_user'}; 
	$row++;
    }

    return $project;
}


sub _db_init() {

    my $migrations = $pg->migrations();
    
    $migrations = $migrations->from_string(
"-- 1 up
DROP TABLE IF EXISTS conf;
DROP TABLE IF EXISTS conf_projects;
DROP TABLE IF EXISTS projects;

CREATE TABLE IF NOT EXISTS conf (
    param TEXT NOT NULL, 
    val TEXT,
    PRIMARY KEY( param )
);
INSERT INTO conf VALUES ('name', 'MyDBNameInit');
INSERT INTO conf VALUES ('desc', 'MyDBDescInit');

CREATE TABLE IF NOT EXISTS conf_projects (
    id TEXT, 
    name TEXT, 
    description TEXT, 
    is_active BOOLEAN, 
    plugins JSONB,
    PRIMARY KEY( id )
);

CREATE TABLE IF NOT EXISTS projects (
    id BIGSERIAL, 
    project_id TEXT NOT NULL, 
    run_time TIMESTAMP,
    run_delay INT,
    run_user TEXT,
    metrics JSONB,
    indicators JSONB,
    attributes JSONB,
    recs JSONB,
    PRIMARY KEY( id )
);
-- 1 down
DROP TABLE IF EXISTS conf;
DROP TABLE IF EXISTS conf_projects;
DROP TABLE IF EXISTS projects;
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


1;

