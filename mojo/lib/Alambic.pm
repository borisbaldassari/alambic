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
    
    $self->secrets(['Secrets of Alambic']);
    
    # Use application logger
    $self->log->info('Alambic v3.0 application started.');
    
    # Alambic::Alambic.pm is the main entry point for all actions;
    #$self->helper( alambic => sub { state $repo = Alambic::Model::Alambic->new() } );
    
    # Set layout for pages.
    $self->defaults(layout => 'default');
    

    # MINION management
    # Use Minion for job queuing.
    
    # Get config from alambic.conf
    my $config = $self->plugin('Config');
    $self->plugin( Minion => {Pg => $config->{'conf_pg_minion'}} );

    # Set parameters.
    # Automatically remove jobs from queue after one day. 86400 is one day.
    $self->minion->remove_after(86400);

    # Add task to compute all data for a project
    $self->minion->add_task( run_project => sub {
        my ($job, $project_id) = @_;
        my $ret = $self->al->run_project($project_id);
        $job->finish($ret);
    } );
    
    # Add task to compute all data for a project
    $self->minion->add_task( run_plugin => sub {
        my ($job, $project_id, $plugin_id) = @_;
        my $ret = $self->al->get_project($project_id)->run_plugin($plugin_id);
        $job->finish($ret);
    } );
    
    
    # Router
    my $r = $self->routes;
    
    # Normal route to controller
    $r->get('/')->to('alambic#welcome');
    
    # Simple pages
    $r->get('/about.html')->to( template => 'alambic/about');
    $r->get('/contact.html')->to( template => 'alambic/contact');
    $r->post('/contact')->to( 'alambic#contact_post' );
    
    # Dashboards
    my $r_projects = $r->get('/projects')->to(controller => 'dashboard');
    $r_projects->get('/#id')->to(action => 'display_summary');
    $r_projects->get('/#id/#page')->to(action => 'display_project');
    $r_projects->get('/#id/#plugin/#page')->to(action => 'display_plugins');
    
    # Admin
    my $r_admin = $r->get('/admin')->to(controller => 'admin');
    $r_admin->get('/summary')->to(action => 'summary');
    $r_admin->get('/projects')->to(action => 'projects');
    my $r_admin_projects = $r_admin->get('/projects')->to(controller => 'admin');
    $r_admin_projects->get('/new')->to(action => 'projects_new');
    $r_admin_projects->post('/new')->to(action => 'projects_new_post');
    $r_admin_projects->get('/#pid')->to(action => 'projects_show');
    $r_admin_projects->get('/#pid/run')->to(action => 'projects_run');
    $r_admin_projects->get('/#pid/del')->to(action => 'projects_del');
    
    $r_admin_projects->get('/#pid/edit')->to('admin#projects_edit');
    
    $r_admin_projects->get('/#pid/setp/#plid')->to('admin#projects_add_plugin');
    $r_admin_projects->post('/#pid/setp/#plid')->to('admin#projects_add_plugin_post');
    $r_admin_projects->get('/#pid/runp/#plid')->to('admin#projects_run_plugin');
    $r_admin_projects->get('/#pid/delp/#plid')->to('admin#projects_del_plugin');
    
    $r->get('/admin/plugins')->to( 'admin#plugins' );
    
    # Job management
    $r->get('/admin/jobs')->to( 'jobs#summary' );
    $r->get('/admin/jobs/#id')->to( 'jobs#display' );
    $r->get('/admin/jobs/#id/del')->to( 'jobs#delete' );
    $r->get('/admin/jobs/#id/run')->to( 'jobs#redo' );
    
    $r->get('/admin/repo')->to('repo#summary');
    $r->get('/admin/repo/init')->to('repo#init');
    $r->get('/admin/repo/backup')->to('repo#backup');
    $r->get('/admin/repo/restore/#file')->to('repo#restore');

    
}

1;
