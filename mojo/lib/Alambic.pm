package Alambic;
use Mojo::Base 'Mojolicious';

use Alambic::Model::Alambic;

use Minion;
use Data::Dumper;


has al => sub {
  my $self = shift;

  # Get config from alambic.conf
  my $config = $self->plugin('Config');
  state $al = Alambic::Model::Alambic->new($config);
};


# This method will run once at server start
sub startup {
  my $self = shift;

  # Get config from alambic.conf
  my $config = $self->plugin('Config');

  # Add another namespace to load commands from
  push @{$self->commands->namespaces}, 'Alambic::Commands';

  $self->secrets(['Secrets of Alambic']);

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

  # Use POD renderer
  #$self->plugin('PODRenderer');
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

  # # Catch all routes only if the instance is not initialised.
  # # Now is initialised by command.
  # if ( $self->app->al->instance_name() eq 'MyDBNameInit' ) {
  # 	print "### Executing Install procedure.\n";
  # 	$r->post('/install')->to( 'alambic#install_post' );
  # 	$r->any('/')->to( 'alambic#install' );
  # 	$r->any('*')->to( 'alambic#install' );
  # 	return;
  # }

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
  $r_projects->get('/#id/history/#build/#page')
    ->to(action => 'display_history');
  $r_projects->get('/#id/#plugin/#page')->to(action => 'display_plugins');
  $r_projects->post('/#id/#plugin/#page')->to(action => 'display_plugins_post');
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
  $r_admin->get('/users')->to(action => 'users');
  $r_admin->get('/users/new')->to(action => 'users_new');
  $r_admin->post('/users/new')->to(action => 'users_new_post');
  $r_admin->get('/users/#uid')->to(action => 'users_edit');
  $r_admin->post('/users/#uid')->to(action => 'users_edit_post');
  $r_admin->get('/users/#uid/del')->to(action => 'users_del');

  $r_admin->get('/models')->to(action => 'models');
  $r_admin->get('/models/import')->to(action => 'models_import');
  $r_admin->get('/models/init')->to(action => 'models_init');

  my $r_admin_projects = $r_admin->any('/projects')->to(controller => 'admin');
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

Alambic - Main class for Alambic

=head1 SYNOPSIS

  # Lowercase command name
  package Mojolicious::Command::mycommand;
  use Mojo::Base 'Mojolicious::Command';

  # Short description
  has description => 'My first Mojo command';

  # Usage message from SYNOPSIS
  has usage => sub { shift->extract_usage };

  sub run {
    my ($self, @args) = @_;

    # Magic here! :)
  }

  1;

  =head1 SYNOPSIS

    Usage: APPLICATION mycommand [OPTIONS]

    Options:
      -s, --something   Does something

  =cut

=head1 DESCRIPTION

L<Alambic> is a framework and a service for software development data management.

See L<Mojolicious::Commands/"COMMANDS"> for a list of commands that are
available by default.

=head1 ATTRIBUTES

L<Mojolicious::Command> implements the following attributes.

=head2 app

  my $app  = $command->app;
  $command = $command->app(Mojolicious->new);

Application for command, defaults to a L<Mojo::HelloWorld> object.

  # Introspect
  say "Template path: $_" for @{$command->app->renderer->paths};

=head2 description

  my $description = $command->description;
  $command        = $command->description('Foo');

Short description of command, used for the command list.

=head2 quiet

  my $bool = $command->quiet;
  $command = $command->quiet($bool);

Limited command output.

=head2 usage

  my $usage = $command->usage;
  $command  = $command->usage('Foo');

Usage information for command, used for the help screen.

=head1 METHODS

L<Mojolicious::Command> inherits all methods from L<Mojo::Base> and implements
the following new ones.

=head2 chmod_file

  $command = $command->chmod_file('/home/sri/foo.txt', 0644);

Change mode of a file.

=head2 chmod_rel_file

  $command = $command->chmod_rel_file('foo/foo.txt', 0644);

Portably change mode of a file relative to the current working directory.

=head2 create_dir

  $command = $command->create_dir('/home/sri/foo/bar');

Create a directory.

=head2 create_rel_dir

  $command = $command->create_rel_dir('foo/bar/baz');

Portably create a directory relative to the current working directory.

=head2 extract_usage

  my $usage = $command->extract_usage;

Extract usage message from the SYNOPSIS section of the file this method was
called from with L<Mojo::Util/"extract_usage">.

=head2 help

  $command->help;

Print usage information for command.

=head2 rel_file

  my $path = $command->rel_file('foo/bar.txt');

Return a L<Mojo::File> object relative to the current working directory.

=head2 render_data

  my $data = $command->render_data('foo_bar');
  my $data = $command->render_data('foo_bar', @args);

Render a template from the C<DATA> section of the command class with
L<Mojo::Loader> and L<Mojo::Template>.

=head2 render_to_file

  $command = $command->render_to_file('foo_bar', '/home/sri/foo.txt');
  $command = $command->render_to_file('foo_bar', '/home/sri/foo.txt', @args);

Render a template from the C<DATA> section of the command class with
L<Mojo::Template> to a file and create directory if necessary.

=head2 render_to_rel_file

  $command = $command->render_to_rel_file('foo_bar', 'foo/bar.txt');
  $command = $command->render_to_rel_file('foo_bar', 'foo/bar.txt', @args);

Portably render a template from the C<DATA> section of the command class with
L<Mojo::Template> to a file relative to the current working directory and
create directory if necessary.

=head2 run

  $command->run;
  $command->run(@ARGV);

Run command. Meant to be overloaded in a subclass.

=head2 write_file

  $command = $command->write_file('/home/sri/foo.txt', 'Hello World!');

Write text to a file and create directory if necessary.

=head2 write_rel_file

  $command = $command->write_rel_file('foo/bar.txt', 'Hello World!');

Portably write text to a file relative to the current working directory and
create directory if necessary.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicious.org>.

=cut
