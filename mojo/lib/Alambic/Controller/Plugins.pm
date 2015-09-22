package Alambic::Controller::Plugins;

use Mojo::Base 'Mojolicious::Controller';

use Data::Dumper;


sub welcome {
    my $self = shift;

    # Check that the connected user has the access rights for this
    if ( not $self->users->is_user_authenticated($self->session->{session_user}, '/admin/ds' ) ) {
        $self->redirect_to( '/login' );
    }

    # Render template 
    $self->render( template => 'alambic/plugins/manage' );   

}


#
# Add a plugin to a project -- GET.
#
sub add_project {
    my $self = shift;

    my $project = $self->param( 'id' );
    my $ds = $self->param( 'ds' );

    my $plugin = $self->al_plugins->get_plugin($ds);
    my $conf = $plugin->get_conf();

    # Prepare data for template.
    $self->stash(
        project => $project,
        conf => $conf,
        );    
    
    # Render template 
    $self->render( template => 'alambic/plugins/add_project' );   
}


#
# Add a plugin to a project -- POST.
#
sub add_project_post {
    my $self = shift;

    my $project = $self->param( 'id' );
    my $ds = $self->param( 'ds' );

    my $plugin = $self->al_plugins->get_plugin($ds);
    my $conf = $plugin->get_conf();

    my %args;
    foreach my $param ( keys %{$conf->{'requires'}} ) {
        $args{$param} = $self->param( $param );
    }

    $self->projects->add_project_ds($project, $ds, %args);
    
    # Render template 
    $self->redirect_to( "/admin/project/$project" );   
}


#
# Remove a plugin from a project.
#
sub del_project {
    my $self = shift;

    my $project = $self->param( 'id' );
    my $ds = $self->param( 'ds' );

    $self->projects->delete_project_ds($project, $ds);
    
    # Render template 
    $self->redirect_to( "/admin/project/$project" );   
}


#
# Retrieve data for a specific plugin and project.
#
sub project_retrieve_data {
    my $self = shift;

    my $project_id = $self->param( 'id' );
    my $ds = $self->param( 'ds' );

    $self->al_plugins->get_plugin($ds)->retrieve_data($project_id);
    
    # Render template 
    $self->redirect_to( "/admin/project/$project_id" );   
}


#
# Compute metrics and files for a specific plugin and project.
#
sub project_compute_data {
    my $self = shift;

    my $project_id = $self->param( 'id' );
    my $ds = $self->param( 'ds' );

    $self->al_plugins->get_plugin($ds)->compute_data($project_id);
    
    # Render template 
    $self->redirect_to( "/admin/project/$project_id" );   
}


1;
