package Alambic::Controller::DataSources;

use Mojo::Base 'Mojolicious::Controller';

use Data::Dumper;


sub welcome {
    my $self = shift;

    # Check that the connected user has the access rights for this
    if ( not $self->users->is_user_authenticated($self->session->{session_user}, '/admin/ds' ) ) {
        $self->redirect_to( '/login' );
    }

    print "[Controller::DataSources] welcome.\n";

    # Render template 
    $self->render( template => 'alambic/ds/manage' );   

}

1;
