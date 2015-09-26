package Alambic::Controller::Repo;

use Mojo::Base 'Mojolicious::Controller';

use Data::Dumper;


sub install {
    my $self = shift;

    # Check that the connected user has the access rights for this
    if ( not $self->users->is_user_authenticated($self->session->{session_user}, '/admin/repo' ) ) {
        $self->redirect_to( '/login' );
    }

    # Render template "alambic/repo/install.html.ep"
    $self->render(template => 'alambic/repo/install');   

}

sub install_post {
    my $self = shift;

    # Check that the connected user has the access rights for this
    if ( not $self->users->is_user_authenticated($self->session->{session_user}, '/admin/repo' ) ) {
        $self->redirect_to( '/login' );
    }

    my $git_repo = $self->param( 'git_repo' );

    # Initialise the Repo object with url.
    $self->repo->init( $git_repo );

    # Render template "alambic/repo/manage.html.ep"
    $self->redirect_to( '/admin/repo' );

}

sub push() {
    my $self = shift;

    # Check that the connected user has the access rights for this
    if ( not $self->users->is_user_authenticated($self->session->{session_user}, '/admin/repo' ) ) {
        $self->redirect_to( '/login' );
    }

    my $ret = $self->repo->push();
    print "REPO CONTROLLER $ret.\n";
    if ($ret !~ m!1!) {
        $self->flash( msg => $ret );
    }

    # Render template "alambic/repo/manage.html.ep"
    $self->redirect_to( '/admin/repo' );
}

1;
