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

sub install {
    my $self = shift;

    # Check that the connected user has the access rights for this
    if ( not $self->users->is_user_authenticated($self->session->{session_user}, '/admin/repo' ) ) {
        $self->redirect_to( '/login' );
    }

    # Render template "alambic/repo/init.html.ep"
    $self->render(template => 'alambic/admin/install');   

}

sub install_post {
    my $self = shift;

    # Check that the connected user has the access rights for this
    if ( not $self->users->is_user_authenticated($self->session->{session_user}, '/admin/repo' ) ) {
        $self->redirect_to( '/login' );
    }

    my $title = $self->param( 'title' );
    my $name = $self->param( 'name' );
    my $desc = $self->param( 'desc' );
    my $git_repo = $self->param( 'git_repo' );

    # Save new values for the current instance
    $self->app->al_config->set_conf($title, $name, $desc);

    # Initialise the Repo object with url.
    $self->repo->init( $git_repo );

    # Render template "alambic/summary.html.ep" with a confirmation message.
    $self->flash( msg => "New instance has been correctly initialised." );
    $self->redirect_to( '/admin/summary' );

}


1;
