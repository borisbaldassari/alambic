package Alambic::Controller::Users;
use Mojo::Base 'Mojolicious::Controller';

use Data::Dumper;

# Displays information about a single user.
sub profile {
    my $self = shift;

    my $user_id = $self->param( 'id' );

    # Prepare data for template and render.
    $self->stash( user_id => $user_id );
    $self->render(template => 'alambic/user/profile');   

}

# Displays information about a single user.
sub projects {
    my $self = shift;

    my $user_id = $self->param( 'id' );
    my $project_id = $self->param( 'project' );

    # Prepare data for template and render.
    $self->stash( user_id => $user_id, project_id => $project_id );
    $self->render(template => 'alambic/user/project');   

}


1;
