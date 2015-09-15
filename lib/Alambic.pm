package Alambic;

use Mojo::Base 'Mojolicious';

use Alambic::Model::Models;
use Alambic::Model::Projects;

use Data::Dumper;

# This method will run once at server start
sub startup {
    my $app = shift;

    $app->secrets(['Secrets of Alambic']);

    $app->log->level('debug');

    # Documentation browser under "/perldoc"
    $app->plugin('PODRenderer');
    
    # Use Config plugin for basic configuration
    my $config = $app->plugin('Config');

    # And make it available as a helper.
#    $app->helper( config => sub { $config } );
    
    # Use application logger
    $app->app->log->info('Comments application started.');
        
    # Helpers definition
    $app->helper( 
        comp_c => sub { 
            my $app = shift;
            my $value = shift || 0;
            return $config->{"colours"}->[int($value)];
        });

    # Models holds information about the model: attributes, metrics, model hierarchy, etc.
    $app->helper( models => sub { state $models = Alambic::Model::Models->new($app) } );
    # Initialise the models (read files).
    $app->models->read_all_files();

    # Projects holds information about the analysed projects: values, pmi, comments, etc.
    $app->helper( projects => sub { state $projects = Alambic::Model::Projects->new($app) } );
    # Initialise the mode (read files).
    $app->projects->read_all_files();

    $app->helper( 
        get_project_name_by_id => sub { 
            my $app = shift;
            my $id = shift || 0;
            return $app->projects->get_project_name_by_id($id);
        });

    $app->helper( conf_dir_conf => sub { $config->{dir_conf} } );
    $app->helper( conf_dir_data => sub { $config->{dir_data} } );
    $app->helper( conf_dir_projects => sub { $config->{dir_projects} } );
    $app->helper( conf_dir_rules => sub { $config->{dir_rules} } );
    $app->helper( conf_title => sub { $config->{instance_title} } );
    $app->helper( conf_desc => sub { $config->{instance_desc} } );
    
    # Router
    my $r = $app->routes;
    
    # Normal route to controller
    $r->get('/')->to('alambic#welcome');
    
    # Simple pages
    $r->get('/about.html')->to( template => 'alambic/about');
    $r->get('/contact.html')->to( template => 'alambic/contact');
    
    # Admin
    $r->get('/admin/summary')->to( 'admin#welcome' );
    $r->get('/admin/projects')->to( 'admin#projects_main' );
#    $r->get('/admin/project/#id')->to( 'admin#projects_id' );

    # Admin - Utilities
    $r->get('/admin/read_files/:files')->to( 'admin#read_files' );

    # Admin - Comments
    $r->get('/admin/comments')->to( 'comments#welcome' );
    $r->get('/admin/comments/#project')->to( 'comments#welcome' );
    $r->get('/admin/comments/#project/a')->to( 'comments#welcome', act => 'a' );
    $r->get('/admin/comments/#project/:act/:com')->to( 'comments#welcome' );
    $r->post('/admin/comments/#project/a')->to( 'comments#add_post' );
    $r->post('/admin/comments/#project/e/:com')->to( 'comments#edit_post' );
    $r->post('/admin/comments/#project/d/:com')->to( 'comments#delete_post' );
    
    # Data (quality_model.json, etc.).
    $r->get('/data/#id')->to('data#download');
    
    # Documentation
    $r->get('/documentation/#id')->to('documentation#welcome');
    
    # Comments
    $r->get('/comments/')->to('alambic#welcome');
    
    # Dashboards
    $r->get('/projects/#id')->to('projects#display');
    
}

1;
