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

package Alambic;
use Mojo::Base 'Mojolicious';

use Alambic::Model::Alambic;

use Minion;
use Data::Dumper;
use Cwd;
use Digest::MD5 qw(md5_hex);


has al => sub {
  my $self = shift;

  # Get config from alambic.conf
  my $config = $self->plugin('Config');
  state $al = Alambic::Model::Alambic->new($config);
};


# This method will run once at server start
sub startup {
  my $self = shift;

  # Set the secret passphrase (notably used in cookies)
  my $hostname = `hostname`;
  chomp $hostname;
  my $secrets1 = md5_hex("Alambic Powah " . getcwd() . " " . $hostname);
  my $secrets2 = md5_hex("Data Metrics " . getcwd() . " " . $hostname);
  my $secrets3 = md5_hex("Mojolicious " . getcwd() . " " . $hostname);
  $self->secrets([$secrets1, $secrets2, $secrets3]);

  # Get config from alambic.conf
  my $config = $self->plugin('Config');

  # Add another namespace to load commands from
  push @{$self->commands->namespaces}, 'Alambic::Commands';

  # Use application logger
  $self->log->info(
    'Alambic ' . $config->{'alambic_version'} . ' application started.');

  my $conf_mail = {
    from     => 'alambic@castalia.solutions',
    encoding => 'base64',
    type     => 'text/html',
    how      => 'sendmail',
    howargs  => ['/usr/sbin/sendmail -t'],
  };
  $self->plugin('mail' => $conf_mail);

  # Set layout for pages.
  $self->defaults(layout => 'default');


  # Used to make alambic installable and Build::Module compatible
  $self->plugin('InstallablePaths');

  # Use Minion for job queuing.
  $self->plugin(Minion => {Pg => $config->{'conf_pg_minion'}});


  # MINION management

  # Set parameters.
  # Automatically remove jobs from queue after one day. 86400 is one day.
  $self->minion->remove_after(86400);

  # Add task to create a project with a wizard
  $self->minion->add_task(
    add_project_wizard => sub {
      my ($job, $wizard, $project_id) = @_;
      my $ret = $self->al->create_project_from_wizard($wizard, $project_id);
      $job->finish($ret);
    }
  );

  # Add task to compute all data for a project
  $self->minion->add_task(
    run_project => sub {
      my ($job, $project_id, $user) = @_;

      # Check that the project is not currently run
      my $jobs = $self->minion->backend->list_jobs;
      foreach my $j (@$jobs) {
        if ( $j->{'args'}[0] =~ m!^${project_id}$!
          && $j->{'state'} =~ 'active'
          && $j->{'id'} != $job->{'id'})
        {
          $job->fail("It is not a good idea to run twice the"
              . " same project concurrently. Aborting the job.");
          return;
        }
      }

      my $ret = $self->al->run_project($project_id, $user);
      $job->finish($ret);
    }
  );

# Add task to run a single plugin
# Partial runs are not recorded in the db and can only be viewed in the job log.
  $self->minion->add_task(
    run_plugin => sub {
      my ($job, $project_id, $plugin_id) = @_;
      my $ret;

      my $plugin_conf
        = $self->app->al->get_plugins()->get_plugin($plugin_id)->get_conf();
      my $models = $self->app->al->get_models();

      if ($plugin_conf->{'type'} =~ /^pre$/) {
        $ret = $self->al->get_project($project_id)->run_plugin($plugin_id);
      }
      elsif ($plugin_conf->{'type'} =~ /^post$/) {
        $ret
          = $self->al->get_project($project_id)->run_post($plugin_id, $models);
      }
      else { $ret->{'log'} = ["Plugin ID [$plugin_id] is not recognised."] }
      $job->finish($ret);
    }
  );

# Add task to run all plugins
# Partial runs are not recorded in the db and can only be viewed in the job log.
  $self->minion->add_task(
    run_plugins => sub {
      my ($job, $project_id) = @_;
      my $ret = $self->al->run_plugins($project_id);
      $job->finish($ret);
    }
  );

# Add task to run qm analysis
# Partial runs are not recorded in the db and can only be viewed in the job log.
  $self->minion->add_task(
    run_qm => sub {
      my ($job, $project_id) = @_;
      my $ret = $self->al->run_qm($project_id);
      $job->finish($ret);
    }
  );

# Add task to run post plugins
# Partial runs are not recorded in the db and can only be viewed in the job log.
  $self->minion->add_task(
    run_posts => sub {
      my ($job, $project_id) = @_;
      my $ret = $self->al->run_posts($project_id);
      $job->finish($ret);
    }
  );


  # Router
  my $r = $self->routes;

  # Normal route to controller
  $r->get('/')->to('alambic#welcome');

  # Simple pages
  $r->get('/about')->to(template => 'alambic/about');
  $r->post('/contact')->to('alambic#contact_post');
  $r->get('/login')->to('alambic#login');
  $r->post('/login')->to('alambic#login_post');
  $r->get('/logout')->to('alambic#logout');

  # Documentation
  $r->get('/documentation/#id')->to('documentation#welcome');

  # Dashboards
  my $r_projects = $r->get('/projects')->to(controller => 'dashboard');
  $r_projects->get('/#id')->to(action => 'display_summary');
  $r_projects->get('/#id/#page')->to(action => 'display_project');
  $r_projects->get('/#id/history/#page')->to(action => 'display_history_all');
  $r_projects->get('/#id/history/#build/#page')
    ->to(action => 'display_history');
  $r_projects->get('/#id/#plugin/#page')->to(action => 'display_plugins');

 # TODO Remove me, or use me to setup the post plugins.
 #$r_projects->post('/#id/#plugin/#page')->to(action => 'display_plugins_post');
  $r_projects->get('/#id/#plugin/figures/#page')
    ->to(action => 'display_figures');

  # JSON data for models
  $r->get('/models/#page')->to('admin#data_models');

  ### Protected routes
  $self->routes->add_condition(
    roles => sub {
      my ($r, $c, $captures, $roles) = @_;
      my @roles = @$roles;

      # 1. User is connected?
      if (exists($c->session->{'session_user'})) {
        my $user
          = $self->al->users->get_user($c->session->{'session_user'}) || {};
        while (my $role = shift @roles) {
          if (grep { $_ eq ${role} } @{$user->{'roles'}}) {

            # It's ok, we know him
            return 1;
          }
        }
      }

      # Keep the weirdos out!
      return undef;
    }
  );

  # User pages
  my $r_user = $r->any('/user')->over(roles => ['Project', 'Admin'])
    ->to(controller => 'users');
  $r_user->get('/#id/profile')->to(action => 'profile');
  $r_user->get('/#id/project/#project')->to(action => 'projects');

  # Admin
  my $r_admin
    = $r->any('/admin')->over(roles => ['Admin'])->to(controller => 'admin');

  $r_admin->get('/edit')->to(action => 'edit');
  $r_admin->post('/edit')->to(action => 'edit_post');
  $r_admin->get('/summary')->to(action => 'summary');
  $r_admin->get('/projects')->to(action => 'projects');

  $r_admin->get('/purgejobs')->to(action => 'jobs_purge');

  $r_admin->get('/users')->to(action => 'users');
  $r_admin->get('/users/new')->to(action => 'users_new');
  $r_admin->post('/users/new')->to(action => 'users_new_post');
  $r_admin->get('/users/#uid')->to(action => 'users_edit');
  $r_admin->post('/users/#uid')->to(action => 'users_edit_post');
  $r_admin->get('/users/#uid/del')->to(action => 'users_del');

  $r_admin->get('/models')->to(action => 'models');
  $r_admin->get('/models/import')->to(action => 'models_import');

  # TODO remove init? still useful?
  $r_admin->get('/models/init')->to(action => 'models_init');

  my $r_admin_projects = $r_admin->any('/projects')->to(controller => 'admin');
  $r_admin_projects->get('/runall')->to(action => 'projects_runall');
  $r_admin_projects->get('/new')->to(action => 'projects_new');
  $r_admin_projects->post('/new')->to(action => 'projects_new_post');

  # Wizards
  $r_admin_projects->get('/new/#wiz')
    ->to(action => 'projects_wizards_new_init');
  $r_admin_projects->post('/new/#wiz')
    ->to(action => 'projects_wizards_new_init_post');
  $r_admin_projects->get('/new/#wiz/#pid')
    ->to(action => 'projects_wizards_new');
  $r_admin_projects->post('/new/#wiz/#pid')
    ->to(action => 'projects_wizards_new_post');

  # Projects
  $r_admin_projects->get('/#pid')->to(action => 'projects_show');
  $r_admin_projects->get('/#pid/run')->to(action => 'projects_run');
  $r_admin_projects->get('/#pid/run/pre')->to(action => 'projects_run_pre');
  $r_admin_projects->get('/#pid/run/qm')->to(action => 'projects_run_qm');
  $r_admin_projects->get('/#pid/run/post')->to(action => 'projects_run_posts');
  $r_admin_projects->get('/#pid/del')->to(action => 'projects_del');
  $r_admin_projects->get('/#pid/edit')->to(action => 'projects_edit');
  $r_admin_projects->post('/#pid/edit')->to(action => 'projects_edit_post');
  $r_admin_projects->get('/#pid/setp/#plid')
    ->to(action => 'projects_add_plugin');
  $r_admin_projects->post('/#pid/setp/#plid')
    ->to(action => 'projects_add_plugin_post');
  $r_admin_projects->get('/#pid/runp/#plid')
    ->to(action => 'projects_run_plugin');
  $r_admin_projects->get('/#pid/delp/#plid')
    ->to(action => 'projects_del_plugin');
  $r_admin_projects->get('/#pid/del_input_file/#file')
    ->to('admin#del_input_file');
  $r_admin_projects->get('/#pid/del_output_file/#file')
    ->to('admin#del_output_file');

  # my $r_admin_models = $r->get('/admin/models/')->to( controller => 'admin' );

  # Job management
  $r_admin->get('/jobs')->to('jobs#summary');
  $r_admin->get('/jobs/#id')->to('jobs#display');
  $r_admin->get('/jobs/#id/del')->to('jobs#delete');
  $r_admin->get('/jobs/#id/run')->to('jobs#redo');

  # Tools management
  $r_admin->get('/tools')->to('tools#summary');
  $r_admin->get('/tools/#id')->to('tools#display');

  # Database manipulations.
  $r_admin->get('/repo')->to('repo#summary');
  $r_admin->get('/repo/init')->to('repo#init');
  $r_admin->get('/repo/backup')->to('repo#backup');
  $r_admin->get('/repo/restore/#file')->to('repo#restore');
  $r_admin->get('/repo/dl/#file')->to('repo#dl');
  $r_admin->get('/repo/del_backup/#file')->to('repo#delete');

  # Admin fallback when no auth
  $r->any('/admin/*')->to('alambic#failed');

}

1;


=encoding utf8

=head1 NAME

B<Alambic> - An open-source platform and service for the management and 
visualisation of software engineering data.

=head1 SYNOPSIS

Start the application in prefork mode (production mode, multi-threaded):

  $ hypnotoad bin/alambic
  Server available at http://127.0.0.1:3010
  $ 

Start the application in daemon mode (development mode, automatic reload of files):

  $ morbo bin/alambic
  Server available at http://127.0.0.1:3000

Start a worker thread (used for long-running tasks, e.g. project analysis):

  $ bin/alambic minion worker


=head1 DESCRIPTION

B<Alambic> is an open-source framework and service for the management and 
visualisation of software engineering data. 

The official web site with complete documentation is L<http://alambic.io>. 

Project is developed on BitBucket at L<https://bitbucket.org/BorisBaldassari/alambic>.

See L<Alambic::Commands/"COMMANDS"> for a list of commands that are available.

=head1 ATTRIBUTES

L<Alambic> implements the following attributes.

=head2 C<al>

  my $app  = $self->al;

=head1 METHODS

L<Alambic> implements the following methods.

=head2 C<startup()>

The default method to start the application.

=head1 SEE ALSO

L<Mojolicious>, L<http://alambic.io>, L<https://bitbucket.org/BorisBaldassari/alambic>

=cut
