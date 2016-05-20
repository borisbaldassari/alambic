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

    my $conf_mail = {
	from     => 'alambic@castalia.solutions',
	encoding => 'base64',
	type     => 'text/html',
	how      => 'sendmail',
	howargs  => [ '/usr/sbin/sendmail -t' ],
    };
    
    $self->plugin( 'mail' => $conf_mail );
    
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

    # Add task to create a project with a wizard
    $self->minion->add_task( add_project_wizard => sub {
        my ($job, $wizard, $project_id) = @_;
        my $ret = $self->al->create_project_from_wizard($wizard, $project_id);
        $job->finish($ret);
    } );
    
    # Add task to compute all data for a project
    $self->minion->add_task( run_project => sub {
        my ($job, $project_id) = @_;
        my $ret = $self->al->run_project($project_id);
        $job->finish($ret);
    } );
    
    # Add task to run a single plugin
    # Partial runs are not recorded in the db and can only be viewed in the job log.
    $self->minion->add_task( run_plugin => sub {
        my ($job, $project_id, $plugin_id) = @_;
        my $ret = $self->al->get_project($project_id)->run_plugin($plugin_id);
        $job->finish($ret);
    } );

    # Add task to run all plugins
    # Partial runs are not recorded in the db and can only be viewed in the job log.
    $self->minion->add_task( run_plugins => sub {
        my ($job, $project_id) = @_;
        my $ret = $self->al->run_plugins($project_id);
        $job->finish($ret);
    } );

    # Add task to run qm analysis
    # Partial runs are not recorded in the db and can only be viewed in the job log.
    $self->minion->add_task( run_qm => sub {
        my ($job, $project_id) = @_;
        my $ret = $self->al->run_qm($project_id);
        $job->finish($ret);
    } );
    
    # Add task to run post plugins
    # Partial runs are not recorded in the db and can only be viewed in the job log.
    $self->minion->add_task( run_post => sub {
        my ($job, $project_id) = @_;
        my $ret = $self->al->run_post($project_id);
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

    # Documentation
    $r->get('/documentation/#id')->to( 'documentation#welcome' );
    
    # Dashboards
    my $r_projects = $r->get('/projects')->to(controller => 'dashboard');
    $r_projects->get('/#id')->to(action => 'display_summary');
    $r_projects->get('/#id/#page')->to(action => 'display_project');
    $r_projects->get('/#id/#plugin/#page')->to(action => 'display_plugins');

    # JSON data for models 
    $r->get('/data/#page')->to( 'admin#data' );
    
    # Admin
    my $r_admin = $r->any('/admin')->to(controller => 'admin');
    $r_admin->get('/summary')->to(action => 'summary');
    $r_admin->get('/projects')->to(action => 'projects');
    my $r_admin_projects = $r_admin->any('/projects')->to(controller => 'admin');
    $r_admin_projects->get('/new')->to(action => 'projects_new');
    $r_admin_projects->post('/new')->to(action => 'projects_new_post');
    # Wizards
    $r_admin_projects->get('/new/#wiz')->to(action => 'projects_wizards_new_init');
    $r_admin_projects->post('/new/#wiz')->to(action => 'projects_wizards_new_init_post');
    $r_admin_projects->get('/new/#wiz/#pid')->to(action => 'projects_wizards_new');
    $r_admin_projects->post('/new/#wiz/#pid')->to(action => 'projects_wizards_new_post');
    # projects
    $r_admin_projects->get('/#pid')->to(action => 'projects_show');
    $r_admin_projects->get('/#pid/run')->to(action => 'projects_run');
    $r_admin_projects->get('/#pid/run/pre')->to(action => 'projects_run_pre');
    $r_admin_projects->get('/#pid/run/qm')->to(action => 'projects_run_qm');
    $r_admin_projects->get('/#pid/run/post')->to(action => 'projects_run_post');
    $r_admin_projects->get('/#pid/del')->to(action => 'projects_del');    
    $r_admin_projects->get('/#pid/edit')->to(action => 'projects_edit');
    $r_admin_projects->post('/#pid/edit')->to(action => 'projects_edit_post');
    
    $r_admin_projects->get('/#pid/setp/#plid')->to( action => 'projects_add_plugin' );
    $r_admin_projects->post('/#pid/setp/#plid')->to( action => 'projects_add_plugin_post' );
    $r_admin_projects->get('/#pid/runp/#plid')->to( action => 'projects_run_plugin' );
    $r_admin_projects->get('/#pid/delp/#plid')->to( action => 'projects_del_plugin' );
    
    $r_admin->get('/models')->to( 'admin#models' );
    $r_admin->get('/models/import')->to( 'admin#models_import' );
    $r_admin->get('/models/init')->to( 'admin#models_init' );
    # my $r_admin_models = $r->get('/admin/models/')->to( controller => 'admin' );
    
    $r->get('/admin/plugins')->to( 'admin#plugins' );
    $r->get('/admin/plugins_pre')->to( 'admin#plugins_pre' );
    $r->get('/admin/plugins_post')->to( 'admin#plugins_post' );
    $r->get('/admin/plugins_global')->to( 'admin#plugins_global' );
    $r->get('/admin/plugins_wizards')->to( 'admin#plugins_wizards' );
    
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
