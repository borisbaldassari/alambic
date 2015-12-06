package Alambic::Controller::CustomData;

use Mojo::Base 'Mojolicious::Controller';
use Data::Dumper;

# Displays the form to add a new instance of the survey.
sub add_to_project {
    my $self = shift;
  
    my $project_id = $self->param( 'proj' );
    my $cd = $self->param( 'cd' );

    # Check that the connected user has the access rights for this
    unless ( $self->users->has_user_project($self->session->{'session_user'}, $project_id) || 
             $self->users->is_user_authenticated($self->session->{'session_user'}, '/admin/projects' ) ) {
        $self->flash( msg => 'You must have rights on project $project_id to access this area.' );
        $self->redirect_to( '/login' );
    }

    my $conf = $self->al_plugins->get_plugin($cd)->get_conf();
    my %args;
    foreach my $param ( keys %{$conf->{'requires'}} ) {
        $args{$param} = $self->param( $param );
    }

    $self->app->log->debug( "[Controller::CustomData] add_project_post [$project_id] [$cd]." );

    $self->app->projects->set_project_cd($project_id, $cd, \%args);
    
    # Render template 
    $self->flash( msg => "Plugin [$cd] added to project [$project_id]." );
    $self->redirect_to( "/admin/project/$project_id" );   
}


# Displays list of custom data plugins enabled for each project, and 
# provides links to see the results.
sub display {
    my $self = shift;
  
    my $project_id = $self->param( 'proj' );
    
    print Dumper($self->app->projects->get_project_info($project_id));

    # Prepare data for template.
    $self->stash(
        project_id => $project_id,
        cdata_id => undef,
        );    
    
    # Render template 
    $self->render( "alambic/admin/customdata" );   
}


# Displays the results recorded for this custom data.
sub show {
    my $self = shift;
  
    my $project_id = $self->param( 'proj' );
    my $cd = $self->param( 'cd' );    

    print Dumper($self->app->projects->get_project_info($project_id));

    # Prepare data for template.
    $self->stash(
        project_id => $project_id,
        cdata_id => $cd,
        );    
    
    # Render template 
    $self->render( "alambic/admin/customdata" );   
}

# Displays the form to add an entry for the specific manual data type.
sub add {
    my $self = shift;
  
    my $project_id = $self->param( 'proj' );
    my $cd = $self->param( 'cd' );    
  
    # Check that the connected user has the access rights for this
    unless ( $self->users->has_user_project($self->session->{'session_user'}, $project_id) || 
             $self->users->is_user_authenticated($self->session->{'session_user'}, '/admin/projects' ) ) {
        $self->flash( msg => 'You must have rights on project $project_id to access this area.' );
        $self->redirect_to( '/login' );
    }

    my $plugin = $self->al_plugins->get_plugin($cd);
    my $conf = $plugin->get_conf();

    # Prepare data for template.
    $self->stash(
        project_id => $project_id,
        conf => $conf,
        );    
    
    # Render template for projects admin section
    $self->render( template => 'alambic/plugins/add_customdata' );
}


# Handle the custom data form once it has been submitted. 
sub add_post {
    my $self = shift;
  
    my $project_id = $self->param( 'proj' );
    my $cd = $self->param( 'cd' );

    # Check that the connected user has the access rights for this
    unless ( $self->users->has_user_project($self->session->{'session_user'}, $project_id) || 
             $self->users->is_user_authenticated($self->session->{'session_user'}, '/admin/projects' ) ) {
        $self->flash( msg => 'You must have rights on project $project_id to access this area.' );
        $self->redirect_to( '/login' );
    }

    my $plugin = $self->al_plugins->get_plugin($cd);
    my $conf = $plugin->get_conf();

    my %args;
    foreach my $arg (@{$conf->{'data'}}) {
        print "Adding $arg->{'id'} with value " . $self->param( $arg->{'id'} ) . ".\n";
        $args{ $arg->{'id'} } = $self->param( $arg->{'id'} );
    }

    # Automatically add author and id to args.
    $args{'id'} = time();
    $args{'author'} = $self->session->{'session_user'};

    my $metrics = $self->al_plugins->get_plugin($cd)->retrieve_data($project_id, \%args);
    if (not defined($metrics)) {
            $self->app->log->warn( "[Controller::CustomData] add_post No metric "
                                   . "returned from custom data specific module." );
            # Render template 
            $self->flash( msg => 'No metric returned from custom data plugin.' );
            $self->redirect_to( "/admin/project/$project_id" );   
    }


    # Render template 
    $self->redirect_to( "/admin/project/$project_id" );   
}


# Displays the form to add an entry for the specific manual data type.
sub edit {
    my $self = shift;
  
    my $project_id = $self->param( 'proj' );
    my $cd = $self->param( 'cd' );    
    my $id = $self->param( 'id' );    
  
    # Check that the connected user has the access rights for this
    unless ( $self->users->has_user_project($self->session->{'session_user'}, $project_id) || 
             $self->users->is_user_authenticated($self->session->{'session_user'}, '/admin/projects' ) ) {
        $self->flash( msg => 'You must have rights on project $project_id to access this area.' );
        $self->redirect_to( '/login' );
    }

    my $plugin = $self->al_plugins->get_plugin($cd);
    my $conf = $plugin->get_conf();
    my $values = $self->app->projects->get_project_cd_content($project_id, $cd);
    my $value;
    foreach my $entry (@{$values}) {
        print "Comparing $entry->{'id'} with $id.\n";
        if ( $entry->{'id'} =~ m!^${id}$! ) { $value = $entry; last }
    }
    print Dumper($value);

    # Prepare data for template.
    $self->stash(
        project_id => $project_id,
        conf => $conf,
        values => $value,
        );    
    
    # Render template for projects admin section
    $self->render( template => 'alambic/plugins/add_customdata' );
}



1;
