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

package Alambic::Model::Alambic;

use warnings;
use strict;

use Alambic::Model::Project;
use Alambic::Model::RepoDB;
use Alambic::Model::RepoFS;
use Alambic::Model::Plugins;
use Alambic::Model::Wizards;
use Alambic::Model::Models;
use Alambic::Model::Users;
use Alambic::Model::Tools;

use Data::Dumper;
use DateTime;
use POSIX;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(
  backup
  restore
  instance_name
  instance_desc
  instance_version
  instance_pg_alambic
  instance_pg_minion
  is_db_ok
  is_db_m_ok
  get_plugins
  get_models
  get_tools
  get_repo_db
  get_repo_fs
  get_wizards
  users
  set_user
  set_user_project
  get_user
  del_user
  create_project
  create_project_from_wizard
  get_project
  set_project
  get_projects_list
  add_project_plugin
  del_project_plugin
  get_project_hist
  get_project_last_run
  get_project_run
  run_project
  run_plugins
  run_qm
  run_posts
  run_globals
  delete_project
);

my $config;
my $repodb;
my $repofs;
my $plugins;
my $wizards;
my $models;
my $tools;
my $al_version;


# Create a new Alambic object.
sub new {
  my ($class, $config_opt) = @_;

  $config = $config_opt;
  my $pg_alambic = $config->{'conf_pg_alambic'};
  $al_version = $config->{'alambic_version'};

  $repodb  = Alambic::Model::RepoDB->new($pg_alambic);
  $repofs  = Alambic::Model::RepoFS->new();
  $plugins = Alambic::Model::Plugins->new();
  $wizards = Alambic::Model::Wizards->new();
  $tools   = Alambic::Model::Tools->new();

  # If the database is not initialised, then init it.
  if (not &is_db_ok()) {
    die "
Database is not initialised. Please first execute:\n
\$ bin/alambic init\n
And restart alambic.\n";
  }

  # Retrieve all metrics definition to initialise Models.pm
  my $metrics    = $repodb->get_metrics();
  my $attributes = $repodb->get_attributes();
  my $qm         = $repodb->get_qm();
  $models = Alambic::Model::Models->new($metrics, $attributes, $qm,
    $plugins->get_conf_all());

  return bless {}, $class;
}


# Create a backup of the Alambic DB.
sub backup() {
  return $repodb->backup_db();
}


# Restore a SQL string into the Alambic DB.
sub restore($) {
  my ($self, $sql) = @_;

  $repodb->restore_db($sql);
}


# Get or set the instance name.
sub instance_name($) {
  my ($self, $name) = @_;

  if (scalar @_ > 1) {
    $repodb->name($name);
  }

  return $repodb->name();
}

# Get or set the instance description.
sub instance_desc($) {
  my ($self, $desc) = @_;

  if (scalar @_ > 1) {
    $repodb->desc($desc);
  }

  return $repodb->desc();
}

# Get the version of Alambic running this instance.
sub instance_version($) {
  my ($self) = @_;

  return $al_version;
}

# Get the postgresql configuration for alambic.
sub instance_pg_alambic() {
  return $config->{'conf_pg_alambic'};
}

# Get the postgresql configuration for minion.
sub instance_pg_minion() {
  return $config->{'conf_pg_minion'};
}

# Get boolean to check if the alambic db can be used.
sub is_db_ok() {
  return $repodb->is_db_ok();
}

# Get boolean to check if the minion db information is defined.
sub is_db_m_ok() {
  my $pg_minion = $config->{'conf_pg_minion'};
  return (defined($pg_minion) && $pg_minion =~ m!^postgres!) ? 1 : 0;
}


# Return the Plugins.pm object for this instance.
sub get_plugins() {
  return $plugins;
}


# Return the Models.pm object for this instance.
sub get_models() {
  return $models;
}

# Return the Tools.pm object for this instance.
sub get_tools() {
  return $tools;
}

# Return the RepoFS.pm object for this instance.
sub get_repo_fs() {
  return $repofs;
}

# Return the RepoDB.pm object for this instance.
sub get_repo_db() {
  return $repodb;
}

# Return the Wizards.pm object for this instance.
sub get_wizards() {
  return $wizards;
}

# Return the list of users with their information.
# my $users = {
#   'boris.baldassari' => {
#     'name' => 'Boris Baldassari',
#     'email' => 'boris.baldassari@domain.com',
#     'passwd' => 'password',
#     'roles' => [ 'admin' ],
#     'projects' => [ 'modeling.sirius' ],
#     'notifs' => {
# 	'modeling.sirius' => [ 'run_complete' ],
#     },
#   },
# };
sub users() {

  my $users = $repodb->get_users();

  return Alambic::Model::Users->new($users);
}

# Add or update user to the Alambic db.
sub set_user($$$$$$$) {
  my $self     = shift;
  my $id       = shift;
  my $name     = shift;
  my $email    = shift;
  my $passwd   = shift;
  my $roles    = shift;
  my $projects = shift;
  my $notifs   = shift;

  # If password not modified, then just keep the old one.
  if ($passwd =~ /^$/ and exists $repodb->get_users()->{$id}) {
    $passwd = $repodb->get_users()->{$id}{'passwd'};
  }
  else {
    my $users = Alambic::Model::Users->new({});
    $passwd = $users->generate_passwd($passwd);
  }

  return $repodb->add_user($id, $name, $email, $passwd, $roles, $projects,
    $notifs);
}

# Add or update a project in a user profile
sub set_user_project($$$) {
  my $self       = shift;
  my $user_id    = shift;
  my $project_id = shift;
  my $content    = shift;

  my $user = $repodb->get_user($user_id)->{$user_id};
  $user->{'projects'}{$project_id} = $content;
  return $repodb->add_user(
    $user->{'id'},     $user->{'name'},  $user->{'email'},
    $user->{'passwd'}, $user->{'roles'}, $user->{'projects'},
    $user->{'notifs'}
  );
}

# Get information for a single user.
sub get_user($) {
  my $self = shift;
  my $id   = shift;

  if (exists $repodb->get_users()->{$id}) {
    return $repodb->get_users()->{$id};
  }
  else {
    return undef;
  }
}

# Delete a user from the database.
sub del_user($) {
  my $self = shift;
  my $uid  = shift;

  my $users = $repodb->del_user($uid);
}


# Create a project with no plugin.
#
# Params
#  - id the project id.
#  - name the name of the project.
#  - desc the description of the project.
#  - active boolean (TRUE|FALSE) is the project active.
# Returns
#  - Project object.
sub create_project($$) {
  my $self   = shift;
  my $id     = shift;
  my $name   = shift;
  my $desc   = shift;
  my $active = shift || 0;

  my $ret = $repodb->set_project_conf($id, $name, $desc, $active, {});

  # $ret == 0 means the insert didn't work.
  if ($ret == 0) {
    return 0;
  }

  my $project = Alambic::Model::Project->new($id, $name);
  $project->desc($desc);
  $project->active($active);

  return $project;
}


# Create a project from a wizard.
#
# Params
#  - wizard the wizard id.
#  - id the project id.
# Returns
#  - Project object.
sub create_project_from_wizard($$) {
  my $self       = shift;
  my $wiz_id     = shift;
  my $project_id = shift;
  my $conf       = shift;

  my $ret_wiz = $wizards->get_wizard($wiz_id)->run_wizard($project_id, $conf);
  my $project = $ret_wiz->{'project'};

  my $ret = $repodb->set_project_conf($project_id, $project->name(),
    $project->desc(), 0, $project->get_plugins());

  # $ret == 0 means the insert didn't work.
  if ($ret == 0) {
    return undef;
  }

  return $ret_wiz;
}


# Get a Project object from its id.
# The project is populated with data (metrics, attributes, recs)
# if available.
#
# Params
#  - id the id of the project to be retrieved.
sub get_project($) {
  my ($self, $project_id) = @_;
  return &_get_project($project_id);
}


# Set properties of a project from its id.
#
# Params
#  - id the id of the project to be set.
#  - name the name of the project to be set.
#  - desc the desc of the project to be set.
#  - active the is_active flag of the project to be set.
#  - plugins the plugins conf of the project to be set.
sub set_project($$$$$) {
  my $self       = shift;
  my $project_id = shift || '';
  my $name       = shift || '';
  my $desc       = shift || '';
  my $active     = shift || '';
  my $plugins    = shift || {};

  my $project = $repodb->get_project_conf($project_id);

  if ($name !~ m!^$!)   { $project->{'name'}   = $name }
  if ($desc !~ m!^$!)   { $project->{'desc'}   = $desc }
  if ($active !~ m!^$!) { $project->{'active'} = $active }
  if (ref($plugins) =~ m!^HASH$! && scalar keys %$plugins > 1) {
    $project->{'plugins'} = $plugins;
  }

  $repodb->set_project_conf(
    $project_id,          $project->{'name'}, $project->{'desc'},
    $project->{'active'}, $project->{'plugins'}
  );
}


# Get a Project object identified by its id.
sub _get_project($) {
  my ($id) = @_;

  my $project_conf = $repodb->get_project_conf($id);
  if (not defined($project_conf)) { return undef }

  my $project_data = $repodb->get_project_last_run($id);

  my $project = Alambic::Model::Project->new(
    $id,
    $project_conf->{'name'},
    $project_conf->{'is_active'},
    $project_conf->{'last_run'},
    $project_conf->{'plugins'},
    $project_data
  );
  $project->desc($project_conf->{'desc'});

  return $project;
}


# Get a hash ref of all project ids with their names.
#
# Params
#  - is_active (1|0) list only active projects?
# Returns
#  - $projects = {
#      "modeling.sirius" => "Sirius",
#      "tools.cdt" => "CDT",
#    }
sub get_projects_list() {
  my $self = shift;
  my $is_active = shift || '';

  my $projects_list = {};
  if ($repodb->is_db_ok()) {
    if ($is_active) {
      $projects_list = $repodb->get_active_projects_list();
    }
    else {
      $projects_list = $repodb->get_projects_list();
    }
  }

  return $projects_list;
}


# Add or set a plugin to the project configuration.
#
# Params
#  - project_id the project id.
#  - plugin_id the plugin id.
#  - plugin_conf a hash ref for the plugin configuration.
sub add_project_plugin() {
  my ($self, $project_id, $plugin_id, $project_conf) = @_;

  my $conf = $repodb->get_project_conf($project_id);

  # Add plugin conf to the hash of all plugins conf
  $conf->{'plugins'}->{$plugin_id} = $project_conf;

  $repodb->set_project_conf($project_id, $conf->{'name'}, $conf->{'desc'},
    $conf->{'is_active'}, $conf->{'plugins'});

  return 1;
}


# Delete a plugin from the project configuration.
#
# Params
#  - project_id the project id.
#  - plugin_id the plugin id.
sub del_project_plugin() {
  my ($self, $project_id, $plugin_id) = @_;

  my $conf = $repodb->get_project_conf($project_id);

  # Add plugin conf to the hash of all plugins conf
  delete $conf->{'plugins'}->{$plugin_id};

  $repodb->set_project_conf($project_id, $conf->{'name'}, $conf->{'desc'},
    $conf->{'is_active'}, $conf->{'plugins'});

  return 1;
}


# Retrieve history of runs for a project.
sub get_project_hist($) {
  my $self       = shift;
  my $project_id = shift;

  return $repodb->get_project_all_runs($project_id);

}

# Return all data for the last run of the project
# Params:
#  * project_id
sub get_project_last_run($) {
  my $self       = shift;
  my $project_id = shift;

  return $repodb->get_project_last_run($project_id);
}


# Return all data for a specific run
# Params:
#  * project_id
#  * run_id
sub get_project_run($$) {
  my $self       = shift;
  my $project_id = shift;
  my $run_id     = shift;

  return $repodb->get_project_run($project_id, $run_id);
}

# Return all data for all runs
# Params:
#  * project_id
# Returns
#  - $ret = [
#      {
#        "metrics" => {'metric1' => 'value1'},
#        "indicators" => {'ind1' => 'value1'},
#        "attributes" => {'attr1' => 'value1'},
#        "attributes_conf" => {'attr1' => 'value1'},
#        "infos" => {'info1' => 'value1'},
#        "recs" => [{'rec1'}, {'value1'}],
#        "log" => ['log entry'],
#      },
#      {
#        "metrics" => {'metric1' => 'value1'},
#        "indicators" => {'ind1' => 'value1'},
#        "attributes" => {'attr1' => 'value1'},
#        "attributes_conf" => {'attr1' => 'value1'},
#        "infos" => {'info1' => 'value1'},
#        "recs" => [{'rec1'}, {'value1'}],
#        "log" => ['log entry'],
#      },
sub get_project_all_runs($$) {
  my $self       = shift;
  my $project_id = shift;

  my @data;

  my $runs = $repodb->get_project_all_runs($project_id);
  for my $run (@$runs) {
      my $rundata = $repodb->get_project_run($project_id, $run->{'id'});
      push( @data, $rundata );
  }

  return \@data;
}


# Run a full analysis on a project: plugins, qm, post plugins.
#
# Params
#  - id the project id.
# Returns
#  - $ret = {
#      "metrics" => {'metric1' => 'value1'},
#      "indicators" => {'ind1' => 'value1'},
#      "attributes" => {'attr1' => 'value1'},
#      "attributes_conf" => {'attr1' => 'value1'},
#      "infos" => {'info1' => 'value1'},
#      "recs" => [{'rec1'}, {'value1'}],
#      "log" => ['log entry'],
#    }
sub run_project($) {
  my ($self, $project_id, $user) = @_;

  my $time_start       = DateTime->now();
  my $time_start_epoch = $time_start->epoch();
  my $run              = {
    'timestamp' =>
      strftime("%Y-%m-%d %H:%M:%S\n", localtime($time_start_epoch)),
    'delay' => 0,
    'user'  => $user || 'unknown',
  };

  my $project       = &_get_project($project_id);
  my $values        = $project->run_project($models);
  my $time_finished = DateTime->now();
  my $delay         = $time_finished - $time_start;
  $run->{'delay'} = $delay->in_units('seconds');

  my $ret
    = $repodb->add_project_run($project_id, $run, $values->{'info'},
    $values->{'metrics'}, $values->{'inds'}, $values->{'attrs'},
    $values->{'attrs_conf'},
    $values->{'recs'});

  # Now get user profiles
  my $users = &users($self);
  my $list  = $users->get_users();

  # Read files containing user references
  # and store them in the user's project section.
  my $users_ = $repofs->read_users($project_id);
  foreach my $u (keys %$list) {
    my $email = $list->{$u}->{'email'};
    if (exists($users_->{$email})) {
      &set_user_project($self, $u, $project_id, $users_->{$email});
    }
  }

  return $values;
}


# Run all pre-plugins on a project. Results will NOT be stored in db
# (only full runs are actually stored).
#
# Params
#  - id the project id.
# Returns
#  - $ret = {
#      "cdata" => [ {'author' => 'so', 'mesg' => 'value1'} ],
#      "metrics" => {'metric1' => 'value1'},
#      "indicators" => {'ind1' => 'value1'},
#      "attributes" => {'attr1' => 'value1'},
#      "attributes_conf" => {'attr1' => 'value1'},
#      "infos" => {'info1' => 'value1'},
#      "recs" => ['rec1', 'rec2'],
#      "log" => ['log entry'],
#    }
sub run_plugins($) {
  my ($self, $project_id) = @_;

  my $project = &_get_project($project_id);
  my $values  = $project->run_plugins();

  return $values;
}


# Compute indicators and populate the quality model.
#
# Params
#  - id the project id.
# Returns
#  - $ret = {
#      "metrics" => {'metric1' => 'value1'},
#      "indicators" => {'ind1' => 'value1'},
#      "attributes" => {'attr1' => 'value1'},
#      "attributes_conf" => {'attr1' => 'value1'},
#      "log" => ['log entry'],
#    }
sub run_qm($) {
  my ($self, $project_id) = @_;

  my $project = &_get_project($project_id);
  my $values  = $project->run_qm($models);

  return $values;
}


# Run all post plugins for the project.
#
# Params
#  - id the project id.
# Returns
#  - $ret = {
#      "metrics" => {'metric1' => 'value1'},
#      "indicators" => {'ind1' => 'value1'},
#      "attributes" => {'attr1' => 'value1'},
#      "attributes_conf" => {'attr1' => 'value1'},
#      "infos" => {'info1' => 'value1'},
#      "recs" => ['rec1' => 'value1'],
#      "log" => ['log entry'],
#    }
sub run_posts($) {
  my ($self, $project_id) = @_;

  my $project = &_get_project($project_id);
  my $values  = $project->run_posts($models);

  return $values;
}


# Run global plugins.
sub run_globals() {

}

# Delete a project from the Alambic instance.
# This removes database records and all files associated
# to the project on the file system.
sub delete_project($) {
  my ($self, $project_id) = @_;

  $repodb->delete_project($project_id);
  $repofs->delete_project($project_id);

  return 1;
}


1;


=encoding utf8

=head1 NAME

B<Alambic::Model::Alambic> - The main class to interact with the Alambic application.

=head1 SYNOPSIS

    my $alambic = Alambic::Model::Alambic->new(
      {
        'conf_pg_alambic' => 'postgresql://alambic:pass4alambic@/minion_db',
        'alambic_version' => '3.3.2', 
      }
    )
    
    my $sql = $alambic->backup();
    $alambic->restore($sql);
    $alambic->run_project('modeling.sirius');

=head1 DESCRIPTION

B<Alambic::Model::Alambic> provides an almost complete interface to the Alambic application. Most 
features provided by L<Almabic::Model::Controllers> and L<Alambic::Model::Commands> are actually
executed by this class, from database queries to project execution and backups.

=head1 METHODS

=head2 C<new()>

    my $alambic = Alambic::Model::Alambic->new(
      {
        'conf_pg_alambic' => 'postgresql://alambic:pass4alambic@/minion_db',
        'alambic_version' => '3.3.2', 
      }
    )

Creates a new Alambic object to interact with the Alambic instance and features.

=head2 C<backup()>

Create a backup of the Alambic DB.

=head2 C<restore()>

    $alambic->restore($my_complete_sql_string);

Restore a SQL string into the Alambic DB.

=head2 C<instance_name()>

    my $name = $instance_bname();
    
    $instance_name('My new name for this instance.');

Get or set the instance name.

=head2 C<instance_desc()>

    my $desc = $instance_desc();
    
    $instance_desc('My new description of this instance.');

Get or set the instance description.

=head2 C<instance_version()>

Get the version of Alambic running this instance.

=head2 C<instance_pg_alambic()>

Get the postgresql configuration for alambic.

=head2 C<instance_pg_minion()>

Get the postgresql configuration for minion.

=head2 C<is_db_ok()>

Get boolean to check if the alambic db can be used.

=head2 C<is_db_m_ok()>

Get boolean to check if the minion db information is defined.

=head2 C<get_plugins()>

Return the Plugins.pm object for this instance.

=head2 C<get_models()>

Return the Models.pm object for this instance.

=head2 C<get_tools()>

Return the Tools.pm object for this instance.

=head2 C<get_repo_fs()>

Return the RepoFS.pm object for this instance.

=head2 C<get_repo_db()>

Return the RepoDB.pm object for this instance.

=head2 C<get_wizards()>

Return the Wizards.pm object for this instance.

=head2 C<users()>

Return the list of users with their information. 

    my $users = {
      'boris.baldassari' => {
        'name' => 'Boris Baldassari',
        'email' => 'boris.baldassari@domain.com',
        'passwd' => 'password',
        'roles' => [ 'admin' ],
        'projects' => [ 'modeling.sirius' ],
        'notifs' => {
          'modeling.sirius' => [ 'run_complete' ],
        },
      },
    };

=head2 C<set_user()>

    $self->app->al->set_user('administrator', 'Administrator',
      'alambic@castalia.solutions', 'password', ['Admin'], {}, {});

Add or update user to the Alambic db.

=over

=item * id 

=item * name

=item * email

=item * password

=item * roles (array reference)

=item * projects (hash reference)

=item * notifications (hash reference)

=back

=head2 C<set_user_project()>

    $al->set_user_project($user_id, $project_id, $content);

Add or update a project in a user profile.

=over

=item * user_id 

=item * project_id

=item * content

=back

=head2 C<get_user()>

    $al->get_user('boris');

Get information for a single user.

=head2 C<del_user()>

    $al->get_user('boris');

Delete a user from the database.

=head2 C<create_project()>

    $self->app->al->create_project(
      $project_id, $project_name, 
      $plugins,
      $project_active);

Create and return an empty project (i.e. with no plugin).

=over

=item * project id 

=item * project name 

=item * project description

=item * is active (boolean) 

=back

=head2 C<create_project_from_wizard()>

    $self->app->al->create_project_from_wizard(
      $wizard_id,
      $project_id,
      $conf,
    );

Create and return a new project from a wizard.

=over

=item * wizard id (e.g. EclipsePmi)

=item * project id

=item * configuration

    {
      'param1' => 'value1',
      'param2' => 'value2',
    }

=back

=head2 C<get_project()>

    my $project = $alambic->get_project('modeling.sirius');

Get a Project object from its id. The project is populated with data
(metrics, attributes, recs) if available.

=head2 C<set_project()>

    my $project = $self->app->al->set_project(
      $project_id, 
      $project_name, 
      $project_desc,
      $project_active
    );


Set properties of a project from its id.

=over

=item * id the id of the project to be set.

=item * name the name of the project to be set.

=item * desc the desc of the project to be set.

=item * active the is_active flag of the project to be set.

=item * plugins the plugins conf of the project to be set.

=back

=head2 C<get_projects_list()>

    my $projects_list = $alambic->get_projects_list();

Get a hash ref of all project ids with their names. Returns:

    $projects = {
      "modeling.sirius" => "Sirius",
      "tools.cdt" => "CDT",
    }

=over

=item * is_active (optional) should inactive project be returned as well?

=back

=head2 C<add_project_plugin()>

    $self->app->al->add_project_plugin($project_id, $plugin_id, \%args);

Add or set a plugin to the project configuration.

=over

=item * project_id the project id.

=item * plugin_id the plugin id.

=item * plugin_conf a hash ref for the plugin configuration.

    {
      'param1' => 'value1',
      'param2' => 'value2',
    }

=back

=head2 C<del_project_plugin()>

    $self->app->al->del_project_plugin($project_id, $plugin_id);

Delete a plugin from the project configuration.

=over

=item * project_id the project id.

=item * plugin_id the plugin id.

=back

=head2 C<get_project_hist()>

    my $hist = $self->app->al->get_project_hist($project_id);

Retrieve history of runs for a project. Only basic information is returned, 
subsequent calls to get_project_run will be required to actually get the
data. Returns an array of hashes:

    [
      {
        'run_time' => '2017-07-29 09:00:08',
        'id' => 3,
        'run_delay' => 49,
        'project_id' => 'modeling.sirius',
        'run_user' => 'administrator'
      },
      {
        'id' => 2,
        'run_delay' => 44,
        'project_id' => 'modeling.sirius',
        'run_time' => '2017-07-29 08:54:35',
        'run_user' => 'administrator'
      },
      {
        'run_user' => 'administrator',
        'run_time' => '2017-07-29 08:53:12',
        'project_id' => 'modeling.sirius',
        'id' => 1,
        'run_delay' => 47
      }
    ];


=head2 C<get_project_last_run()>

    my $runs = $alambic->get_project_last_run('modeling.sirius');

Return all data for the last run of the project.

    {
      'recs' => [
        {
          'desc' => 'The title entry is empty in the PMI.',
          'severity' => 2,
          'rid' => 'PMI_EMPTY_TITLE',
          'src' => 'EclipsePmi'
        }
      ],
      'attributes_conf' => undef,
      'run_delay' => 49,
      'project_id' => 'modeling.sirius',
      'metrics' => {
        'CI_JOBS_FAILED_1W' => 7,
      },
      'info' => {
        'PMI_SCM_URL' => 'http://git.eclipse.org/c/sirius/org.eclipse.sirius.legacy.git',
      },
      'id' => 3,
      'run_user' => 'administrator',
      'indicators' => undef,
      'attributes' => undef,
      'run_time' => '2017-07-29 09:00:08'
    }


=head2 C<get_project_run()>

    my $run = $alambic->get_project_run('modeling.sirius', 3);

Return all data for a specific run.

    {
      'recs' => [
        {
          'desc' => 'The title entry is empty in the PMI.',
          'severity' => 2,
          'rid' => 'PMI_EMPTY_TITLE',
          'src' => 'EclipsePmi'
        }
      ],
      'attributes_conf' => undef,
      'run_delay' => 49,
      'project_id' => 'modeling.sirius',
      'metrics' => {
        'CI_JOBS_FAILED_1W' => 7,
      },
      'info' => {
        'PMI_SCM_URL' => 'http://git.eclipse.org/c/sirius/org.eclipse.sirius.legacy.git',
      },
      'id' => 3,
      'run_user' => 'administrator',
      'indicators' => undef,
      'attributes' => undef,
      'run_time' => '2017-07-29 09:00:08'
    }


=head2 C<get_project_all_runs()>

    my $run = $alambic->get_project_all_runs('modeling.sirius');

Return all data for all runs.

    {
      'recs' => [
        {
          'desc' => 'The title entry is empty in the PMI.',
          'severity' => 2,
          'rid' => 'PMI_EMPTY_TITLE',
          'src' => 'EclipsePmi'
        }
      ],
      'attributes_conf' => undef,
      'run_delay' => 49,
      'project_id' => 'modeling.sirius',
      'metrics' => {
        'CI_JOBS_FAILED_1W' => 7,
      },
      'info' => {
        'PMI_SCM_URL' => 'http://git.eclipse.org/c/sirius/org.eclipse.sirius.legacy.git',
      },
      'id' => 3,
      'run_user' => 'administrator',
      'indicators' => undef,
      'attributes' => undef,
      'run_time' => '2017-07-29 09:00:08'
    }

=head2 C<run_project()>

    my $results = $alambic->run_project('modeling.sirius');

Run a full analysis on a project, including pre- plugins, qm, post- plugins. 
Returns a hash ref with all information about the run.

    {
      "metrics" => {'metric1' => 'value1'},
      "indicators" => {'ind1' => 'value1'},
      "attributes" => {'attr1' => 'value1'},
      "attributes_conf" => {'attr1' => 'value1'},
      "infos" => {'info1' => 'value1'},
      "recs" => [{'rec1'}, {'rec2'}],
      "log" => ['log entry'],
    }

=head2 C<run_plugins()>

    my $results = $alambic->run_plugins('modeling.sirius');

Run all pre-plugins on a project. Results will NOT be stored in db (only full runs are actually stored).
Returns a hash ref with all information about the run.

    {
      "metrics" => {'metric1' => 'value1'},
      "indicators" => {'ind1' => 'value1'},
      "attributes" => {'attr1' => 'value1'},
      "attributes_conf" => {'attr1' => 'value1'},
      "infos" => {'info1' => 'value1'},
      "recs" => [{'rec1'}, {'rec2'}],
      "log" => ['log entry'],
    }

=head2 C<run_qm()>

    my $results = $alambic->run_qm('modeling.sirius');

Compute indicators and populate the quality model. 
Returns a hash reference with all computation results.

    {
      "metrics" => {'metric1' => 'value1'},
      "indicators" => {'ind1' => 'value1'},
      "attributes" => {'attr1' => 'value1'},
      "attributes_conf" => {'attr1' => 'value1'},
      "log" => ['log entry'],
    }

=head2 C<run_posts()>

    my $results = $alambic->run_posts('modeling.sirius');

Run all post plugins for the project. Returns a hash reference with all 
information returned by post plugins.

    {
      "metrics" => {'metric1' => 'value1'},
      "indicators" => {'ind1' => 'value1'},
      "attributes" => {'attr1' => 'value1'},
      "attributes_conf" => {'attr1' => 'value1'},
      "infos" => {'info1' => 'value1'},
      "recs" => [{'rec1'}, {'rec2'}],
      "log" => ['log entry'],
    }


=head2 C<run_globals()>

TODO. NOT IMPLEMENTED.

=head2 C<delete_project()>

    $alambic->delete_project('modelings.sirius');

Delete a project from the Alambic instance. 
This removes database records and all files associated to the project on the file system.

=head1 SEE ALSO

L<Mojolicious>, L<http://alambic.io>, L<https://bitbucket.org/BorisBaldassari/alambic>

=cut

