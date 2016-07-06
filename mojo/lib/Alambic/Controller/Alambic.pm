package Alambic::Controller::Alambic;
use Mojo::Base 'Mojolicious::Controller';

use Data::Dumper;

# Main screen for Alambic
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
    if ( $self->app->al->users()->validate_user($username, $password) ) {
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


# Used when the user failed auth and asks for Admin.
sub failed() {
    my $self = shift;
    
    $self->render( template => 'alambic/failed' );
}

sub contact_post() {
    my $self = shift;
    
    my $name = $self->param( 'name' );
    my $email = $self->param( 'email' );
    my $message = $self->param( 'message' );

    # Prepare mail content
    my $data = $self->render_mail('alambic/contact', 
				  name => $name, 
				  email => $email, 
				  message => $message);
    # Actually send the email
    $self->mail(
	mail => {
	    To => 'boris.baldassari@gmail.com',
	    Format => 'mail',
            Data => $data,
        },
    );

    $self->flash( msg => "Message has been sent. Thank you!" );
    $self->redirect_to( '/' );    
}


1;
