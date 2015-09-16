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

    print "[Controller::Alambic] login_post before authenticate().\n";
    $self->users->validate_user($username, $password);
    print "[Controller::Alambic] login_post after authenticate().\n";
    $self->session( 'session_user' => $username );
#    my $user = $self->current_user();

    $self->render( 'alambic/admin/welcome', msg => "You have been successfully authenticated.");
}

sub logout() {
    my $self = shift;

    print "[Controller::Alambic] DBG log out.\n";
    delete $self->session->{session_user};

    $self->redirect_to( '/' );
}

1;
