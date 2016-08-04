package Alambic::Model::RepoDB;

use warnings;
use strict;

use Mojo::Pg;
use Mojo::JSON qw( decode_json encode_json );
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
                     get_info
                     get_metric
                     get_metrics
                     set_metric 
                     get_attribute
                     get_attributes
                     set_attribute
                     get_user
                     get_users
                     add_user
                     get_qm
                     set_qm                
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
    
    my $sql_out = &_db_query_create();
	print "################################\n";
   
    my @tables = ( 'conf', 'users', 
		   'models_attributes', 'models_metrics', 'models_qms', 
		   'projects_cdata', 'projects_conf', 'projects_info', 'projects_runs' );
 
    foreach my $table (@tables) {
	my $results = $pg->db->query("SELECT * FROM $table");
	while (my $next = $results->hash) {
	    my @cols = sort keys %{$next};
	    my @values_orig = map { my $v = $next->{$_}; $v =~ s/'/''/g; "" . $v . "" } @cols;
	    my $insert_statement = "INSERT INTO $table (" . join(', ', @cols) . ")\n VALUES ('";
	    $insert_statement .= join( '\', \'', @values_orig) . "');\n";
	    $sql_out .= $insert_statement;
	}
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

    return $rows == 10 ? 1 : 0;
}


# Get or set the Alambic instance name.
sub name($) {
    my ($self, $name) = @_;

    my $ret;
    if (scalar @_ > 1) {
	$pg->db->query("UPDATE conf SET val=? WHERE param='name';", ($name));
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
	$pg->db->query("UPDATE conf SET val=? WHERE param='desc';", ($desc));
	$ret = $desc;
    } else {
	my $test = $pg->db->query("SELECT val FROM conf WHERE param='desc';")->hash;
	$ret = $test->{'val'};
    }
    
    return $ret;
}


# Get all info for a project from db
sub get_info($) {
    my ($self, $project_id) = @_;
    
    # Execute select in info table.
    my %ret;
    my $results = $pg->db->query("SELECT last_run, info FROM projects_info WHERE project_id=?", ($project_id));
    while (my $next = $results->hash) {
	$ret{'last_run'} = $next->{'last_run'}; 
	$ret{'info'} = encode_json( $next->{'info'} ); 
    }
    
    return \%ret;
}


# Get a single metric definition from db.
sub get_metric($) {
    my ($self, $mnemo) = @_;
    
    my $results = $pg->db->query("SELECT * FROM models_metrics WHERE mnemo='?';", ($mnemo));
    my $ret;

    # Process one row at a time
    while (my $next = $results->hash) {
	$ret->{$next->{'mnemo'}} = $next;
	$ret->{$next->{'mnemo'}}->{'description'} = decode_json( $next->{'description'} );
	$ret->{$next->{'mnemo'}}->{'scale'} = decode_json( $next->{'scale'} );
    }

    return $ret;
}


# Get all metrics definition from db
sub get_metrics($) {
    my $results = $pg->db->query("SELECT * FROM models_metrics;");
    my $ret;

    # Process one row at a time
    while (my $next = $results->hash) {
	$ret->{$next->{'mnemo'}} = $next;
	$ret->{$next->{'mnemo'}}->{'description'} = decode_json( $next->{'description'} );
	$ret->{$next->{'mnemo'}}->{'scale'} = decode_json( $next->{'scale'} );
    }

    return $ret;
}


# Set a metric definition in the db.
sub set_metric($) {
    my $self = shift;
    my $mnemo = shift;
    my $name = shift || '';
    my $desc = shift || '[]';
    my $scale = shift || '[]';
    
    my $query = "INSERT INTO models_metrics (mnemo, name, description, scale) VALUES "
	. "(?, ?, ?, ?) ON CONFLICT (mnemo) DO UPDATE SET (mnemo, name, description, scale) "
	. "= (?, ?, ?, ?)";
    my $ret = $pg->db->query( $query, ($mnemo, $name, $desc, $scale, $mnemo, $name, $desc, $scale) );
    
    return $ret;
}


# Get a single attribute definition from db.
sub get_attribute($) {
    my ($self, $mnemo) = @_;
    
    my $results = $pg->db->query("SELECT * FROM models_attributes WHERE mnemo='?';", ($mnemo));
    my $ret;

    # Process one row at a time
    while (my $next = $results->hash) {
	$ret->{$next->{'mnemo'}} = $next;
	$ret->{$next->{'mnemo'}}->{'description'} = decode_json( $next->{'description'} );
    }

    return $ret;
}


# Get all attributes definition from db
sub get_attributes($) {
    my $results = $pg->db->query("SELECT * FROM models_attributes;");
    my $ret;

    # Process one row at a time
    while (my $next = $results->hash) {
	$ret->{$next->{'mnemo'}} = $next;
	$ret->{$next->{'mnemo'}}->{'description'} = decode_json( $next->{'description'} );    }

    return $ret;
}


# Set a attribute definition in the db.
sub set_attribute($) {
    my $self = shift;
    my $mnemo = shift;
    my $name = shift || '';
    my $desc = shift || '[]';
    
    my $query = "INSERT INTO models_attributes (mnemo, name, description) VALUES "
	. "(?, ?, ?) ON CONFLICT (mnemo) DO UPDATE SET (mnemo, name, description) "
	. "= (?, ?, ?)";
    my $ret = $pg->db->query( $query, ($mnemo, $name, $desc, $mnemo, $name, $desc) );
    
    return $ret;
}


# Get all users from db
sub get_users() {
    my $results = $pg->db->query("SELECT * FROM users;");
    my $ret;

    # Process one row at a time
    while (my $next = $results->hash) {
	$ret->{$next->{'id'}} = $next;
	$ret->{$next->{'id'}}->{'roles'} = decode_json( $next->{'roles'} );    
	$ret->{$next->{'id'}}->{'projects'} = decode_json( $next->{'projects'} );    
	$ret->{$next->{'id'}}->{'notifs'} = decode_json( $next->{'notifs'} );    
    }

    return $ret;
}


# Get a specific user from db
sub get_user($) {
    my $self = shift;
    my $user = shift;
    
    my $results = $pg->db->query("SELECT * FROM users WHERE id=?;", $user);
    my $ret;

    # Process one row at a time
    while (my $next = $results->hash) {
	$ret->{$next->{'id'}} = $next;
	$ret->{$next->{'id'}}->{'roles'} = decode_json( $next->{'roles'} );    
	$ret->{$next->{'id'}}->{'projects'} = decode_json( $next->{'projects'} );    
	$ret->{$next->{'id'}}->{'notifs'} = decode_json( $next->{'notifs'} );    
    }

    return $ret;
}


# Get a specific user from db
sub add_user($$$$$$) {
    my $self = shift;
    my $id = shift;
    my $name = shift;
    my $email = shift;
    my $passwd = shift;
    my $roles = shift;
    my $projects = shift;
    my $notifs = shift;
    
    my $roles_json = encode_json($roles);
    my $projects_json = encode_json($projects);
    my $notifs_json = encode_json($notifs);
    
    my $query = "INSERT INTO users (id, name, email, passwd, roles, projects, notifs) VALUES "
	. "(?, ?, ?, ?, ?, ?, ?) ON CONFLICT (id) DO UPDATE SET "
	. "(id, name, email, passwd, roles, projects, notifs) "
	. "= (?, ?, ?, ?, ?, ?, ?)";
    my $ret = $pg->db->query( $query, 
			      ($id, $name, $email, $passwd, $roles_json, $projects_json, $notifs_json,
			       $id, $name, $email, $passwd, $roles_json, $projects_json, $notifs_json) );

    return $ret;
}


# Get a specific user from db
sub del_user($$$$$$) {
    my $self = shift;
    my $uid = shift;
    

    # Remove project from table conf_projects
    my $ret = $pg->db->query("DELETE FROM users WHERE id=?;", ($uid));

    return $ret;
}


# Get a single qm definition from db.
sub get_qm($) {
    my ($self, $mnemo) = @_;

    my $results = $pg->db->query("SELECT * FROM models_qms LIMIT 1;");
    my $ret;

    # Process one row at a time
    while (my $next = $results->hash) {
	$ret = $next;
	$ret->{'model'} = decode_json( $next->{'model'} );
    }

    return $ret->{'model'} || [];
}


# Set a qm definition in the db.
#
# Params:
#   - $mnemo a string for the uniq identifier of the project (e.g. modeling.sirius).
#   - $name a string for the name of the project.
#   - $model a json for the model.
sub set_qm($$$) {
    my $self = shift;
    my $mnemo = shift;
    my $name = shift || '';
    my $model = shift || '[]';
    
    my $query = "INSERT INTO models_qms (mnemo, name, model) VALUES "
	. "(?, ?, ?) ON CONFLICT (mnemo) DO UPDATE SET (mnemo, name, model) "
	. "= (?, ?, ?)";
    my $ret = $pg->db->query( $query, ($mnemo, $name, $model, $mnemo, $name, $model) );
    
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

    my $plugins_json = encode_json($plugins);
    my $query = "INSERT INTO projects_conf VALUES (?, ?, ?, ?, ?) "
	. "ON CONFLICT (id) DO UPDATE SET (name, description, is_active, plugins) "
	. "= (?, ?, ?, ?)";
    $pg->db->query($query,
		   ($id, $name, $desc, $is_active, $plugins_json, $name, $desc, $is_active, $plugins_json));
    
    return 1;
}


# Delete from db all entries relatives to a project.
sub delete_project() {
    my ($self, $project_id) = @_;

    # Remove project from table conf_projects
    my $results = $pg->db->query("DELETE FROM projects_conf WHERE id=?;", ($project_id));
    
    # Remove project runs from table projects
    $results = $pg->db->query("DELETE FROM projects_runs WHERE project_id=?;", ($project_id));

    return 1;
}


# Get the configuration of a project as a hash.
sub get_project_conf($) {
    my ($self, $id) = @_;

    # See if the project exists
    my %values; 
    my $exists = 0;
    my $results = $pg->db->query("SELECT name, description, is_active, plugins FROM projects_conf WHERE id=?;", ($id));

    # There should be 0 or 1 row with this id.
    while (my $next = $results->hash) {
	$exists = 1;
	$values{'name'} = $next->{'name'}; 
	$values{'desc'} = $next->{'description'};
	$values{'is_active'} = $next->{'is_active'};
	$values{'plugins'} = decode_json( $next->{'plugins'} ); 
	$values{'last_run'} = '';

	my $results_last_run = $pg->db->query("SELECT run_time FROM projects_runs WHERE project_id=? ORDER BY run_time DESC LIMIT 1;", ($id));
	# There should be 0 or 1 row with this id.
	while (my $next = $results_last_run->hash) {
	    $values{'last_run'} = $next->{'run_time'};
	}
    }

    return $exists ? \%values : undef;
}


# Returns a hash of projects id/names defined in the db.
sub get_projects_list() {
    my ($self) = @_;

    my %projects_list; 
    my $results = $pg->db->query("SELECT id, name FROM projects_conf;");
    while (my $next = $results->hash) {
	$projects_list{$next->{'id'}} = $next->{'name'}; 
    }

    return \%projects_list;
}

# Returns a hash of projects id/names defined in the db.
sub get_active_projects_list() {
    my ($self) = @_;

    my %projects_list; 
    my $results = $pg->db->query("SELECT id, name FROM projects_conf WHERE is_active=TRUE;");
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
#  - \%info a hash (ref) of hash of info ($info->{'plugin1'}{'info1'}).
#  - \%metrics a hash ref of metrics.
#  - \%indicators a hash ref of indicators.
#  - \%attributes a hash ref of attributes.
#  - \%attributes_conf a hash ref of attributes.
#  - \@recs a hash ref of recs.
sub add_project_run($$$$$$$) {
    my ($self, $project_id, $run, $info, $metrics, $indicators, $attributes, $attributes_conf, $recs) = @_;

    # Expand information..
    my $run_time = $run->{'timestamp'};
    my $run_delay = $run->{'delay'};
    my $run_user = $run->{'user'};

    my $info_json = encode_json($info);
    my $metrics_json = encode_json($metrics);
    my $indicators_json = encode_json($indicators);
    my $attributes_json = encode_json($attributes);
    my $attributes_conf_json = encode_json($attributes_conf);
    my $recs_json = encode_json($recs);

    # Execute insert in db.
    my $query = "INSERT INTO projects_info 
        ( project_id, last_run, info ) 
      VALUES (?, ?, ?) 
      ON CONFLICT (project_id) DO UPDATE SET ( project_id, last_run, info ) "
	. "= (?, ?, ?)";

    my $id = 0;
    eval {
	$id = $pg->db->query($query, ($project_id, $run_time, $info_json, $project_id, $run_time, $info_json)
	    )->hash->{'id'};
    };
    
    # Execute insert in db.
    $query = "INSERT INTO projects_runs 
        ( project_id, run_time, run_delay, run_user, metrics, indicators, attributes, attributes_conf, recs ) 
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        returning id;";

    $id = 0;
    eval {
	$id = $pg->db->query($query, 
			     ($project_id, $run_time, $run_delay, $run_user, 
			      $metrics_json, $indicators_json, $attributes_json, 
			      $attributes_conf_json, $recs_json) 
	    )->hash->{'id'};
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
#   'recs' => [
#     {
#       'desc' => 'This is a description.',
#       'severity' => 3,
#       'rid' => 'REC_PMI_11'
#     }
#   ],
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
    
    # Execute select in runs table.
    my $query = "SELECT * FROM projects_runs WHERE project_id=? ORDER BY id DESC LIMIT 1";

    my $results = $pg->db->query($query, ($id));
    while (my $next = $results->hash) {
	$project{'id'} = $next->{'id'}; 
	$project{'project_id'} = $next->{'project_id'}; 
	$project{'run_time'} = $next->{'run_time'}; 
	$project{'run_delay'} = $next->{'run_delay'}; 
	$project{'run_user'} = $next->{'run_user'}; 
	$project{'metrics'} = decode_json( $next->{'metrics'} ); 
	$project{'indicators'} = decode_json( $next->{'indicators'} ); 
	$project{'attributes'} = decode_json( $next->{'attributes'} ); 
	$project{'attributes_conf'} = decode_json( $next->{'attributes_conf'} ); 
	$project{'recs'} = decode_json( $next->{'recs'} || '[]' ); 
    }
    
    # Execute select in info table.
    $results = $pg->db->query("SELECT info FROM projects_info WHERE project_id=?", ($id));
    while (my $next = $results->hash) {
	$project{'info'} = decode_json( $next->{'info'} ); 
    }
    
    return \%project;
}


# Returns the results of the specified job run in Alambic for the specified project.
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
#   'recs' => [
#     {
#       'desc' => 'This is a description.',
#       'severity' => 3,
#       'rid' => 'REC_PMI_11'
#     }
#   ],
#   'run_delay' => 113,
#   'run_time' => '2016-05-08 16:53:57',
#   'run_user' => 'none'
# }
#
# Params
#  - $id the id of the project, e.g. modeling.sirus.
sub get_project_run() {
    my ($self, $project_id, $id) = @_;

    my %project;
    
    # Execute select in db.
    my $results = $pg->db->query("SELECT * FROM projects_runs WHERE id=? ORDER BY id DESC LIMIT 1", ($id));
    while (my $next = $results->hash) {
	$project{'id'} = $next->{'id'}; 
	$project{'project_id'} = $next->{'project_id'}; 
	$project{'run_time'} = $next->{'run_time'}; 
	$project{'run_delay'} = $next->{'run_delay'}; 
	$project{'run_user'} = $next->{'run_user'}; 
	$project{'metrics'} = decode_json( $next->{'metrics'} ); 
	$project{'indicators'} = decode_json( $next->{'indicators'} ); 
	$project{'attributes'} = decode_json( $next->{'attributes'} ); 
	$project{'attributes_conf'} = decode_json( $next->{'attributes_conf'} ); 
	$project{'recs'} = decode_json($next->{'recs'} ); 
    }
    
    # Execute select in info table.
    $results = $pg->db->query("SELECT info FROM projects_info WHERE project_id=?", ($id));
    while (my $next = $results->hash) {
	$project{'info'} = decode_json( $next->{'info'} ); 
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
    my $results = $pg->db->query("SELECT id, project_id, run_time, run_delay, run_user FROM projects_runs WHERE project_id=? ORDER BY id DESC", ($id));
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


# Crreates all tables in the database, plus a few default values for conf.
sub _db_init() {

    my $migrations = $pg->migrations();
    
    $migrations = $migrations->from_string( "-- 1 up
" . &_db_query_create() . "
INSERT INTO conf VALUES ('name', 'MyDBNameInit');
INSERT INTO conf VALUES ('desc', 'MyDBDescInit');
-- 1 down
DROP TABLE IF EXISTS conf;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS projects_conf;
DROP TABLE IF EXISTS projects_runs;
DROP TABLE IF EXISTS projects_info;
DROP TABLE IF EXISTS projects_cdata;
DROP TABLE IF EXISTS models_metrics;
DROP TABLE IF EXISTS models_attributes;
DROP TABLE IF EXISTS models_qms;
");

    $migrations->migrate(1)->migrate;
	
}

# Returns the query used to create the db tables.
sub _db_query_create() {

    return "
DROP TABLE IF EXISTS conf;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS projects_conf;
DROP TABLE IF EXISTS projects_runs;
DROP TABLE IF EXISTS projects_info;
DROP TABLE IF EXISTS projects_cdata;
DROP TABLE IF EXISTS models_metrics;
DROP TABLE IF EXISTS models_attributes;
DROP TABLE IF EXISTS models_qms;

CREATE TABLE IF NOT EXISTS conf (
    param TEXT NOT NULL, 
    val TEXT,
    PRIMARY KEY( param )
);

CREATE TABLE IF NOT EXISTS users (
    id TEXT NOT NULL, 
    name TEXT,
    email TEXT,
    passwd TEXT,
    roles JSONB,
    projects JSONB,
    notifs JSONB,
    PRIMARY KEY( id )
);

CREATE TABLE IF NOT EXISTS projects_conf (
    id TEXT, 
    name TEXT, 
    description TEXT, 
    is_active BOOLEAN, 
    plugins JSONB,
    PRIMARY KEY( id )
);

CREATE TABLE IF NOT EXISTS models_attributes (
    mnemo TEXT, 
    name TEXT, 
    description JSONB, 
    PRIMARY KEY( mnemo )
);

CREATE TABLE IF NOT EXISTS models_metrics (
    mnemo TEXT, 
    name TEXT, 
    description JSONB, 
    scale JSONB, 
    PRIMARY KEY( mnemo )
);

CREATE TABLE IF NOT EXISTS models_qms (
    mnemo TEXT, 
    name TEXT, 
    model JSONB, 
    PRIMARY KEY( mnemo )
);

CREATE TABLE IF NOT EXISTS projects_runs (
    id BIGSERIAL, 
    project_id TEXT NOT NULL, 
    run_time TIMESTAMP,
    run_delay INT,
    run_user TEXT,
    metrics JSONB,
    indicators JSONB,
    attributes JSONB,
    attributes_conf JSONB,
    recs JSONB,
    PRIMARY KEY( id )
);

CREATE TABLE IF NOT EXISTS projects_cdata (
    id BIGSERIAL, 
    project_id TEXT, 
    plugin_id TEXT,  
    last_run TIMESTAMP,
    cdata JSONB, 
    PRIMARY KEY( id )
);

CREATE TABLE IF NOT EXISTS projects_info (
    project_id TEXT, 
    last_run TIMESTAMP,
    info JSONB, 
    PRIMARY KEY( project_id )
);
";
}

1;
