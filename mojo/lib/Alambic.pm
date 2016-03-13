package Alambic;

use Mojo::Base 'Mojolicious';

use Alambic::Model::Config;
use Alambic::Model::Models;
use Alambic::Model::Projects;
use Alambic::Model::Users;
use Alambic::Model::Repo;
use Alambic::Model::Plugins;

use Minion;

use Data::Dumper;

use File::ChangeNotify;


my $app;

# has projects => sub { 
#   state $projects = Alambic::Model::Projects->new($app);
# };

# has al_config => sub { 
#   state $config = Alambic::Model::Config->new($app);
# };


# This method will run once at server start
sub startup {
    $app = shift;

    $app->secrets(['Secrets of Alambic']);

    $app->log->level('debug');

    # Use Config plugin for basic configuration
    my $config = $app->plugin('Config');

    my $conf_mail = {
	from     => 'alambic@eclipse.castalia.camp',
	encoding => 'base64',
	type     => 'text/html',
	how      => 'sendmail',
	howargs  => [ '/usr/sbin/sendmail -t' ],
    };
    
    $app->plugin( 'mail' => $conf_mail );
    
    # Use application logger
    $app->app->log->info('Alambic application started.');

    # Helpers definition
    $app->plugin('Alambic::Model::Helpers');

    my $watcher_data = File::ChangeNotify->instantiate_watcher
        ( directories => [ $config->{'dir_data'} ],
          filter      => qr/\.json$/,
        );

    my $watcher_conf = File::ChangeNotify->instantiate_watcher
        ( directories => [ $config->{'dir_conf'} ],
          filter      => qr/\.json$/,
        );

    # Repo holds information about the git repository used for this instance.
    $app->helper( repo => sub { state $repo = Alambic::Model::Repo->new($app) } );
    # Initialise repository object.
    $app->repo->read_status();

    # Load plugins for data plugins.
    $app->helper( al_plugins => sub { state $plugins = Alambic::Model::Plugins->new($app) } );
    # Initialise the plugins (read files).
    $app->al_plugins->read_all_files();

    # Users holds information about the users and authentication mecanism.
    $app->helper( users => sub { state $users = Alambic::Model::Users->new($app) } );
    # Initialise the mode (read files).
    $app->users->read_all_files();

    # Models holds information about the model: attributes, metrics, model hierarchy, etc.
    $app->helper( models => sub { state $models = Alambic::Model::Models->new($app) } );
    # Initialise the models (read files).
    $app->models->read_all_files();

    # project holds information about the projects.
    $app->helper( projects => sub { 
      state $project = Alambic::Model::Projects->new($app);
      if ( my @events = $watcher_data->new_events() ) { 
        $app->app->log->info( 'Change detected in data files.' );
        foreach my $event (@events) { $app->app->log->info( "   Event " . $event->type . " [" . $event->path . "]" ); }
        $project->read_all_files(); 
      }
      return $project;
		} );

    # al_config holds information about this Alambic instance.
    $app->helper( al_config=> sub { 
      state $config = Alambic::Model::Config->new($app);
      if ( my @events = $watcher_conf->new_events() ) { 
        $app->app->log->info( 'Change detected in config files.' );
        foreach my $event (@events) { $app->app->log->info( "   Event " . $event->type . " [" . $event->path . "]" ); }
        $config->read_files(); 
        # Also update users in case of an update of the users conf file.
        $app->users->read_all_files();
      }
      return $config;
    } );

    # Used to get project name from id
    $app->helper( 
        get_project_name_by_id => sub { 
            my $app = shift;
            my $id = shift || 0;
            return $app->projects->get_project_name_by_id($id);
        });
    
    # Set the default layout for pages.
    if ( defined( $app->al_config->get_layout() ) ) {
        $app->app->log->info('Using layout ' . $app->al_config->get_layout() . ' from configuration file.');
        $app->defaults(layout => $app->al_config->get_layout());
    } else {
        $app->defaults(layout => 'default');
    }

    # MINION management

    # Use Minion for job queuing.
    $app->plugin( Minion => {Pg => $app->al_config->get_pg('conf_pg')} );

    # Set parameters.
    # Automatically remove jobs from queue after one day. 86400 is one day.
    $app->minion->remove_after(86400);

    # Add task to retrieve ds data
    $app->minion->add_task( retrieve_data_ds => sub {
        my ($job, $ds, $project_id) = @_;
        my $log_ref = $app->al_plugins->get_plugin($ds)->retrieve_data($project_id);
        my @log = @{$log_ref};
        $job->finish(\@log);
    } );

    # Add task to compute ds data
    $app->minion->add_task( compute_data_ds => sub {
        my ($job, $ds, $project_id) = @_;
        my $log_ref = $app->al_plugins->get_plugin($ds)->compute_data($project_id);
        my @log = @{$log_ref};
        $job->finish(\@log);
    } );
    
    # Add task to retrieve all data for a project
    $app->minion->add_task( retrieve_project => sub {
        my ($job, $project_id) = @_;
        my $log_ref = $app->projects->retrieve_project_data($project_id);
        my @log = @{$log_ref};
        $job->finish(\@log);
    } );
    
    # Add task to compute all data for a project
    $app->minion->add_task( analyse_project => sub {
        my ($job, $project_id) = @_;
        my $log_ref = $app->projects->analyse_project($project_id);
        my @log = @{$log_ref};
        $job->finish(\@log);
    } );
    
    # Add task to run both retrieval and analysis for a project
    $app->minion->add_task( run_project => sub {
        my ($job, $project_id) = @_;
        my $log_ref_retrieve = $app->projects->retrieve_project_data($project_id);
        my $log_ref_analyse = $app->projects->analyse_project($project_id);
        my @log = ( @{$log_ref_retrieve}, @{$log_ref_analyse} );
        $job->finish(\@log);
    } );
    

    # Router
    my $r = $app->routes;
    
    # Normal route to controller
    $r->get('/')->to('alambic#welcome');
    
    # Simple pages
    $r->get('/about.html')->to( template => 'alambic/about');
    $r->get('/contact.html')->to( template => 'alambic/contact');
    $r->post('/contact')->to( 'alambic#contact_post' );

    # Data (quality_model.json, etc.).
    $r->get('/data/#id')->to('data#download');
    
    # Documentation
    $r->get('/documentation/#id')->to('documentation#welcome');
    $r->get('/documentation')->to('documentation#welcome');
    
    # Comments
    $r->get('/comments/')->to('comments#welcome');
    
    # Dashboards
    $r->get('/projects/#id')->to('dashboard#display');
    # Figures
    $r->get('/projects/figures/#plugin/#project/#fig')->to('figures#plugins');
    
    # Login form
    $r->get('/login')->to('alambic#login');
    $r->post('/login')->to('alambic#login_post');
    $r->get('/logout')->to('alambic#logout');

    # Admin
    $r->get('/admin/summary')->to( 'admin#welcome' );

    # Install route (SCM)
    $r->get('/admin/install')->to('alambic#install');
    $r->post('/admin/install')->to('alambic#install_post');
    
    # Job management
    $r->get('/admin/jobs')->to( 'jobs#summary' );
    $r->get('/admin/jobs/#id')->to( 'jobs#display' );
    $r->get('/admin/jobs/#id/del')->to( 'jobs#delete' );
    $r->get('/admin/jobs/#id/rec')->to( 'jobs#redo' );

    # Admin - Repository
    $r->get('/admin/repo')->to( 'admin#repo' );
    $r->get('/admin/repo/init')->to( 'repo#init' );
    $r->post('/admin/repo/init')->to( 'repo#init_post' );
    $r->get('/admin/repo/manage')->to('repo#manage');
    $r->get('/admin/repo/push')->to('repo#push');

    # Admin - Data sources
    $r->get('/admin/plugins')->to( 'admin#plugins' );

    # Admin -- manage projects
    $r->get('/admin/projects')->to( 'admin#projects_main' );
    $r->get('/admin/projects/new')->to( 'admin#project_add' );
    $r->post('/admin/projects/new')->to( 'admin#project_add_post' );
    $r->get('/admin/project/#id/retrieve')->to( 'admin#project_retrieve_data' );
    $r->get('/admin/project/#id/analyse')->to( 'admin#project_analyse' );
    $r->get('/admin/project/#id/run')->to( 'admin#project_run' );
    $r->get('/admin/project/#id/del')->to( 'admin#project_del' );
    $r->get('/admin/project/#id')->to( 'admin#projects_id' );

    # Admin - manage data source plugins
    $r->get('/admin/project/#id/ds/#ds/new')->to( 'plugins#add_project' );
    $r->post('/admin/project/#id/ds/#ds/new')->to( 'plugins#add_project_post' );
    $r->get('/admin/project/#id/ds/#ds/check')->to( 'plugins#check_project' );
    $r->get('/admin/project/#id/ds/#ds/retrieve')->to( 'plugins#project_retrieve_data' );
    $r->get('/admin/project/#id/ds/#ds/compute')->to( 'plugins#project_compute_data' );
#    $r->get('/admin/project/#id/ds/#ds/edit')->to( 'plugins#add_project' );
    $r->get('/admin/project/#id/ds/#ds/del')->to( 'plugins#del_project' );

    # Admin - manage custom data plugins.
    # $id is the project
    # $cd is the custom data plugin
    $r->get('/admin/cdata')->to( 'custom_data#display' );
    $r->get('/admin/cdata/#proj')->to( 'custom_data#display' );
    $r->get('/admin/cdata/#proj/#cd/new')->to( 'custom_data#add_to_project' );
    $r->get('/admin/cdata/#proj/#cd/show')->to( 'custom_data#show' );
    $r->get('/admin/cdata/#proj/#cd/add')->to( 'custom_data#add' );
    $r->post('/admin/cdata/#proj/#cd/add')->to( 'custom_data#add_post' );
#    $r->get('/admin/cdata/#proj/#cd/compute')->to( 'custom_data#compute_data' );
    $r->get('/admin/cdata/#proj/#cd/edit/:id')->to( 'custom_data#edit' );
    $r->get('/admin/cdata/#proj/#cd/del/:id')->to( 'custom_data#del' );

    # Admin - Users management
    $r->get('/admin/users')->to( 'admin#users_main' );

    # Admin - Utilities
    $r->get('/admin/read_files/:files')->to( 'admin#read_files' );
    $r->get('/admin/del_input_file/#project/#file')->to( 'admin#del_input_file' );
    $r->get('/admin/del_data_file/#project/#file')->to( 'admin#del_data_file' );

    # Admin - Comments
    $r->get('/admin/comments')->to( 'comments#welcome' );
    $r->get('/admin/comments/#project')->to( 'comments#welcome' );
    $r->get('/admin/comments/#project/a')->to( 'comments#welcome', act => 'a' );
    $r->get('/admin/comments/#project/:act/:com')->to( 'comments#welcome' );
    $r->post('/admin/comments/#project/a')->to( 'comments#add_post' );
    $r->post('/admin/comments/#project/e/:com')->to( 'comments#edit_post' );
    $r->post('/admin/comments/#project/d/:com')->to( 'comments#delete_post' );

}

1;
