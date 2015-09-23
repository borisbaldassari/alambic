package Alambic::Controller::Admin;

use Mojo::Base 'Mojolicious::Controller';

use Data::Dumper;


# This action will render a template
sub welcome {
    my $self = shift;
    
    # Render template for main admin section
    $self->render( template => 'alambic/admin/summary' );
}


sub read_files() {
    my $self = shift;
    
    # Check that the connected user has the access rights for this
    unless ( $self->{app}->users->is_user_authenticated( $self->session->{'session_user'}, '/admin/read_files' ) ) {
        $self->flash( msg => 'You must be authentified to read configuration files.' );
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

    $self->render( template => 'alambic/admin/summary', msg => $msg );
}


sub projects_main {
    my $self = shift;
    
    # Check that the connected user has the access rights for this
    unless ( $self->{app}->users->is_user_authenticated( $self->session->{'session_user'}, '/admin/projects' ) ) {
        $self->flash( msg => 'You must be authentified to access project management.' );
        $self->redirect_to( '/login' );
    }
             
    my @list_projects = $self->projects->list_projects();
    my %full_projects = $self->projects->get_all_projects();

    # Prepare data for template.
    $self->stash(
        list_projects => \@list_projects,
        full_projects => \%full_projects,
        );    
    
    # Render template for projects admin section
    $self->render( template => 'alambic/admin/projects' );
}

sub project_add {
    my $self = shift;
    
    my $from = $self->param( 'from' );
    
    # Check that the connected user has the access rights for this
    unless ( $self->{app}->users->is_user_authenticated( $self->session->{'session_user'}, '/admin/projects' ) ) {
        $self->flash( msg => 'You must be authentified to add a project.' );
        $self->redirect_to( '/login' );
    }

    # Prepare data for template.
    $self->stash(
        from => $from,
        );    

    $self->render( template => 'alambic/admin/project_add' );
}

sub project_add_post {
    my $self = shift;
    
    my $project_id = $self->param( 'id' );
    my $project_name = $self->param( 'name' );
    my $from = $self->param( 'from' );
    
    # Check that the connected user has the access rights for this
    unless ( $self->{app}->users->is_user_authenticated( $self->session->{'session_user'}, '/admin/projects' ) ) {
        $self->flash( msg => 'You must be authentified to add a project.' );
        $self->redirect_to( '/login' );
    }

    if ( defined($from) && $from =~ m!^pmi$! ) {
        $self->projects->add_project_from_pmi($project_id);
    } else {
        $self->projects->add_project($project_id, $project_name);
    }

    $self->redirect_to( '/admin/projects' );
}

sub project_del {
    my $self = shift;

    my $project_id = $self->param( 'id' );
    
    # Check that the connected user has the access rights for this
    unless ( $self->{app}->users->is_user_authenticated( $self->session->{'session_user'}, '/admin/projects' ) ) {
        $self->flash( msg => 'You must be authentified to delete a project.' );
        $self->redirect_to( '/login' );
    }

    $self->projects->del_project($project_id);

    $self->redirect_to( '/admin/projects' );
}

sub projects_id($) {
    my $self = shift;

    my $project_id = $self->param( 'id' );
    
    # Check that the connected user has the access rights for this
    unless ( $self->{app}->users->is_user_authenticated( $self->session->{'session_user'}, '/admin/projects' ) ) {
        $self->flash( msg => 'You must be authentified to access project management.' );
        $self->redirect_to( '/login' );
    }
    
    # Get list of files in input and data directories.
    my $dir_projects = $self->config->{'dir_data'};
    my @files_data = <${dir_projects}/${project_id}/*.json>;
    my $dir_input = $self->config->{'dir_input'};
    my @files_input = <${dir_input}/${project_id}/*.json>;
    my %projects = $self->projects->get_all_projects();
             
    # Prepare data for template.
    $self->stash(
        project_id => $project_id,
        projects => \%projects,
        files_data => \@files_data,
        files_input => \@files_input,
        );    
    
    # Render template for projects admin section
    $self->render( template => 'alambic/admin/project' );
}

sub users_main {
    my $self = shift;
    
    # Check that the connected user has the access rights for this
    unless ( $self->{app}->users->is_user_authenticated( $self->session->{'session_user'}, '/admin/users' ) ) {
        $self->flash( msg => 'You must be authentified to access users management.' );
        $self->redirect_to( '/login' );
    }
    
    $self->render( template => 'alambic/admin/users' );
}

sub project_retrieve_data {
    my $self = shift;

    my $project_id = $self->param( 'id' );
    print "[Controller::Admin] project_retrieve_data $project_id.\n";
    
    # Check authentified user.
    unless ( $self->users->has_user_project($self->session->{'session_user'}, $project_id) || 
             $self->users->is_user_authenticated($self->session->{'session_user'}, '/admin/projects' ) ) {
        $self->flash( msg => 'You must have rights on project $project_id to access this area.' );
        $self->redirect_to( '/login' );
    }

    $self->app->projects->retrieve_project_data($project_id);

    $self->flash( msg => "Data for project $project_id has been retrieved." );
    $self->redirect_to( "/admin/project/$project_id" );

}

sub project_analyse {
    my $self = shift;

    my $project_id = $self->param( 'id' );
    
    # Check authentified user.
    unless ( $self->users->has_user_project($self->session->{'session_user'}, $project_id) || 
             $self->users->is_user_authenticated($self->session->{'session_user'}, '/admin/projects' ) ) {
        $self->flash( msg => "You must have rights on project $project_id to access this area." );
        $self->redirect_to( '/login' );
    }

    $self->app->projects->analyse_project($project_id);
    $self->flash( msg => "Data for project $project_id has been analysed." );

    $self->redirect_to( "/admin/project/$project_id" );
}

1;
