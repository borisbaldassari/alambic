package Alambic::Controller::Admin;

use Mojo::Base 'Mojolicious::Controller';

use Data::Dumper;
use File::stat;
use Time::localtime;

# This action will render a template
sub welcome {
    my $self = shift;
    
    # Render template for main admin section
    $self->render( template => 'alambic/admin/summary' );
}


sub read_files() {
    my $self = shift;
    
    # Check that the connected user has the access rights for this
    unless ( $self->app->users->is_user_authenticated( $self->session->{'session_user'}, '/admin/projects' ) ) {
        $self->flash( msg => 'You must be authentified to read configuration files.' );
        $self->redirect_to( '/login' );
    }

    my $files = $self->param( 'files' );
    my $msg;

    if ($files =~ m!models!) {
        $self->models->read_all_files();
        $msg = "All model files reread.";
    } elsif ($files =~ m!projects!) {
        $self->app->projects->read_all_files();
        $msg = "All project files reread.";
    } else {
        $msg = "Could not understand command. Files not read.";
    }

    $self->render( template => 'alambic/admin/summary', msg => $msg );
}


sub del_input_file() {
    my $self = shift;
    
    my $project_id = $self->param( 'project' );
    my $file = $self->param( 'file' );

    # Check that the connected user has the access rights for this
    unless ( $self->users->has_user_project($self->session->{'session_user'}, $project_id) || 
             $self->app->users->is_user_authenticated( $self->session->{'session_user'}, '/admin/projects' ) ) {
        $self->flash( msg => 'You must be authenticated to access project management.' );
        $self->redirect_to( '/login' );
    }

    my $ret = unlink($self->config->{'dir_input'} . '/' . $project_id . '/' . $file);
    my $msg;
    if ($ret == 1) {
        $msg = "Deleted input file [$file].";
    } else {
        $msg = "ERROR: could not delete input file.";
    }

    $self->flash( msg => $msg );
    $self->redirect_to( '/admin/project/' . $project_id );
}


sub del_data_file() {
    my $self = shift;
    
    my $project_id = $self->param( 'project' );
    my $file = $self->param( 'file' );

    # Check that the connected user has the access rights for this
    unless ( $self->users->has_user_project($self->session->{'session_user'}, $project_id) || 
             $self->app->users->is_user_authenticated( $self->session->{'session_user'}, '/admin/projects' ) ) {
        $self->flash( msg => 'You must be authenticated to access project management.' );
        $self->redirect_to( '/login' );
    }

    my $ret = unlink($self->config->{'dir_data'} . '/' . $project_id . '/' . $file);
    my $msg;
    if ($ret == 1) {
        $msg = "Deleted data file [$file].";
    } else {
        $msg = "ERROR: could not delete data file.";
    }

    $self->flash( msg => $msg );
    $self->redirect_to( '/admin/project/' . $project_id );
}


sub projects_main {
    my $self = shift;
    
    # Check that the connected user has the access rights for this
    unless ( $self->app->users->is_user_authenticated( $self->session->{'session_user'}, '/admin/projects' ) ) {
        $self->flash( msg => 'You must be authenticated to access project management.' );
        $self->redirect_to( '/login' );
    }
             
    my @list_projects = $self->app->projects->list_projects();
    my %full_projects = $self->app->projects->get_all_projects();

    # Prepare data for template.
    $self->stash(
        list_projects => \@list_projects,
        full_projects => \%full_projects,
        );    
    
    # Render template for projects admin section
    $self->render( template => 'alambic/admin/projects' );
}


#
# Displays a list of plugins detected with information about them.
#
sub plugins {
    my $self = shift;

    # Check that the connected user has the access rights for this
    if ( not $self->users->is_user_authenticated($self->session->{session_user}, '/admin/plugins' ) ) {
        $self->redirect_to( '/login' );
    }

    # Render template 
    $self->render( template => 'alambic/admin/plugins' );   

}


#
# Manage information about the Alambic git repository.
#
sub repo {
    my $self = shift;

    # Check that the connected user has the access rights for this
    if ( not $self->users->is_user_authenticated($self->session->{session_user}, '/admin/repo' ) ) {
        $self->redirect_to( '/login' );
    }

    # Render template "alambic/admin/repo.html.ep"
    $self->render( template => 'alambic/admin/repo' );
}


sub project_add {
    my $self = shift;
    
    my $from = $self->param( 'from' );
    
    # Check that the connected user has the access rights for this
    unless ( $self->app->users->is_user_authenticated( $self->session->{'session_user'}, '/admin/projects' ) ) {
        $self->flash( msg => 'You must be authenticated to add a project.' );
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
    my $project_active = $self->param( 'is_active' );

    # Check that the connected user has the access rights for this
    unless ( $self->app->users->is_user_authenticated( $self->session->{'session_user'}, '/admin/projects' ) ) {
        $self->flash( msg => 'You must be authenticated to add a project.' );
        $self->redirect_to( '/login' );
    }

    # If fields are not filled, fail.
    if (not defined($project_id) or not defined($project_name)
        or $project_id =~ /^\s$/ or $project_name =~ /^\s$/) {
        $self->flash( msg => "Failed to add project [$project_id]." );
        $self->redirect_to( '/admin/projects' );
    }

    $self->app->projects->add_project($project_id, $project_name, $project_active);

    $self->flash( msg => "Project [$project_id] saved." );
    $self->redirect_to( "/admin/project/$project_id" );
}

sub project_del {
    my $self = shift;

    my $project_id = $self->param( 'id' );
    
    # Check that the connected user has the access rights for this
    unless ( $self->app->users->is_user_authenticated( $self->session->{'session_user'}, '/admin/projects' ) ) {
        $self->flash( msg => 'You must be authenticated to delete a project.' );
        $self->redirect_to( '/login' );
    }

    $self->app->projects->del_project($project_id);

    $self->redirect_to( '/admin/projects' );
}

sub projects_id($) {
    my $self = shift;

    my $project_id = $self->param( 'id' );

    # Check that the connected user has the access rights for this
    unless ( $self->users->has_user_project($self->session->{'session_user'}, $project_id) || 
             $self->app->users->is_user_authenticated( $self->session->{'session_user'}, '/admin/projects' ) ) {
        $self->flash( msg => 'You must be authenticated to access project management.' );
        $self->redirect_to( '/login' );
    }
    
    # Get list of files in input and data directories.
    my $dir_projects = $self->config->{'dir_data'};
    my @files_data = <${dir_projects}/${project_id}/*.*>;
    my $dir_input = $self->config->{'dir_input'};
    my @files_input = <${dir_input}/${project_id}/*.*>;
    my %projects = $self->{app}->projects->get_all_projects();
    my %files_time;

    # Retrieve last modification time on input files.
    foreach my $file (@files_input, @files_data) { 
        $files_time{$file} = ctime( stat($file)->mtime );
    }

    # Prepare data for template.
    $self->stash(
        project_id => $project_id,
        projects => \%projects,
        files_data => \@files_data,
        files_input => \@files_input,
        files_time =>\%files_time,
        );    
    
    # Render template for projects admin section
    $self->render( template => 'alambic/admin/project' );
}

sub users_main {
    my $self = shift;
    
    # Check that the connected user has the access rights for this
    unless ( $self->app->users->is_user_authenticated( $self->session->{'session_user'}, '/admin/users' ) ) {
        $self->flash( msg => 'You must be authenticated to access users management.' );
        $self->redirect_to( '/login' );
    }
    
    $self->render( template => 'alambic/admin/users' );
}

sub project_retrieve_data {
    my $self = shift;
    
    my @log;

    my $project_id = $self->param( 'id' );
    $self->app->log->info("[Controller::Admin] project_retrieve_data $project_id.");
    
    # Check authenticated user.
    unless ( $self->users->has_user_project($self->session->{'session_user'}, $project_id) || 
             $self->users->is_user_authenticated($self->session->{'session_user'}, '/admin/projects' ) ) {
        $self->flash( msg => "You must have rights on project $project_id to access this area." );
        $self->redirect_to( '/login' );
    }

    push( @log, @{$self->app->projects->retrieve_project_data($project_id)} );
    push( @log, "Data for project $project_id has been retrieved." );

    my $log_str = join( '<br />', @log );

    $self->flash( msg => $log_str );
    $self->redirect_to( "/admin/project/$project_id" );

}

sub project_analyse {
    my $self = shift;

    my $project_id = $self->param( 'id' );
    $self->app->log->info("[Controller::Admin] project_analyse $project_id.");
    
    my @log;

    # Check authenticated user.
    unless ( $self->users->has_user_project($self->session->{'session_user'}, $project_id) || 
             $self->users->is_user_authenticated($self->session->{'session_user'}, '/admin/projects' ) ) {
        $self->flash( msg => "You must have rights on project $project_id to access this area." );
        $self->redirect_to( '/login' );
    }
    push( @log, @{$self->app->projects->analyse_project($project_id)} );
    push( @log, "Data for project $project_id has been analysed." );

    my $log_str = join( '<br />', @log );

    $self->flash( msg => $log_str );
    $self->redirect_to( "/admin/project/$project_id" );
}

1;
