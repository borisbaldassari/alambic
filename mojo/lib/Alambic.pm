package Alambic;

use Mojo::Base 'Mojolicious';

use Alambic::Model::Config;
use Alambic::Model::Models;
use Alambic::Model::Projects;
use Alambic::Model::Users;
use Alambic::Model::Repo;
use Alambic::Model::Plugins;

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

    # Set the default layout for pages.
    $app->defaults(layout => 'polarsys');

    $app->log->level('debug');

    # Use Config plugin for basic configuration
    my $config = $app->plugin('Config');
    
    # Use application logger
    $app->app->log->info('Comments application started.');

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
        $config->read_all_files(); 
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
    
    # Router
    my $r = $app->routes;
    
    # Normal route to controller
    $r->get('/')->to('alambic#welcome');
    
    # Simple pages
    $r->get('/about.html')->to( template => 'alambic/about');
    $r->get('/contact.html')->to( template => 'alambic/contact');

    # Data (quality_model.json, etc.).
    $r->get('/data/#id')->to('data#download');
    
    # Documentation
    $r->get('/documentation/#id')->to('documentation#welcome');
    
    # Comments
    $r->get('/comments/')->to('comments#welcome');
    
    # Dashboards
    $r->get('/projects/#id')->to('dashboard#display');
    
    # Login form
    $r->get('/login')->to('alambic#login');
    $r->post('/login')->to('alambic#login_post');
    $r->get('/logout')->to('alambic#logout');

    # Admin
    $r->get('/admin/summary')->to( 'admin#welcome' );

    # Install route (SCM)
    $r->get('/admin/install')->to('alambic#install');
    $r->post('/admin/install')->to('alambic#install_post');
    
    # Admin - Repository
    $r->get('/admin/repo')->to( 'admin#repo' );
    $r->get('/admin/repo/init')->to( 'repo#init' );
    $r->post('/admin/repo/init')->to( 'repo#init_post' );
    $r->get('/admin/repo/manage')->to('repo#manage');
    $r->get('/admin/repo/push')->to('repo#push');

    # Admin - Data sources
    $r->get('/admin/plugins')->to( 'admin#plugins' );

    $r->get('/admin/projects')->to( 'admin#projects_main' );
    $r->get('/admin/projects/new')->to( 'admin#project_add' );
    $r->post('/admin/projects/new')->to( 'admin#project_add_post' );
    $r->get('/admin/project/#id/retrieve')->to( 'admin#project_retrieve_data' );
    $r->get('/admin/project/#id/analyse')->to( 'admin#project_analyse' );
    $r->get('/admin/project/#id/del')->to( 'admin#project_del' );
    $r->get('/admin/project/#id')->to( 'admin#projects_id' );

    $r->get('/admin/project/#id/ds/#ds/new')->to( 'plugins#add_project' );
    $r->post('/admin/project/#id/ds/#ds/new')->to( 'plugins#add_project_post' );
    $r->get('/admin/project/#id/ds/#ds/check')->to( 'plugins#check_project' );
    $r->get('/admin/project/#id/ds/#ds/retrieve')->to( 'plugins#project_retrieve_data' );
    $r->get('/admin/project/#id/ds/#ds/compute')->to( 'plugins#project_compute_data' );
#    $r->get('/admin/project/#id/ds/#ds/edit')->to( 'plugins#add_project' );
    $r->get('/admin/project/#id/ds/#ds/del')->to( 'plugins#del_project' );

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
