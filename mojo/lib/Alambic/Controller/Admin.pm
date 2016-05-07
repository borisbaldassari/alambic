package Alambic::Controller::Admin;
use Mojo::Base 'Mojolicious::Controller';

use Data::Dumper;
use File::stat;
use Time::localtime;

# Main screen for Alambic admin.
sub summary {
    my $self = shift;
    
    $self->render( template => 'alambic/admin/summary' );
}


# Projects screen for Alambic admin.
sub projects {
    my $self = shift;
    
    $self->render( template => 'alambic/admin/projects' );
}


# Display project screen for Alambic admin.
sub projects_show {
    my $self = shift;
    my $project_id = $self->param( 'pid' );

    # Get list of files in input and data directories.
    my @files_input = <projects/${project_id}/input/*.*>;
    my @files_output = <projects/${project_id}/output/*.*>;
    my %files_time;

    # Retrieve last modification time on input files.
    foreach my $file (@files_input, @files_output) { 
        $files_time{$file} = ctime( stat($file)->mtime );
    }

    # Prepare data for template.
    $self->stash(
        project_id => $project_id,
        files_input => \@files_input,
        files_output => \@files_output,
        files_time =>\%files_time,
        );
    
    $self->render( template => 'alambic/admin/project' );
}


# New project screen for Alambic admin.
sub projects_new {
    my $self = shift;

    $self->stash(
        project_id => '',
        project_name => '',
	project_active => '',
        );
    
    $self->render( template => 'alambic/admin/project_set' );
}


# New project screen for Alambic admin.
sub projects_new_post {
    my $self = shift;
    
    my $project_id = $self->param( 'id' );
    my $project_name = $self->param( 'name' );
    my $project_active = $self->param( 'is_active' );
    
    my $project = $self->app->al->create_project( $project_id, $project_name, '', $project_active );

    my $msg = "Project '$project_name' ($project_id) has been created.";
    
    $self->flash( msg => $msg );
    $self->redirect_to( '/admin/projects' );
}


# Run project screen for Alambic admin.
sub projects_run {
    my $self = shift;
    my $project_id = $self->param( 'pid' );

    my $project = $self->app->al->run_project( $project_id );

    my $msg = "Project has been run.";
    
    $self->flash( msg => $msg );
    $self->redirect_to( '/admin/projects/' . $project_id );
}


# Delete project screen for Alambic admin.
sub projects_del {
    my $self = shift;
    my $project_id = $self->param( 'pid' );

    # TODO DEL PROJECT

    my $msg = "Project has been deleted.";
    
    $self->flash( msg => $msg );
    $self->redirect_to( '/admin/projects/' . $project_id );
}


# Edit project screen for Alambic admin.
sub projects_edit {
    my $self = shift;
    my $project_id = $self->param( 'pid' );
    
    # Render template for main admin section
    $self->render( template => 'alambic/admin/projects_edit' );
}



1;
