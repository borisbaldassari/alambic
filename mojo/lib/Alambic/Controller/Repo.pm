package Alambic::Controller::Repo;

use Mojo::Base 'Mojolicious::Controller';

use Data::Dumper;


sub init {
    my $self = shift;

    # Check that the connected user has the access rights for this
    if ( not $self->users->is_user_authenticated($self->session->{session_user}, '/admin/repo' ) ) {
        $self->redirect_to( '/login' );
        return;
    }

    # Render template "alambic/repo/init.html.ep"
    $self->render(template => 'alambic/repo/init');   

}

sub init_post {
    my $self = shift;

    # Check that the connected user has the access rights for this
    if ( not $self->users->is_user_authenticated($self->session->{session_user}, '/admin/repo' ) ) {
        $self->redirect_to( '/login' );
        return;
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
        return;
    }

    my $ret = $self->repo->push();
    if ($ret !~ m!1!) {
        $self->flash( msg => $ret );
    }

    # Render template "alambic/repo/manage.html.ep"
    $self->redirect_to( '/admin/repo' );
}

1;
