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

package Alambic::Controller::Admin;
use Mojo::Base 'Mojolicious::Controller';

use Mojo::JSON qw( encode_json decode_json );
use Data::Dumper;
use File::stat;
use Time::localtime;

# Main screen for Alambic admin.
sub summary {
  my $self = shift;

  $self->render(template => 'alambic/admin/summary');
}


# Edit information about the instance
sub edit {
  my $self = shift;

  $self->stash(
    name => $self->app->al->instance_name(),
    desc => $self->app->al->instance_desc(),
    gt   => $self->app->al->get_repo_db()->conf()->{'google_tracking'},
  );
  $self->render(template => 'alambic/admin/instance_edit');
}


# Edit information about the instance -- post
sub edit_post {
  my $self = shift;

  # Get values from form.
  my $name = $self->param('name');
  my $desc = $self->param('desc');
  my $gt   = $self->param('google-tracking');

  $self->app->al->get_repo_db()->name($name);
  $self->app->al->get_repo_db()->desc($desc);
  $self->app->al->get_repo_db()->conf('google-tracking', $gt);

  $self->flash(msg => "Instance details have been saved.");
  $self->redirect_to('/admin/summary');
}


# JSON access for models data.
sub data_models {
  my $self = shift;
  my $page = $self->param('page');

  my $models = $self->app->al->get_models();

  if ($page =~ m!^attributes.json$!) {
    $self->render(json => $models->get_attributes());

  }
  elsif ($page =~ m!^attributes_full.json$!) {
    $self->render(json => $models->get_attributes_full());

  }
  elsif ($page =~ m!^metrics.json$!) {
    $self->render(json => $models->get_metrics());

  }
  elsif ($page =~ m!^metrics_full.json$!) {
    $self->render(json => $models->get_metrics_full());

  }
  elsif ($page =~ m!^qm.json$! || $page =~ m!^quality_model.json$!) {
    $self->render(json => $models->get_qm());

  }
  elsif ($page =~ m!^qm_full.json$! || $page =~ m!^quality_model_full.json$!) {
    $self->render(json => $models->get_qm_full());

  }
  else {
    $self->render(json => {});
  }
}

# Models display screen for Alambic admin.
sub models {
  my $self = shift;

  my $models = $self->app->al->get_models();

  # Get list of metrics definition files.
  my @files_metrics    = <lib/Alambic/files/models/metrics/*.json>;
  my @files_attributes = <lib/Alambic/files/models/attributes/*.json>;
  my @files_qm         = <lib/Alambic/files/models/qm/*.json>;

  $self->stash(
    files_metrics    => \@files_metrics,
    files_attributes => \@files_attributes,
    files_qm         => \@files_qm,
    models           => $models,
  );

  $self->render(template => 'alambic/admin/models');
}

# Display list of users for Alambic admin.
sub users {
  my $self = shift;

  $self->render(template => 'alambic/admin/users');
}

# Add a user.
sub users_new {
  my $self = shift;

  $self->render(template => 'alambic/admin/users_set');
}

# Add a user -- POST.
sub users_new_post {
  my $self = shift;

  my $id     = $self->param('id');
  my $name   = $self->param('name');
  my $email  = $self->param('email');
  my $passwd = $self->param('passwd');

  my @roles;
  foreach my $role (@{$self->app->al->users->get_roles()}) {
    if ($self->param('roles_' . $role)) { push(@roles, $role) }
  }

  my $projects = $self->param('projects');
  my $notifs   = $self->param('notifs');

  my $project
    = $self->app->al->set_user($id, $name, $email, $passwd, \@roles, $projects,
    $notifs);


  my $msg = "User $name ($id) has been created.";
  $self->flash(msg => $msg);
  $self->redirect_to('/admin/users');
}

# Edit a user.
sub users_edit {
  my $self = shift;
  my $uid  = $self->param('uid');


  my $user = $self->app->al->users->get_user($uid);

  # Prepare data for template.
  $self->stash(
    user_id       => $user->{'id'},
    user_name     => $user->{'name'},
    user_email    => $user->{'email'},
    user_roles    => $user->{'roles'},
    user_projects => $user->{'projects'},
    user_notifs   => $user->{'notifs'},
  );

  $self->render(template => 'alambic/admin/users_set');
}

# Edit a user -- POST.
sub users_edit_post {
  my $self = shift;

  my $id     = $self->param('id');
  my $name   = $self->param('name');
  my $email  = $self->param('email');
  my $passwd = $self->param('passwd');

  my @roles;
  foreach my $role (@{$self->app->al->users->get_roles()}) {
    if ($self->param('roles_' . $role)) { push(@roles, $role) }
  }

  my $projects = $self->param('projects');
  my $notifs   = $self->param('notifs');

  my $project
    = $self->app->al->set_user($id, $name, $email, $passwd, \@roles, $projects,
    $notifs);


  my $msg = "User $name ($id) has been updated.";
  $self->flash(msg => $msg);
  $self->redirect_to('/admin/users');
}

# Delete a user from the database.
sub users_del {
  my $self = shift;

  my $uid = $self->param('uid');

  my $project = $self->app->al->del_user($uid);

  my $msg = "User $uid has been deleted.";
  $self->flash(msg => $msg);
  $self->redirect_to('/admin/users');
}


# Models import for Alambic admin.
sub models_import {
  my $self = shift;
  my $file = $self->param('file');
  my $type = $self->param('type') || "metrics";
  my $add  = $self->param('add') || 1;

  my $repofs = Alambic::Model::RepoFS->new();
  my $repodb = $self->app->al->get_repo_db();

  if ($type =~ m!^metrics$!) {
    my $metrics = decode_json($repofs->read_models('metrics', $file));

    foreach my $metric (@{$metrics->{'children'}}) {
      $repodb->set_metric(
        $metric->{'mnemo'}, $metric->{'name'},
        $metric->{'desc'},  $metric->{'scale'}
      );
    }
  }
  elsif ($type =~ m!^attributes$!) {
    my $attributes = decode_json($repofs->read_models('attributes', $file));

    foreach my $attribute (@{$attributes->{'children'}}) {
      $repodb->set_attribute($attribute->{'mnemo'}, $attribute->{'name'},
        $attribute->{'desc'});
    }
  }
  elsif ($type =~ m!^qm$!) {
    my $qm = decode_json($repofs->read_models('qm', $file));

    $repodb->set_qm("ALB_BASIC", "Alambic Quality Model", $qm->{'children'});

  }
  else {
    print "[ERROR] Something went wrong: bad type for model import.\n";
  }

  $self->app->al->get_models()->init_models(
    $repodb->get_metrics(),
    $repodb->get_attributes(),
    $repodb->get_qm(), $self->app->al->get_plugins()->get_conf_all()
  );

  my $msg = "File $file has been imported in the $type table.";
  $self->flash(msg => $msg);
  $self->redirect_to('/admin/models');
}

# Models display screen for Alambic admin.
# TODO
# sub models_init {
#   my $self = shift;

#   my $repodb = $self->app->al->get_repo_db();
#   $self->app->al->get_models()->init_models(
#     $repodb->get_metrics(),
#     $repodb->get_attributes(),
#     $repodb->get_qm(), $self->app->al->get_plugins()->get_conf_all()
#   );

#   my $msg = "Models have been re-read.";
#   $self->flash(msg => $msg);
#   $self->redirect_to('/admin/models');
# }


# Projects screen for Alambic admin.
sub projects {
  my $self = shift;

  $self->render(template => 'alambic/admin/projects');
}


# Display specific project screen for Alambic admin.
sub projects_show {
  my $self       = shift;
  my $project_id = $self->param('pid');

  # Get list of files in input and data directories.
  my @files_input  = <projects/${project_id}/input/*.*>;
  my @files_output = <projects/${project_id}/output/*.*>;
  my %files_time;

  # TODO get the list of runs for this project.
  my $repodb = $self->app->al->get_repo_db();
  my $runs   = $repodb->get_project_all_runs($project_id);

  # Retrieve last modification time on input files.
  foreach my $file (@files_input, @files_output) {
    $files_time{$file} = ctime(stat($file)->mtime);
  }

  # Prepare data for template.
  $self->stash(
    project_id   => $project_id,
    files_input  => \@files_input,
    files_output => \@files_output,
    files_time   => \%files_time,
    project_runs => $runs,
  );

  $self->render(template => 'alambic/admin/project');
}


# New project screen for Alambic admin.
sub projects_new {
  my $self = shift;

  $self->stash(project_id => '', project_name => '', project_active => '',);

  $self->render(template => 'alambic/admin/project_set');
}


# New project screen for Alambic admin - post processing.
sub projects_new_post {
  my $self = shift;

  my $project_id     = $self->param('id');
  my $project_name   = $self->param('name');
  my $project_active = $self->param('is_active');

  my $project = $self->app->al->create_project($project_id, $project_name, '',
    $project_active);

  my $msg = "Project '$project_name' ($project_id) has been created.";

  $self->flash(msg => $msg);
  $self->redirect_to('/admin/projects');
}


# New project from wizard screen for Alambic admin.
sub projects_wizards_new_init {
  my $self   = shift;
  my $wizard = $self->param('wiz');

  my $conf_wizard
    = $self->app->al->get_wizards()->get_wizard($wizard)->get_conf();

  $self->stash(wizard_id => $wizard, conf_wizard => $conf_wizard,);

  $self->render(template => 'alambic/admin/project_set_wizard');
}


# New project from wizard screen for Alambic admin.
sub projects_wizards_new_init_post {
  my $self   = shift;
  my $wizard = $self->param('wiz');

  my $project_id = $self->param('project_id');

  my %args;
  my $conf_wizard
    = $self->app->al->get_wizards()->get_wizard($wizard)->get_conf();
  foreach my $param (keys %{$conf_wizard->{'params'}}) {
    $args{$param} = $self->param($param);
  }

  my $project
    = $self->app->al->create_project_from_wizard($wizard, $project_id, \%args);

  my $msg = "Project [$project_id] has been created.";

  $self->flash(msg => $msg);
  $self->redirect_to("/admin/projects/$project_id");
}


# Run project screen for Alambic admin.
sub projects_run {
  my $self       = shift;
  my $project_id = $self->param('pid');

  my $user = $self->session('session_user');

  # Start minion job
  my $job = $self->minion->enqueue(
    run_project => [$project_id, $user] => {delay => 0});

  my $msg
    = "Project run for $project_id has been enqueued [<a href=\"/admin/jobs/$job\">$job</a>].";

  $self->flash(msg => $msg);
  $self->redirect_to('/admin/projects/' . $project_id);
}


# Run all projects at once
sub projects_runall {
  my $self = shift;

  my $user = $self->session('session_user');

  my $projects = $self->app->al->get_projects_list(1);

  # Start minion job
  for my $p (keys %$projects) {
    my $job
      = $self->minion->enqueue(run_project => [$p, $user] => {delay => 0});
  }

  my $msg
    = "Started runs for all [" . scalar(keys %$projects) . "] active projects.";

  $self->flash(msg => $msg);
  $self->redirect_to('/admin/jobs/');
}


# Purge all finished and failed jobs
sub jobs_purge {
  my $self = shift;

  my $user = $self->session('session_user');

  foreach my $job (@{$self->minion->backend->list_jobs()}) {

    # Remove minion job if state == failed or finished.
    if ($job->{'state'} =~ m!^failed$! or $job->{'state'} =~ m!^finished$!) {
      my $job = $self->minion->backend->remove_job($job->{'id'});
    }
  }

  my $msg = "Purged all finished and failed jobs in the queue.";

  $self->flash(msg => $msg);
  $self->redirect_to('/admin/jobs/');
}


# Delete a project for Alambic admin.
sub projects_del {
  my $self       = shift;
  my $project_id = $self->param('pid');

  $self->app->al->delete_project($project_id);
  my $msg = "Project $project_id has been deleted.";

  $self->flash(msg => $msg);
  $self->redirect_to('/admin/projects');
}


# Edit project screen for Alambic admin.
sub projects_edit {
  my $self       = shift;
  my $project_id = $self->param('pid');

  my $conf           = $self->app->al->get_project($project_id);
  my $project_name   = $conf->name();
  my $project_active = $conf->active();
  my $project_desc   = $conf->desc();

  $self->stash(
    id        => $project_id,
    name      => $project_name,
    desc      => $project_desc,
    is_active => $project_active,
  );

  # Render template
  $self->render(template => 'alambic/admin/project_set');
}


# Edit project screen for Alambic admin (POST).
sub projects_edit_post {
  my $self = shift;

  my $project_id     = $self->param('id');
  my $project_name   = $self->param('name');
  my $project_desc   = $self->param('desc');
  my $project_active = $self->param('is_active');

  my $project
    = $self->app->al->set_project($project_id, $project_name, $project_desc,
    $project_active);

  my $msg = "Project '$project_name' ($project_id) has been updated.";

  $self->flash(msg => $msg);
  $self->redirect_to('/admin/projects/' . $project_id);
}


# Add plugin to project screen for Alambic admin.
sub projects_add_plugin {
  my $self       = shift;
  my $project_id = $self->param('pid');
  my $plugin_id  = $self->param('plid');

  # Prepare data for template.
  my $conf = $self->app->al->get_plugins()->get_plugin($plugin_id)->get_conf();
  my $conf_project
    = $self->app->al->get_project($project_id)->get_plugins()->{$plugin_id};

  $self->stash(
    project      => $project_id,
    conf         => $conf,
    conf_project => $conf_project,
  );

  # Render template
  $self->render(template => 'alambic/admin/project_plugin_add');
}


# Add plugin to project screen for Alambic admin (POST).
sub projects_add_plugin_post {
  my $self       = shift;
  my $project_id = $self->param('pid');
  my $plugin_id  = $self->param('plid');

  my $conf = $self->app->al->get_plugins()->get_plugin($plugin_id)->get_conf();

  my %args;
  foreach my $param (keys %{$conf->{'params'}}) {
    $args{$param} = $self->param($param);
  }

  $self->app->al->add_project_plugin($project_id, $plugin_id, \%args);

  my $msg = "Plugin $plugin_id has been added to project $project_id.";

  $self->flash(msg => $msg);
  $self->redirect_to('/admin/projects/' . $project_id);
}


# Run specific plugin on a project.
sub projects_run_plugin {
  my $self       = shift;
  my $project_id = $self->param('pid');
  my $plugin_id  = $self->param('plid');

  my $job = $self->minion->enqueue(
    run_plugin => [$project_id, $plugin_id] => {delay => 0});

#    $self->app->al->get_project($project_id)->run_plugin($plugin_id);

  my $msg
    = "Plugin $plugin_id has been enqueued [<a href=\"/admin/jobs/$job\">$job</a>] on project $project_id.";

  $self->flash(msg => $msg);
  $self->redirect_to('/admin/projects/' . $project_id);
}


# Run pre plugins on a project.
sub projects_run_pre {
  my $self       = shift;
  my $project_id = $self->param('pid');

  my $job
    = $self->minion->enqueue(run_plugins => [$project_id] => {delay => 0});

  my $msg
    = "Project run Pre plugins on project $project_id has been enqueued [<a href=\"/admin/jobs/$job\">$job</a>].";

  $self->flash(msg => $msg);
  $self->redirect_to('/admin/projects/' . $project_id);
}


# Run quality model for a project.
sub projects_run_qm {
  my $self       = shift;
  my $project_id = $self->param('pid');

  my $job = $self->minion->enqueue(run_qm => [$project_id] => {delay => 0});

  my $msg
    = "Project run QM on project $project_id has been enqueued [<a href=\"/admin/jobs/$job\">$job</a>].";

  $self->flash(msg => $msg);
  $self->redirect_to('/admin/projects/' . $project_id);
}


# Run post plugins on a project
sub projects_run_posts {
  my $self       = shift;
  my $project_id = $self->param('pid');

  my $job = $self->minion->enqueue(run_posts => [$project_id] => {delay => 0});

  my $msg
    = "Project run post plugins on project $project_id has been enqueued [<a href=\"/admin/jobs/$job\">$job</a>].";

  $self->flash(msg => $msg);
  $self->redirect_to('/admin/projects/' . $project_id);
}


# Delete a plugin from a project.
sub projects_del_plugin {
  my $self       = shift;
  my $project_id = $self->param('pid');
  my $plugin_id  = $self->param('plid');

  $self->app->al->del_project_plugin($project_id, $plugin_id);

  my $msg = "Plugin $plugin_id has been removed from project $project_id.";

  $self->flash(msg => $msg);
  $self->redirect_to('/admin/projects/' . $project_id);
}

# Delete a file from the input data directory on the file system
sub del_input_file() {
  my $self = shift;

  my $project_id = $self->param('pid');
  my $file       = $self->param('file');

  my $ret = unlink('projects/' . $project_id . '/input/' . $file);
  my $msg;
  if ($ret == 1) {
    $msg = "Deleted input file [$file].";
  }
  else {
    $msg = "ERROR: could not delete input file.";
  }

  $self->flash(msg => $msg);
  $self->redirect_to('/admin/projects/' . $project_id);
}


# Delete a file from the output data directory on the file system
sub del_output_file() {
  my $self = shift;

  my $project_id = $self->param('pid');
  my $file       = $self->param('file');

  my $ret = unlink('projects/' . $project_id . '/output/' . $file);
  my $msg;
  if ($ret == 1) {
    $msg = "Deleted output file [$file].";
  }
  else {
    $msg = "ERROR: could not delete output file.";
  }

  $self->flash(msg => $msg);
  $self->redirect_to('/admin/projects/' . $project_id);
}


1;


=encoding utf8

=head1 NAME

B<Alambic::Controller::Admin> - Routing logic for Alambic administration UI.

=head1 SYNOPSIS

Routing logic for all administration actions in the Alambic web ui. This is automatically called by the Mojolicious framework.

=head1 METHODS

=head2 C<summary()> 

Main screen for Alambic admin.

=head2 C<edit()> 

Edit information about the instance.

=head2 C<edit_post()> 

Edit information about the instance -- post processing.

=head2 C<data_models()> 

JSON access for models data.

=head2 C<models()> 

Models display screen for Alambic admin.

=head2 C<users()> 

Display list of users for Alambic admin.

=head2 C<users_new()> 

Add a new user.

=head2 C<users_new_post()> 

Add a new user -- post processing.

=head2 C<users_edit()> 

Edit a user's parameters.

=head2 C<users_edit_post()> 

Edit a user's parameters -- post processing.

=head2 C<users_del()> 

Delete a user from the database.

=head2 C<models_import()> 

Models import for Alambic admin.

=head2 C<models_init()> 

Reread all models. Models display screen for Alambic admin.

=head2 C<projects()> 

Projects screen for Alambic admin.

=head2 C<projects_show()> 

Display specific project screen for Alambic admin.

=head2 C<projects_new()> 

New project screen for Alambic admin.

=head2 C<projects_new_post()> 

New project screen for Alambic admin - post processing.

=head2 C<projects_wizards_new_init()> 

New project from wizard screen for Alambic admin.

=head2 C<projects_wizards_new_init_post()> 

New project from wizard screen for Alambic admin -- post processing.

=head2 C<projects_run()> 

Run (enqueue) a specific project.

=head2 C<projects_runall()> 

Run (enqueue) all projects.

=head2 C<jobs_purge()> 

Purge all finished and failed jobs

=head2 C<projects_del()> 

Delete a project for Alambic admin.

=head2 C<projects_edit()> 

Edit project screen for Alambic admin.

=head2 C<projects_edit_post()> 

Edit project screen for Alambic admin -- post processing.

=head2 C<projects_add_plugin()> 

Add plugin to project screen for Alambic admin.

=head2 C<projects_add_plugin_post()> 

Add plugin to project screen for Alambic admin -- post processing.

=head2 C<projects_run_plugin()> 

Run specific plugin on a project.

=head2 C<projects_run_pre()> 

Run pre plugins on a project.

=head2 C<projects_run_qm()> 

Run quality model for a project.

=head2 C<projects_run_posts()> 

Run post plugins for a project.

=head2 C<projects_del_plugin()> 

Delete a plugin from a project.

=head2 C<del_input_file()> 

Delete a file from the input data directory on the file system.

=head2 C<del_output_file()> 

Delete a file from the output data directory on the file system.

=head1 SEE ALSO

L<Alambic>, L<http://alambic.io>, L<https://bitbucket.org/BorisBaldassari/alambic>, L<Mojolicious>.

=cut
