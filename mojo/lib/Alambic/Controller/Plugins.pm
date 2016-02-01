package Alambic::Controller::Plugins;

use Mojo::Base 'Mojolicious::Controller';
use Mojo::IOLoop;

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
        $self->flash( msg => "You must have rights on project $project_id to access this area." );
        $self->redirect_to( '/login' );
        return;
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
        $self->flash( msg => "You must have rights on project $project_id to access this area." );
        $self->redirect_to( '/login' );
        return;
    }

    my $conf = $self->al_plugins->get_plugin($ds)->get_conf();
    my %args;
    foreach my $param ( keys %{$conf->{'requires'}} ) {
        $args{$param} = $self->param( $param );
    }

    $self->app->log->debug( "[Controller::Plugins] add_project_post [$project_id] [$ds]." );

    $self->app->projects->set_project_ds($project_id, $ds, \%args);
    
    # Render template 
    $self->flash( msg => "Plugin [$ds] added to project [$project_id]." );
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
        $self->flash( msg => "You must have rights on project $project_id to access this area." );
        $self->redirect_to( '/login' );
        return;
    }

    $self->app->projects->delete_project_ds($project_id, $ds);
    
    # Render template 
    $self->redirect_to( "/admin/project/$project_id" );   
}


#
# Check data for a specific plugin and project.
#
sub check_project {
    my $self = shift;

    my $project_id = $self->param( 'id' );
    my $ds = $self->param( 'ds' );

    # Check that the connected user has the access rights for this
    unless ( $self->users->has_user_project($self->session->{'session_user'}, $project_id) || 
             $self->users->is_user_authenticated($self->session->{'session_user'}, '/admin/projects' ) ) {
        $self->flash( msg => "You must have rights on project $project_id to access this area." );
        $self->redirect_to( '/login' );
        return;
    }

    my $ret = $self->al_plugins->get_plugin($ds)->check_project($project_id);
    my $ret_str = join( '<br />', @{$ret} );
    $self->flash( msg => $ret_str );
    
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
    
    my @log;

    # Check that the connected user has the access rights for this
    unless ( $self->users->has_user_project($self->session->{'session_user'}, $project_id) || 
             $self->users->is_user_authenticated($self->session->{'session_user'}, '/admin/projects' ) ) {
        $self->flash( msg => "You must have rights on project $project_id to access this area." );
        $self->redirect_to( '/login' );
        return;
    }

    my $job = $self->minion->enqueue(retrieve_data_ds => [ $ds, $project_id ] => { delay => 0 });
    push( @log, "Job [$job] has been queued." );

    $self->flash( msg => join( '<br />', @log ) );
    $self->redirect_to( "/admin/project/$project_id" );   
}


#
# Compute metrics and files for a specific plugin and project.
#
sub project_compute_data {
    my $self = shift;

    my @log;

    my $project_id = $self->param( 'id' );
    my $ds = $self->param( 'ds' );

    # Check that the connected user has the access rights for this
    unless ( $self->users->has_user_project($self->session->{'session_user'}, $project_id) || 
             $self->users->is_user_authenticated($self->session->{'session_user'}, '/admin/projects' ) ) {
        $self->flash( msg => "You must have rights on project $project_id to access this area." );
        $self->redirect_to( '/login' );
        return;
    }

    $self->app->log->debug( "[Controller::Plugins] project_compute_data [$project_id] [$ds]." );

    my $job = $self->minion->enqueue(compute_data_ds => [ $ds, $project_id ] => { delay => 0 });
    push( @log, "Job [$job] has been queued." );

    $self->flash( msg => join( '<br />', @log ) );
    $self->redirect_to( "/admin/project/$project_id" );

}


1;
