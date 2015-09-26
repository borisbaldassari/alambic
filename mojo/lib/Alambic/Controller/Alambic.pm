package Alambic::Controller::Alambic;
use Mojo::Base 'Mojolicious::Controller';

# This action will render a template
sub welcome {
    my $self = shift;

    # Render template "alambic/welcome.html.ep"
    $self->render();
}

sub login() {
    my $self = shift;

    $self->render( template => 'alambic/login' );
}

sub login_post() {
    my $self = shift;

    my $username = $self->param( 'username' );
    my $password = $self->param( 'password' );

    # Check return value for login.
    if ( $self->users->validate_user($username, $password) ) {
        $self->session( 'session_user' => $username );
        $self->flash( msg => "You have been successfully authenticated as user $username." );
        $self->redirect_to( '/admin/summary' );
    } else {
        $self->flash( msg => "Wrong login/password. Sorry." );
        $self->redirect_to( '/login' );
    }
}

sub logout() {
    my $self = shift;

    delete $self->session->{session_user};

    $self->redirect_to( '/' );
}

1;