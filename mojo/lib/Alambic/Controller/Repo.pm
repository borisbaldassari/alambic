package Alambic::Controller::Repo;

use Mojo::Base 'Mojolicious::Controller';

use Data::Dumper;


sub welcome {
    my $self = shift;

    # Render template "alambic/repo/install.html.ep"
    $self->render(template => 'alambic/repo/install');   

}

sub welcome_post {
    my $self = shift;

    my $git_repo = $self->param( 'git_repo' );

    # Initialise the Repo object with url.
    $self->repo->init( $git_repo );

    # Render template "alambic/repo/manage.html.ep"
    $self->redirect_to( '/admin/repo' );

}

sub manage() {
    my $self = shift;

    # Render template "alambic/repo/manage.html.ep"
    $self->render( template => 'alambic/repo/manage' );
}

1;
