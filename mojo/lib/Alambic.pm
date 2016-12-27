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
    
    # Add another namespace to load commands from
    push @{$self->commands->namespaces}, 'Alambic::Commands';
    
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
    
    # Get config from alambic.conf
    my $config = $self->plugin('Config');

    # Use Minion for job queuing.
    $self->plugin( Minion => {Pg => $config->{'conf_pg_minion'}} );

    # MINION management

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
        my ($job, $project_id, $user) = @_;
        my $ret = $self->al->run_project($project_id, $user);
        $job->finish($ret);
    } );
    
    # Add task to run a single plugin
    # Partial runs are not recorded in the db and can only be viewed in the job log.
    $self->minion->add_task( run_plugin => sub {
        my ($job, $project_id, $plugin_id) = @_;
	my $ret; 

	my $plugin_conf = $self->app->al->get_plugins()->get_plugin($plugin_id)->get_conf();
	my $models = $self->app->al->get_models();

	if ($plugin_conf->{'type'} =~ /^pre$/ ) {
	    $ret = $self->al->get_project($project_id)->run_plugin($plugin_id);
	} elsif ($plugin_conf->{'type'} =~ /^post$/ ) {
	    $ret = $self->al->get_project($project_id)->run_post($plugin_id, $models);
	} else { $ret->{'log'} = [ "Plugin ID [$plugin_id] is not recognised." ] }
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
    $self->minion->add_task( run_posts => sub {
        my ($job, $project_id) = @_;
        my $ret = $self->al->run_posts($project_id);
        $job->finish($ret);
    } );
    


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
    $r->get('/')->to( 'alambic#welcome' );
    
    # Simple pages
    $r->get('/about')->to( template => 'alambic/about');
    $r->get('/contact')->to( template => 'alambic/contact');
    $r->post('/contact')->to( 'alambic#contact_post' );
    $r->get('/login')->to( 'alambic#login' );
    $r->post('/login')->to( 'alambic#login_post' );
    $r->get('/logout')->to( 'alambic#logout' );

    # Documentation
    $r->get('/documentation/#id')->to( 'documentation#welcome' );
    
    # Dashboards
    my $r_projects = $r->get('/projects')->to( controller => 'dashboard' );
    $r_projects->get('/#id')->to( action => 'display_summary' );
    $r_projects->get('/#id/#page')->to( action => 'display_project' );
    $r_projects->get('/#id/#plugin/#page')->to( action => 'display_plugins' );
    $r_projects->post('/#id/#plugin/#page')->to( action => 'display_plugins_post' );
    $r_projects->get('/#id/#plugin/figures/#page')->to( action => 'display_figures' );

    # JSON data for models 
    $r->get('/models/#page')->to( 'admin#data_models' );

    ### Protected routes
    $self->routes->add_condition(
    	role => sub {
    	    my ( $r, $c, $captures, $role ) = @_;
	    my $user = $self->al->users->get_user($c->session->{'session_user'}) || {};

    	    # Keep the weirdos out!
    	    return undef
    		if ( !exists( $c->session->{'session_user'} )
    		     || not grep { $_ eq ${role} } @{$user->{'roles'}} );

    	    # It's ok, we know him
    	    return 1;
    	}
    	);

    # Admin
    my $r_admin = $r->any('/admin')->over( role => 'Admin' )->to( controller => 'admin' );   
    
    $r_admin->get('/edit')->to( action => 'edit' );
    $r_admin->post('/edit')->to( action => 'edit_post' );
    $r_admin->get('/summary')->to(action => 'summary');
    $r_admin->get('/projects')->to(action => 'projects');
    $r_admin->get('/users')->to(action => 'users');
    $r_admin->get('/users/new')->to(action => 'users_new');
    $r_admin->post('/users/new')->to(action => 'users_new_post');
    $r_admin->get('/users/#uid')->to(action => 'users_edit');
    $r_admin->post('/users/#uid')->to(action => 'users_edit_post');
    $r_admin->get('/users/#uid/del')->to(action => 'users_del');
    
    $r_admin->get('/models')->to( action => 'models' );
    $r_admin->get('/models/import')->to( action => 'models_import' );
    $r_admin->get('/models/init')->to( action => 'models_init' );
    
    my $r_admin_projects = $r_admin->any('/projects')->to(controller => 'admin');
    $r_admin_projects->get('/new')->to(action => 'projects_new');
    $r_admin_projects->post('/new')->to(action => 'projects_new_post');

    # Wizards
    $r_admin_projects->get('/new/#wiz')->to(action => 'projects_wizards_new_init');
    $r_admin_projects->post('/new/#wiz')->to(action => 'projects_wizards_new_init_post');
    $r_admin_projects->get('/new/#wiz/#pid')->to(action => 'projects_wizards_new');
    $r_admin_projects->post('/new/#wiz/#pid')->to(action => 'projects_wizards_new_post');
    
    # Projects
    $r_admin_projects->get('/#pid')->to(action => 'projects_show');
    $r_admin_projects->get('/#pid/run')->to(action => 'projects_run');
    $r_admin_projects->get('/#pid/run/pre')->to(action => 'projects_run_pre');
    $r_admin_projects->get('/#pid/run/qm')->to(action => 'projects_run_qm');
    $r_admin_projects->get('/#pid/run/post')->to(action => 'projects_run_posts');
    $r_admin_projects->get('/#pid/del')->to(action => 'projects_del');    
    $r_admin_projects->get('/#pid/edit')->to(action => 'projects_edit');
    $r_admin_projects->post('/#pid/edit')->to(action => 'projects_edit_post');
    $r_admin_projects->get('/#pid/setp/#plid')->to( action => 'projects_add_plugin' );
    $r_admin_projects->post('/#pid/setp/#plid')->to( action => 'projects_add_plugin_post' );
    $r_admin_projects->get('/#pid/runp/#plid')->to( action => 'projects_run_plugin' );
    $r_admin_projects->get('/#pid/delp/#plid')->to( action => 'projects_del_plugin' );
    $r_admin_projects->get('/#pid/del_input_file/#file')->to( 'admin#del_input_file' );
    $r_admin_projects->get('/#pid/del_output_file/#file')->to( 'admin#del_output_file' );
    # my $r_admin_models = $r->get('/admin/models/')->to( controller => 'admin' );

    # Job management
    $r_admin->get('/jobs')->to( 'jobs#summary' );
    $r_admin->get('/jobs/#id')->to( 'jobs#display' );
    $r_admin->get('/jobs/#id/del')->to( 'jobs#delete' );
    $r_admin->get('/jobs/#id/run')->to( 'jobs#redo' );

    # Database manipulations.
    $r_admin->get('/repo')->to('repo#summary');
    $r_admin->get('/repo/init')->to('repo#init');
    $r_admin->get('/repo/backup')->to('repo#backup');
    $r_admin->get('/repo/restore/#file')->to('repo#restore');
    $r_admin->get('/repo/dl/#file')->to('repo#dl');
    $r_admin->get('/repo/del_backup/#file')->to('repo#delete');
 
    # Admin fallback when no auth
    $r->any('/admin/*')->to( 'alambic#failed' );   
    
}

1;
