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

package Alambic::Model::RepoDB;

use warnings;
use strict;

use Mojo::Pg;
use Mojo::JSON qw( decode_json encode_json );
use Data::Dumper;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(
  init_db
  backup_db
  restore_db
  get_pg_version
  clean_db
  is_db_defined
  is_db_ok
  is_db_empty
  name
  desc
  conf
  get_info
  get_metric
  get_metrics
  set_metric
  del_metric
  get_attribute
  get_attributes
  set_attribute
  get_user
  get_users
  add_user
  del_user
  get_qm
  set_qm
  set_project_conf
  delete_project
  get_project_conf
  get_projects_list
  get_active_projects_list
  add_project_run
  get_project_last_run
  get_project_run
  get_project_all_runs
);

my $pg;

# Create a new RepoDB object.
sub new {
  my ($class, $alambic_db) = @_;

  # Used for tests as a fallback.
  my $db_url = "postgresql://alambic:pass4alambic@/alambic_db";

  if (defined($alambic_db) && $alambic_db =~ /^postgres/) {
    $db_url = $alambic_db;
  }

  $pg = Mojo::Pg->new($db_url);

  return bless {}, $class;
}

# Initialise the database with all tables.
sub init_db() {
  &_db_init();
}

# Start a backup of the Alambic database.
sub backup_db() {
  my ($self) = @_;

  my $sql_out = &_db_query_create();

  my @tables = (
    'conf',              'users',
    'models_attributes', 'models_metrics',
    'models_qms',        'projects_cdata',
    'projects_conf',     'projects_info',
    'projects_runs'
  );

  foreach my $table (@tables) {
    my $results = $pg->db->query("SELECT * FROM $table");
    while (my $next = $results->hash) {
      my @cols = sort keys %{$next};
      my @values_orig
        = map { my $v = $next->{$_}; $v =~ s/'/''/g; "" . $v . "" } @cols;
      my $insert_statement
        = "INSERT INTO $table (" . join(', ', @cols) . ")\n VALUES ('";
      $insert_statement .= join('\', \'', @values_orig) . "');\n";
      $sql_out .= $insert_statement;
    }
  }

  return $sql_out;
}

# Restore a backup by executing the SQL export, re-initialise the
# sequence ids for auto-increment columns.
sub restore_db($) {
  my ($self, $sql_in) = @_;

  my $results = $pg->db->query($sql_in);

  # Now reset the auto-increment columns
  my $next_pr
    = $pg->db->query("SELECT id FROM projects_runs ORDER BY id DESC LIMIT 1;")
    ->hash;
  $next_pr = $next_pr->{'id'} ? $next_pr->{'id'} : 1;
  my $next_cd
    = $pg->db->query("SELECT id FROM projects_cdata ORDER BY id DESC LIMIT 1;")
    ->hash;
  $next_cd = $next_cd->{'id'} ? $next_cd->{'id'} : 1;

  # We want to set the NEXT sequence id.
  $next_pr++;
  $next_cd++;
  $pg->db->query(
    "ALTER SEQUENCE public.projects_runs_id_seq RESTART WITH ${next_pr};");
  $pg->db->query(
    "ALTER SEQUENCE public.projects_cdata_id_seq RESTART WITH ${next_cd};");

  return 1;
}

# Get the PostGres version.
sub get_pg_version() {
  return $pg->db->query('select version() as version;')->hash->{'version'};
}

# Clean the database. Boils down to migrating down the schemas.
sub clean_db() {
  my $active = $pg->migrations()->active;
  $pg->migrations()->migrate(0);
  $active = $pg->migrations()->active;
}

# Get the database status: is the connection string filled in?
sub is_db_defined() {
  if (defined $pg) {
    return 1;
  }
  else {
    return 0;
  }
}


# Checks if the database is ready to be used, i.e. has the correct number
# of tables defined.
sub is_db_ok() {
  my $rows = $pg->db->query(
    "SELECT tablename FROM pg_catalog.pg_tables 
      WHERE schemaname != 'pg_catalog' AND schemaname != 'information_schema';"
  )->rows;

  return $rows == 10 ? 1 : 0;
}


# Checks if the database contains data (counts number of project
# run records). Returns undef if tables do not exist (db is not ok).
sub is_db_empty() {

  my $rows = $pg->db->query(
    "SELECT tablename FROM pg_catalog.pg_tables 
      WHERE schemaname != 'pg_catalog' AND schemaname != 'information_schema';"
  )->rows;

  if ($rows != 10) {
    return undef;
  }

  $rows = $pg->db->query("SELECT COUNT(*) FROM projects_conf;");

  return $rows->rows == 0 ? 1 : 0;

}


# Get or set the Alambic instance name.
sub name($) {
  my ($self, $name) = @_;

  my $ret;
  if (scalar @_ > 1) {
    $pg->db->query("UPDATE conf SET val=? WHERE param='name';", ($name));
    $ret = $name;
  }
  else {
    my $test = $pg->db->query("SELECT val FROM conf WHERE param='name';")->hash;
    $ret = $test->{'val'};
  }

  return $ret;
}


# Get or set the Alambic instance name.
sub desc($) {
  my ($self, $desc) = @_;

  my $ret;
  if (scalar @_ > 1) {
    $pg->db->query("UPDATE conf SET val=? WHERE param='desc';", ($desc));
    $ret = $desc;
  }
  else {
    my $test = $pg->db->query("SELECT val FROM conf WHERE param='desc';")->hash;
    $ret = $test->{'val'};
  }

  return $ret;
}


# Get or set the Alambic instance anonymise_data flag.
sub anonymise_data($) {
  my ($self, $anon) = @_;

  my $ret;
  if (scalar @_ > 1) {
    $pg->db->query("UPDATE conf SET val=? WHERE param='anon';", ($anon));
    $ret = $anon;
  }
  else {
    my $test = $pg->db->query("SELECT val FROM conf WHERE param='anon';")->hash;
    $ret = $test->{'val'};
  }

  return $ret;
}


# Get or set the Alambic instance configuration.
# When getting (no argument provided), the full hash is returned.
# When setting, specify param and value.
sub conf($$$) {
  my ($self, $param, $value) = @_;

  if (scalar @_ > 1) {
    my $query
      = "INSERT INTO conf (param, val) VALUES "
      . "(?, ?) ON CONFLICT (param) DO UPDATE SET (param, val) "
      . "= (?, ?)";
    my $ret = $pg->db->query($query, ($param, $value, $param, $value));
  }

  my %conf;
  my $results = $pg->db->query("SELECT * FROM conf;");
  while (my $next = $results->hash) {
    $conf{$next->{'param'}} = $next->{'val'};
  }

  return \%conf;
}


# Get all info for a project from db.
sub get_info($) {
  my ($self, $project_id) = @_;

  # Execute select in info table.
  my %ret;
  my $results
    = $pg->db->query(
    "SELECT last_run, info FROM projects_info WHERE project_id=?",
    ($project_id));
  while (my $next = $results->hash) {
    $ret{'last_run'} = $next->{'last_run'};
    $ret{'info'}     = decode_json($next->{'info'});
  }

  return \%ret;
}


# Get all metrics definition from db.
sub get_metrics($) {
  my $results = $pg->db->query("SELECT * FROM models_metrics;");
  my $ret;

  # Process one row at a time
  while (my $next = $results->hash) {
    $ret->{$next->{'mnemo'}} = $next;
    $ret->{$next->{'mnemo'}}->{'description'}
      = decode_json($next->{'description'});
    $ret->{$next->{'mnemo'}}->{'scale'} = decode_json($next->{'scale'});
  }

  return $ret || {};
}


# Get a single metric definition from db.
sub get_metric($) {
  my ($self, $mnemo) = @_;
  my ($ret, $results);

  eval {
    $results
      = $pg->db->query("SELECT * FROM models_metrics WHERE mnemo=?;", ($mnemo));
  };

  if ($@) {    #print "# In RepoDB::get_metric Exception.\n" . Dumper($@);
  }

  # Process one row at a time
  while (my $next = $results->hash) {
    $ret->{$next->{'mnemo'}} = $next;
    $ret->{$next->{'mnemo'}}->{'description'}
      = decode_json($next->{'description'});
    $ret->{$next->{'mnemo'}}->{'scale'} = decode_json($next->{'scale'});
  }

  return $ret;
}


# Set a metric definition in the db.
sub set_metric($) {
  my $self  = shift;
  my $mnemo = shift;
  my $name  = shift || '';
  my $desc  = encode_json(shift || []);
  my $scale = encode_json(shift || []);

  my $query
    = "INSERT INTO models_metrics (mnemo, name, description, scale) VALUES "
    . "(?, ?, ?, ?) ON CONFLICT (mnemo) DO UPDATE SET (mnemo, name, description, scale) "
    . "= (?, ?, ?, ?)";
  my $ret = $pg->db->query($query,
    ($mnemo, $name, $desc, $scale, $mnemo, $name, $desc, $scale));

  return $ret;
}


# Delete a metric definition in the db.
sub del_metric($) {
  my $self  = shift;
  my $mnemo = shift;

  my $query = 'DELETE FROM models_metrics WHERE mnemo = ? ';
  my $ret = $pg->db->query($query, ($mnemo));

  # Send signal to reload server.
#  my $ppid = getpid(); print "Reloading $ppid.\n";
  kill USR2  => $$; #$ppid;
  
  return $ret;
}


# Get a single attribute definition from db.
sub get_attribute($) {
  my ($self, $mnemo) = @_;

  my $results = $pg->db->query("SELECT * FROM models_attributes WHERE mnemo=?;",
    ($mnemo));
  my $ret;

  # Process one row at a time
  while (my $next = $results->hash) {
    $ret->{$next->{'mnemo'}} = $next;
    $ret->{$next->{'mnemo'}}->{'description'}
      = decode_json($next->{'description'});
  }

  return $ret;
}


# Get all attributes definition from db;
sub get_attributes($) {
  my $results = $pg->db->query("SELECT * FROM models_attributes;");
  my $ret;

  # Process one row at a time
  while (my $next = $results->hash) {
    $ret->{$next->{'mnemo'}} = $next;
    $ret->{$next->{'mnemo'}}->{'description'}
      = decode_json($next->{'description'});
  }

  return $ret;
}


# Set a attribute definition in the db.
sub set_attribute($) {
  my $self  = shift;
  my $mnemo = shift;
  my $name  = shift || '';
  my $desc  = encode_json(shift || []);

  my $query
    = "INSERT INTO models_attributes (mnemo, name, description) VALUES "
    . "(?, ?, ?) ON CONFLICT (mnemo) DO UPDATE SET (mnemo, name, description) "
    . "= (?, ?, ?)";
  my $ret
    = $pg->db->query($query, ($mnemo, $name, $desc, $mnemo, $name, $desc));

  return $ret;
}


# Delete a attribute definition in the db.
sub del_attribute($) {
  my $self  = shift;
  my $mnemo = shift;

  my $query = 'DELETE FROM models_attributes WHERE mnemo = ? ';
  my $ret = $pg->db->query($query, ($mnemo));

  # Send signal to reload server.
#  my $ppid = getpid(); print "Reloading $ppid.\n";
  kill USR2  => $$; #$ppid;
  
  return $ret;
}


# Get all users from db.
sub get_users() {
  my $results = $pg->db->query("SELECT * FROM users;");
  my $ret;

  # Process one row at a time
  while (my $next = $results->hash) {
    $ret->{$next->{'id'}}               = $next;
    $ret->{$next->{'id'}}->{'roles'}    = decode_json($next->{'roles'});
    $ret->{$next->{'id'}}->{'projects'} = decode_json($next->{'projects'});
    $ret->{$next->{'id'}}->{'notifs'}   = decode_json($next->{'notifs'});
  }

  return $ret;
}


# Get a specific user from db.
sub get_user($) {
  my $self = shift;
  my $user = shift;

  my $results = $pg->db->query("SELECT * FROM users WHERE id=?;", $user);
  my $ret;

  # Process one row at a time
  while (my $next = $results->hash) {
    $ret->{$next->{'id'}}               = $next;
    $ret->{$next->{'id'}}->{'roles'}    = decode_json($next->{'roles'});
    $ret->{$next->{'id'}}->{'projects'} = decode_json($next->{'projects'});
    $ret->{$next->{'id'}}->{'notifs'}   = decode_json($next->{'notifs'});
  }

  return $ret;
}


# Add a user to the db.
sub add_user($$$$$$) {
  my $self     = shift;
  my $id       = shift;
  my $name     = shift;
  my $email    = shift;
  my $passwd   = shift;
  my $roles    = shift;
  my $projects = shift;
  my $notifs   = shift;

  my $roles_json    = encode_json($roles);
  my $projects_json = encode_json($projects);
  my $notifs_json   = encode_json($notifs);

  my $query
    = "INSERT INTO users (id, name, email, passwd, roles, projects, notifs) VALUES "
    . "(?, ?, ?, ?, ?, ?, ?) ON CONFLICT (id) DO UPDATE SET "
    . "(id, name, email, passwd, roles, projects, notifs) "
    . "= (?, ?, ?, ?, ?, ?, ?)";
  my $ret = $pg->db->query(
    $query,
    (
      $id,            $name,          $email,       $passwd,
      $roles_json,    $projects_json, $notifs_json, $id,
      $name,          $email,         $passwd,      $roles_json,
      $projects_json, $notifs_json
    )
  );

  return $ret;
}


# delete a specific user from the db.
sub del_user($) {
  my $self = shift;
  my $uid  = shift;


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
    $ret->{'model'} = decode_json($next->{'model'});
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
  my $self  = shift;
  my $mnemo = shift;
  my $name  = shift || '';
  my $model = encode_json(shift || []);

  my $query
    = "INSERT INTO models_qms (mnemo, name, model) VALUES "
    . "(?, ?, ?) ON CONFLICT (mnemo) DO UPDATE SET (mnemo, name, model) "
    . "= (?, ?, ?)";
  my $ret
    = $pg->db->query($query, ($mnemo, $name, $model, $mnemo, $name, $model));

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
  my $self      = shift;
  my $id        = shift;
  my $name      = shift || '';
  my $desc      = shift || '';
  my $is_active = shift || 0;
  my $plugins   = shift;

  my $plugins_json = encode_json($plugins);
  my $query
    = "INSERT INTO projects_conf VALUES (?, ?, ?, ?, ?) "
    . "ON CONFLICT (id) DO UPDATE SET (name, description, is_active, plugins) "
    . "= (?, ?, ?, ?)";
  $pg->db->query(
    $query,
    (
      $id,   $name, $desc,      $is_active, $plugins_json,
      $name, $desc, $is_active, $plugins_json
    )
  );

  return 1;
}


# Delete from db all entries relatives to a project.
sub delete_project() {
  my ($self, $project_id) = @_;

  # Remove project from table conf_projects
  my $results
    = $pg->db->query("DELETE FROM projects_conf WHERE id=?;", ($project_id));

  # Remove project runs from table projects
  $results = $pg->db->query("DELETE FROM projects_runs WHERE project_id=?;",
    ($project_id));

  return 1;
}


# Get the configuration of a project as a hash.
sub get_project_conf($) {
  my ($self, $id) = @_;

  # See if the project exists
  my %values;
  my $exists  = 0;
  my $results = $pg->db->query(
    "SELECT name, description, is_active, plugins FROM projects_conf WHERE id=?;",
    ($id)
  );

  # There should be 0 or 1 row with this id.
  while (my $next = $results->hash) {
    $exists              = 1;
    $values{'name'}      = $next->{'name'};
    $values{'desc'}      = $next->{'description'};
    $values{'is_active'} = $next->{'is_active'};
    $values{'plugins'}   = decode_json($next->{'plugins'});
    $values{'last_run'}  = '';

    my $results_last_run = $pg->db->query(
      "SELECT run_time FROM projects_runs WHERE project_id=? ORDER BY run_time DESC LIMIT 1;",
      ($id)
    );

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
  my $results = $pg->db->query(
    "SELECT id, name FROM projects_conf WHERE is_active=TRUE;");
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
  my (
    $self,       $project_id,      $run,
    $info,       $metrics,         $indicators,
    $attributes, $attributes_conf, $recs
  ) = @_;

  # Expand information..
  my $run_time  = $run->{'timestamp'};
  my $run_delay = $run->{'delay'};
  my $run_user  = $run->{'user'};

  my $info_json            = encode_json($info)            || '{}';
  my $metrics_json         = encode_json($metrics)         || '{}';
  my $indicators_json      = encode_json($indicators)      || '{}';
  my $attributes_json      = encode_json($attributes)      || '{}';
  my $attributes_conf_json = encode_json($attributes_conf) || '{}';
  my $recs_json            = encode_json($recs)            || '[]';

  # Execute insert in db.
  my $query = "INSERT INTO projects_info 
        ( project_id, last_run, info ) 
      VALUES (?, ?, ?) 
      ON CONFLICT (project_id) DO UPDATE SET ( project_id, last_run, info ) "
    . "= (?, ?, ?)";

  my $id = 0;

  eval {
    my $ret = $pg->db->query($query,
      ($project_id, $run_time, $info_json, $project_id, $run_time, $info_json));
    $id = $ret->hash->{'id'};
  };

  if ($@) {

    #print "# In RepoDB::add_project_run projects_info Exception "
    #. Dumper($@) . "\n";
  }

  # Execute insert in db.
  $query = "INSERT INTO projects_runs 
        ( project_id, run_time, run_delay, run_user, metrics, indicators, attributes, attributes_conf, recs ) 
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        returning id;";

  $id = 0;
  eval {
    $id = $pg->db->query(
      $query,
      (
        $project_id,      $run_time,             $run_delay,
        $run_user,        $metrics_json,         $indicators_json,
        $attributes_json, $attributes_conf_json, $recs_json
      )
    )->hash->{'id'};
  };

  if ($@) {

    #print "# In RepoDB::add_project_run projects_runs Exception "
    #  . Dumper($@) . "\n";
  }

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
  my $query
    = "SELECT * FROM projects_runs WHERE project_id=? ORDER BY id DESC LIMIT 1";

  my $results = $pg->db->query($query, ($id));
  while (my $next = $results->hash) {
    $project{'id'}              = $next->{'id'};
    $project{'project_id'}      = $next->{'project_id'};
    $project{'run_time'}        = $next->{'run_time'};
    $project{'run_delay'}       = $next->{'run_delay'};
    $project{'run_user'}        = $next->{'run_user'};
    $project{'metrics'}         = decode_json($next->{'metrics'});
    $project{'indicators'}      = decode_json($next->{'indicators'});
    $project{'attributes'}      = decode_json($next->{'attributes'});
    $project{'attributes_conf'} = decode_json($next->{'attributes_conf'});
    $project{'recs'}            = decode_json($next->{'recs'} || '[]');
  }

  # Execute select in info table.
  $results = $pg->db->query("SELECT info FROM projects_info WHERE project_id=?",
    ($id));
  while (my $next = $results->hash) {
    $project{'info'} = decode_json($next->{'info'});
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
#  - $project_id the id of the project, e.g. modeling.sirus.
#  - $run_id the id of the run, e.g. 4.
sub get_project_run($$) {
  my ($self, $project_id, $run_id) = @_;

  my %project;

  # Execute select in db.
  my $results
    = $pg->db->query(
    "SELECT * FROM projects_runs WHERE id=? ORDER BY id DESC LIMIT 1",
    ($run_id));
  while (my $next = $results->hash) {
    $project{'id'}              = $next->{'id'};
    $project{'project_id'}      = $next->{'project_id'};
    $project{'run_time'}        = $next->{'run_time'};
    $project{'run_delay'}       = $next->{'run_delay'};
    $project{'run_user'}        = $next->{'run_user'};
    $project{'metrics'}         = decode_json($next->{'metrics'});
    $project{'indicators'}      = decode_json($next->{'indicators'});
    $project{'attributes'}      = decode_json($next->{'attributes'});
    $project{'attributes_conf'} = decode_json($next->{'attributes_conf'});
    $project{'recs'}            = decode_json($next->{'recs'});
  }

  # Execute select in info table.
  # TODO check that works.
  $results = $pg->db->query("SELECT info FROM projects_info WHERE project_id=?",
    ($project_id));
  while (my $next = $results->hash) {
    $project{'info'} = decode_json($next->{'info'});
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
  my $results = $pg->db->query(
    "SELECT id, project_id, run_time, run_delay, run_user FROM projects_runs WHERE project_id=? ORDER BY id DESC",
    ($id)
  );
  my $row = 0;
  while (my $next = $results->hash) {
    $project->[$row]{'id'}         = $next->{'id'};
    $project->[$row]{'project_id'} = $next->{'project_id'};
    $project->[$row]{'run_time'}   = $next->{'run_time'};
    $project->[$row]{'run_delay'}  = $next->{'run_delay'};
    $project->[$row]{'run_user'}   = $next->{'run_user'};
    $row++;
  }

  return $project;
}


# Creates all tables in the database, plus a few default values for conf.
sub _db_init() {

  my $migrations = $pg->migrations();

  $migrations = $migrations->from_string(
    "-- 1 up
" . &_db_query_create() . "
INSERT INTO conf VALUES ('name', 'MyDBNameInit');
INSERT INTO conf VALUES ('desc', 'MyDBDescInit');
INSERT INTO conf VALUES ('anon', '1');
-- 1 down
TRUNCATE conf, users, projects_conf, projects_runs, 
  projects_info, projects_cdata, models_metrics, 
  models_attributes, models_qms;
DROP TABLE IF EXISTS conf;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS projects_conf;
DROP TABLE IF EXISTS projects_runs;
DROP TABLE IF EXISTS projects_info;
DROP TABLE IF EXISTS projects_cdata;
DROP TABLE IF EXISTS models_metrics;
DROP TABLE IF EXISTS models_attributes;
DROP TABLE IF EXISTS models_qms;
"
  );

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


=encoding utf8

=head1 NAME

B<Alambic::Model::RepoDB> - Interface to all database-related actions and
information defined in Alambic.

=head1 SYNOPSIS

    my $repodb = Alambic::Model::RepoDB->new(
      "postgresql://alambic:pass4alambic@/alambic_db"
    );
    
    $repodb->backup();

=head1 DESCRIPTION

B<Alambic::Model::RepoDB> provides a complete interface to all database 
operations within Alambic. As for now only Postgres is supported, but
other database systems may be added in the future while keeping this 
interface mostly as it is. 

=head1 METHODS

=head2 C<new()>

    my $repodb = Alambic::Model::RepoDB->new(
      "postgresql://alambic:pass4alambic@/alambic_db"
    );

Create a new L<Alambic::Model::RepoDB> object and optionally initialise it 
with a database connection.

=head2 C<init_db()>

    $repodb->init_db();

Initialise the database with all tables.

=head2 C<backup_db()>

    $repodb->backup();

Start a backup of the Alambic database. This produces a SQL file with all
data that can be easily re-imported in PostGresql server. Returns a big
SQL file.

=head2 C<restore_db()>

    $repodb->restore_db('INSERT INTO....');

Restore a backup by executing the SQL export, re-initialise the 
sequence ids for auto-increment columns.

=head2 C<get_pg_version()>

    my $version = $repodb->get_pg_version();

Get the PostGres version. Returns a string, e.g. PostgreSQL 9.5.

=head2 C<clean_db()>

    $repodb->clean_db();

Clean the database. Boils down to migrating down the schemas.

=head2 C<is_db_defined()>

    if ($repodb->is_db_defined()) { print "defined!" }

Get the database status: is the connection string filled in? 

=head2 C<is_db_ok()>

    if ($repodb->is_db_ok()) { print "ok!" }

Checks if the database is ready to be used, i.e. has the correct number 
of tables defined.

=head2 C<is_db_empty()>

    if ($repodb->is_db_empty()) { print "empty!" }

Checks if the database contains data (counts number of project 
run records). Returns undef if tables do not exist (db is not ok).

=head2 C<name()>

    my $name = $repodb->name();
    $repodb->name('New name');

Get or set the Alambic instance name.

=head2 C<desc()>

    my $name = $repodb->desc();
    $repodb->desc('New description');

Get or set the Alambic instance name.

=head2 C<conf()>

    my $params = $repodb->conf();
    # Returns a hash ref
    $repodb('param1', 'value1');

Get or set the Alambic instance configuration.
When getting (no argument provided), the full hash is returned.
When setting, specify param and value.

=head2 C<get_info()>

    my $info $repodb->get_info();

Get all info for a project from db.

=head2 C<get_metrics()>

    my $metrics = $repodb->get_metrics();

Get all metrics definition from db.

=head2 C<get_metric()>

    my $metric = epodb->get_metric('METRIC1');

Get a single metric definition from db.

=head2 C<get_attribute()>

    my $attr = $repodb->get_attribute('ATTR1');

Get a single attribute definition from db.

=head2 C<get_attributes()>

    my $attrs = $repodb->get_attributes();

Get all attributes definition from db.

=head2 C<set_attribute()>

    $repodb->set_attribute(
      'MNEMO', 'ATTR_NAME', ['desc', 'desc']
    );

Set a attribute definition in the db.

=head2 C<get_users()>

    my $users = $repodb->get_users();

Get all users from db.

=head2 C<get_user()>

    my $user = $repodb->get_user('boris');

Get a specific user from db.

=head2 C<add_user()>

    $repodb->add_user(
      'boris', 'Boris Baldassari', 'boris@domain.com',
      'password', ['Admin'], {}, {}
    )

Add a user to the database.

=head2 C<del_user()>

    $repodb->del_user('boris');

Delete a user from the database.

=head2 C<get_qm()>

    my $qm = $repodb->get_qm();

Get a single qm definition from db (the first record as for now).

=head2 C<set_qm()>

    $repodb->set_qm(
      'MNENMO', 'My Model Name', {}
    );

Set a qm definition in the db.

=head2 C<set_project_conf()>

    $repodb->set_project_conf(
      'project_id', 'Project Name', 
      'Project Desc', { 'PLUG1' => {} }
    );

Add or edit a project in the list of projects, with its name, desc, and plugins.

=head2 C<delete_project()>

    $repodb->delete_project('modeling.sirius');

Delete from db all entries relatives to a project.

=head2 C<get_project_conf()>

    my $project_conf = $repodb->get_project_conf('modeling.sirius');

Get the configuration of a project as a hash.

=head2 C<get_projects_list()>

    my $list = $repodb->get_projects_list();



=head2 C<get_active_projects_list()>

    my $list = $repodb->get_active_projects_list();

Returns a hash of projects id/names defined in the db.

=head2 C<add_project_run()>

    $repodb->add_project_run(
      'project_id', \%run_info, 
      \%info, \%metrics, \%indicators
      \%atttributes, \Mattributes_conf
      \%recs
    );

Stores the results of a job run in Alambic.

=head2 C<get_project_last_run()>

    my $last_run = $repodb->get_project_last_run();

Returns the results of the last job run in Alambic for the specified project.

    {
      'attributes' => { 'MYATTR' => 18 },
      'id' => 2,
      'indicators' => { 'MYINDIC' => 16 },
      'metrics' => { 'MYMETRIC' => 15 },
      'project_id' => 'modeling.sirius',
      'recs' => [
        {
          'desc' => 'This is a description.',
          'severity' => 3,
          'rid' => 'REC_PMI_11'
        }
      ],
      'run_delay' => 113,
      'run_time' => '2016-05-08 16:53:57',
      'run_user' => 'none'
    }


=head2 C<get_project_run()>

    my $run = $repodb->get_project_run('modeling.sirius', 5);

Returns the results of the specified job run in Alambic for the specified project.

=head2 C<get_project_all_runs()>

    my $runs = $repodb->get_project_all_runs($project_id);

Returns an array of basic information of all runs in Alambic 
for the specified project.
    
    [
      {
        'id' => 2,
        'project_id' => 'modeling.sirius',
        'run_delay' => 113,
        'run_time' => '2016-05-08 16:53:20',
        'run_user' => 'none'
      },
      {
        'id' => 1,
        'project_id' => 'modeling.sirius',
        'run_delay' => 13,
        'run_time' => '2016-05-08 16:53:20',
        'run_user' => 'none'
      }
    ]

=head1 SEE ALSO

L<Mojolicious>, L<http://alambic.io>, L<https://bitbucket.org/BorisBaldassari/alambic>

=cut

