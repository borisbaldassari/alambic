package Alambic::Controller::Plugins;

use Mojo::Base 'Mojolicious::Controller';

use Data::Dumper;


#
# Add a plugin to a project -- GET.
#
sub add_project {
    my $self = shift;

    my $project_id = $self->param( 'id' );
    my $ds = $self->param( 'ds' );

    # Check that the connected user has the access rights for this
    unless ( $self->users->has_user_project($self->session->{'session_user'}, $project_id) || 
             $self->users->is_user_authenticated($self->session->{'session_user'}, '/admin/projects' ) ) {
        $self->flash( msg => 'You must have rights on project $project_id to access this area.' );
        $self->redirect_to( '/login' );
    }

    my $plugin = $self->al_plugins->get_plugin($ds);
    my $conf = $plugin->get_conf();

    # Prepare data for template.
    $self->stash(
        project => $project_id,
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

    my $project_id = $self->param( 'id' );
    my $ds = $self->param( 'ds' );

    # Check that the connected user has the access rights for this
    unless ( $self->users->has_user_project($self->session->{'session_user'}, $project_id) || 
             $self->users->is_user_authenticated($self->session->{'session_user'}, '/admin/projects' ) ) {
        $self->flash( msg => 'You must have rights on project $project_id to access this area.' );
        $self->redirect_to( '/login' );
    }

    my $plugin = $self->al_plugins->get_plugin($ds);
    my $conf = $plugin->get_conf();

    my %args;
    foreach my $param ( keys %{$conf->{'requires'}} ) {
        $args{$param} = $self->param( $param );
    }

    $self->projects->add_project_ds($project_id, $ds, %args);
    
    # Render template 
    $self->redirect_to( "/admin/project/$project_id" );   
}


#
# Remove a plugin from a project.
#
sub del_project {
    my $self = shift;

    my $project_id = $self->param( 'id' );
    my $ds = $self->param( 'ds' );

    # Check that the connected user has the access rights for this
    unless ( $self->users->has_user_project($self->session->{'session_user'}, $project_id) || 
             $self->users->is_user_authenticated($self->session->{'session_user'}, '/admin/projects' ) ) {
        $self->flash( msg => 'You must have rights on project $project_id to access this area.' );
        $self->redirect_to( '/login' );
    }

    $self->projects->delete_project_ds($project_id, $ds);
    
    # Render template 
    $self->redirect_to( "/admin/project/$project_id" );   
}


#
# Retrieve data for a specific plugin and project.
#
sub project_retrieve_data {
    my $self = shift;

    my $project_id = $self->param( 'id' );
    my $ds = $self->param( 'ds' );

    # Check that the connected user has the access rights for this
    unless ( $self->users->has_user_project($self->session->{'session_user'}, $project_id) || 
             $self->users->is_user_authenticated($self->session->{'session_user'}, '/admin/projects' ) ) {
        $self->flash( msg => 'You must have rights on project $project_id to access this area.' );
        $self->redirect_to( '/login' );
    }

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

    # Check that the connected user has the access rights for this
    unless ( $self->users->has_user_project($self->session->{'session_user'}, $project_id) || 
             $self->users->is_user_authenticated($self->session->{'session_user'}, '/admin/projects' ) ) {
        $self->flash( msg => 'You must have rights on project $project_id to access this area.' );
        $self->redirect_to( '/login' );
    }

    $self->al_plugins->get_plugin($ds)->compute_data($project_id);
    
    # Render template 
    $self->redirect_to( "/admin/project/$project_id" );   
}


1;
