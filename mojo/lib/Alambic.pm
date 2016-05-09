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

    # # Add task to retrieve ds data
    # $self->minion->add_task( retrieve_data_ds => sub {
    #     my ($job, $ds, $project_id) = @_;
    #     my $log_ref = $self->al_plugins->get_plugin($ds)->retrieve_data($project_id);
    #     my @log = @{$log_ref};
    #     $job->finish(\@log);
    # } );

    # # Add task to compute ds data
    # $self->minion->add_task( compute_data_ds => sub {
    #     my ($job, $ds, $project_id) = @_;
    #     my $log_ref = $self->al_plugins->get_plugin($ds)->compute_data($project_id);
    #     my @log = @{$log_ref};
    #     $job->finish(\@log);
    # } );
    
    # # Add task to retrieve all data for a project
    # $self->minion->add_task( retrieve_project => sub {
    #     my ($job, $project_id) = @_;
    #     my $log_ref = $self->projects->retrieve_project_data($project_id);
    #     my @log = @{$log_ref};
    #     $job->finish(\@log);
    # } );
    
    # Add task to compute all data for a project
    $self->minion->add_task( run_project => sub {
        my ($job, $project_id) = @_;
        my $ret = $self->al->run_project($project_id);
        $job->finish($ret);
    } );
    
    # # Add task to run both retrieval and analysis for a project
    # $self->minion->add_task( run_project => sub {
    #     my ($job, $project_id) = @_;
    #     my $log_ref_retrieve = $self->projects->retrieve_project_data($project_id);
    #     my $log_ref_analyse = $self->projects->analyse_project($project_id);
    #     my @log = ( @{$log_ref_retrieve}, @{$log_ref_analyse} );
    #     $job->finish(\@log);
    # } );
  
    
    # Router
    my $r = $self->routes;
    
    # Normal route to controller
    $r->get('/')->to('alambic#welcome');
    
    # Admin
    $r->get('/admin/summary')->to('admin#summary');
    $r->get('/admin/projects')->to('admin#projects');
    $r->get('/admin/projects/new')->to('admin#projects_new');
    $r->post('/admin/projects/new')->to('admin#projects_new_post');
    $r->get('/admin/projects/#pid')->to('admin#projects_show');
    $r->get('/admin/projects/#pid/run')->to('admin#projects_run');
    $r->get('/admin/projects/#pid/del')->to('admin#projects_del');
    
    $r->get('/admin/projects/#pid/edit')->to('admin#projects_edit');
    
    $r->get('/admin/projects/#pid/setp/#plid')->to('admin#projects_add_plugin');
    $r->post('/admin/projects/#pid/setp/#plid')->to('admin#projects_add_plugin_post');
    $r->get('/admin/projects/#pid/runp/#plid')->to('admin#projects_run_plugin');
    $r->get('/admin/projects/#pid/delp/#plid')->to('admin#projects_del_plugin');
    
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
