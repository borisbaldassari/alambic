package Alambic::Controller::Alambic;
use Mojo::Base 'Mojolicious::Controller';

use Data::Dumper;

# Install screen for Alambic.
sub install {
    my $self = shift;
	
    # Render template "alambic/install.html.ep"
    $self->render();
}

# Install screen for Alambic.
sub install_post {
    my $self = shift;

    my $name = $self->param( 'name' );
    my $desc = $self->param( 'desc' );
    my $password = $self->param( 'password' );

    # Set instance parameters
    $self->app->al->get_repo_db()->name($name);
    $self->app->al->get_repo_db()->desc($desc);

    # Set administrator parameters.
    my $email = $self->param( 'email' );
    my $passwd = $self->param( 'passwd' );
    
    my $project = $self->app->al->set_user( 'administrator', 'Administrator', $email, 
					    $passwd, ['Admin'], [], {} );
    kill USR2 => getppid;
    
    $self->session( 'session_user' => 'administrator' );
    $self->flash( msg => "The instance has been configured and user administrator has been created.<br />"
		  . "You are now authenticated." );
    $self->redirect_to( '/' );
	
}

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
    my $users = $self->app->al->users();
    my $valid = $users->validate_user($username, $password);
    if ( $valid ) {
        $self->session( 'session_user' => $username );
        $self->flash( msg => "You have been successfully authenticated as user $username." );
        $self->redirect_to( '/user/' . $username . '/profile' );
    } else {
	delete $self->session->{session_user};
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
    
    $self->render( template => 'alambic/failed', status => 403 );
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

    # Get the administrator email address.
    my $admin = $self->app->al->get_user('administrator');

    if (defined($admin->{'email'})) {
	# Actually send the email
	$self->mail(
	    mail => { To => $admin->{'email'}, Format => 'mail', Data => $data }
	    );
	$self->flash( msg => "Message has been sent. Thank you!" );
    } else {
	$self->flash( msg => "Message could not be sent: cannot find an email address for administrator." );
    }
    
    $self->redirect_to( '/' );    
}


1;
