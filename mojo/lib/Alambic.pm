package Alambic;
use Mojo::Base 'Mojolicious';

use Alambic::Model::Alambic;



has al => {
    state $repo = Alambic::Alambic->new();
};


# This method will run once at server start
sub startup {
  my $self = shift;

  $self->secrets(['Secrets of Alambic']);
    
  # Use application logger
  $self->log->info('Alambic v3.0 application started.');
  
  # Alambic::Alambic.pm is the main entry point for all actions;
  $self->helper( alambic => sub { state $repo = Alambic::Alambic->new() } );
  


    # # MINION management

    # # Use Minion for job queuing.
    # $self->plugin( Minion => {Pg => $self->al_config->get_pg('conf_pg')} );

    # # Set parameters.
    # # Automatically remove jobs from queue after one day. 86400 is one day.
    # $self->minion->remove_after(86400);

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
    
    # # Add task to compute all data for a project
    # $self->minion->add_task( analyse_project => sub {
    #     my ($job, $project_id) = @_;
    #     my $log_ref = $self->projects->analyse_project($project_id);
    #     my @log = @{$log_ref};
    #     $job->finish(\@log);
    # } );
    
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
  $r->get('/')->to('example#welcome');
}

1;
