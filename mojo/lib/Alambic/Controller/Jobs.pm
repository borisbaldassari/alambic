package Alambic::Controller::Jobs;

use Mojo::Base 'Mojolicious::Controller';

use Data::Dumper;

# Displays a list of jobs with information and actions
sub summary {
    my $self = shift;

    # Check that the connected user has the access rights for this
    if ( not $self->users->is_user_authenticated($self->session->{session_user}, '/admin/jobs' ) ) {
        $self->redirect_to( '/login' );
        return;
    }
    
    $self->render(template => 'alambic/admin/jobs');   

}

# Displays information about a single job.
sub display {
    my $self = shift;

    my $job_id = $self->param( 'id' );

    # Check that the connected user has the access rights for this
    if ( not $self->users->is_user_authenticated($self->session->{session_user}, '/admin/jobs' ) ) {
        $self->redirect_to( '/login' );
        return;
    }

    # Prepare data for template and render.
    $self->stash( job_id => $job_id );
    $self->render(template => 'alambic/admin/job');   

}

# Recycles a job (re-start it).
sub redo {
    my $self = shift;
    my $job_id = $self->param( 'id' );

    # Check that the connected user has the access rights for this
    if ( not $self->users->is_user_authenticated($self->session->{session_user}, '/admin/jobs' ) ) {
        $self->redirect_to( '/login' );
        return;
    }

    # Enqueue job
    my $job_info = $self->minion->backend->job_info($job_id);
    my $job = $self->minion->enqueue($job_info->{'task'} => $job_info->{'args'} => { delay => 0 });

    $self->flash( msg => "Job [$job] has been relaunched with ID [$job]." );
    $self->redirect_to( "/admin/jobs/$job" );

}

# Deletes a job
sub delete {
    my $self = shift;
    my $job_id = $self->param( 'id' );

    # Check that the connected user has the access rights for this
    if ( not $self->users->is_user_authenticated($self->session->{session_user}, '/admin/jobs' ) ) {
        $self->redirect_to( '/login' );
        return;
    }

    $self->minion->backend->remove_job($job_id);

    $self->flash( msg => "Job [$job_id] has been deleted." );
    $self->redirect_to( '/admin/jobs' );

}

1;
