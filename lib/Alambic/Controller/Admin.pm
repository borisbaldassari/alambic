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

    my $files = $self->param( 'files' );

    if ($files =~ m!models!) {
        $self->models->read_all_files();
    } elsif ($files =~ m!projects!) {
        $self->projects->read_all_files();
    }

    $self->render( template => 'alambic/admin/welcome' );
}


sub projects_main {
    my $self = shift;
    
    my %projects = $self->projects->get_all_projects();

    # Prepare data for template.
    $self->stash(
        projects => \%projects,
        );    
    
    # Render template for projects admin section
    $self->render( template => 'alambic/admin/projects' );
}

sub check_project {
    
}

1;
