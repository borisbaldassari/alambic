package Alambic::Controller::Plugins;

use Mojo::Base 'Mojolicious::Controller';

use Data::Dumper;


sub welcome {
    my $self = shift;

    # Check that the connected user has the access rights for this
    if ( not $self->users->is_user_authenticated($self->session->{session_user}, '/admin/ds' ) ) {
        $self->redirect_to( '/login' );
    }

    print "[Controller::Plugins] welcome.\n";

    # Render template 
    $self->render( template => 'alambic/plugins/manage' );   

}

sub add_project {
    my $self = shift;

    my $project = $self->param( 'id' );
    my $ds = $self->param( 'ds' );

    #$self->{app}->al_plugins->get_plugin($ds);
    # Add ds to Projects.pm
    # Write file to projects->project_conf.json

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

sub add_project_post {
    my $self = shift;

    my $project = $self->param( 'id' );
    my $ds = $self->param( 'ds' );

    print "[Controller::Plugins] add_project_post $project $ds.\n";

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

sub del_project {
    my $self = shift;

    my $project = $self->param( 'id' );
    my $ds = $self->param( 'ds' );

    print "[Controller::Plugins] del_project_post $project $ds.\n";

    $self->projects->delete_project_ds($project, $ds);
    
    # Render template 
    $self->redirect_to( "/admin/project/$project" );   
}


sub project_retrieve_data {
    my $self = shift;

    my $project_id = $self->param( 'id' );
    my $ds = $self->param( 'ds' );

    $self->al_plugins->get_plugin($ds)->retrieve_data($project_id);
    
    # Render template 
    $self->redirect_to( "/admin/project/$project_id" );   
}

sub project_compute_data {
    my $self = shift;

    my $project_id = $self->param( 'id' );
    my $ds = $self->param( 'ds' );

    $self->al_plugins->get_plugin($ds)->compute_data($project_id);
    
    # Render template 
    $self->redirect_to( "/admin/project/$project_id" );   
}


1;
