package Alambic::Controller::Admin;

use Mojo::Base 'Mojolicious::Controller';

use Data::Dumper;


# This action will render a template
sub welcome {
    my $self = shift;
    
    # Render template for main admin section
    $self->render( template => 'alambic/admin/welcome' );
}


sub read_files() {
    my $self = shift;

    # Check that the connected user has the access rights for this
    if ( not $self->users->is_user_authenticated($self->session->{session_user}, '/admin/read_files' ) ) {
        $self->redirect_to( '/login' );
    }
    
    my $files = $self->param( 'files' );
    my $msg;

    if ($files =~ m!models!) {
        $self->models->read_all_files();
        $msg = "All model files reread.";
    } elsif ($files =~ m!projects!) {
        $self->projects->read_all_files();
        $msg = "All project files reread.";
    } else {
        $msg = "Could not understand command. Files not read.";
    }

    $self->render( template => 'alambic/admin/welcome', msg => $msg );
}


sub projects_main {
    my $self = shift;
    
    # Check that the connected user has the access rights for this
    if ( not $self->users->is_user_authenticated($self->session->{session_user}, '/admin/projects' ) ) {
        $self->redirect_to( '/login' );
    }
             
    my %projects = $self->projects->get_all_projects();

    # Prepare data for template.
    $self->stash(
        projects => \%projects,
        );    
    
    # Render template for projects admin section
    $self->render( template => 'alambic/admin/projects' );
}

sub users_main {
    my $self = shift;

    # Check that the connected user has the access rights for this
    $self->redirect_to( '/login' ) unless (
        exists( $self->session->{session_user} ) &&
        $self->users->is_user_authenticated($self->session->{session_user}, '/admin/users' ) 
        );
    
    $self->render( template => 'alambic/admin/users' );
}

sub check_project {
    
}

1;
