package Alambic::Controller::Comments;

use Mojo::Base 'Mojolicious::Controller';

use Data::Dumper;

sub welcome {
    my $self = shift;
    
    # 'project' is the specific project we want the comments for.
    my $project_id = $self->param( 'project' ) || '';
    # 'action' is either a (add), s (show), e (edit) or d (delete).
    my $project_action = $self->param( 'act' ) || 's';
    my $action_id = $self->param( 'com' ) || 0;

    # For each project, get their comments for the summary.
    my @projects = $self->projects->list_projects();
    my %projects_comments;
    foreach my $project (@projects) {
        my $comments;
        if ( defined($self->projects->get_project_comments($project)) ) {
            $comments = $self->projects->get_project_comments($project);
        } else {
            $comments = [];
        }
        $projects_comments{$project} = $comments;
    }
    my $action_comment;
    if ($action_id != 0) {
        foreach my $comment (@{$projects_comments{$project_id}}) {
            if ($comment->{'id'} eq $action_id) {
                $action_comment = $comment;
                last;
            }
        }
    }

    # Prepare data for template.
    $self->stash(
        project_id => $project_id,
        action => $project_action,
        action_comment => $action_comment,
        comments => \%projects_comments,
        );    
    
    # Render template for projects admin section
    $self->render( template => 'alambic/admin/comments' );
}

sub add_post {
    my $self = shift;

    my $project_id = $self->param( 'project' );
    my $date = localtime();

    my $comment = {
        "id" => time(),
#        "user" => $self->session('user'),
        "author" => $self->param('author'),
        "date" => $date,
        "mnemo" => $self->param('mnemo'),
        "text" => $self->param('text'),
     };
    $self->projects->add_project_comment($project_id, $comment);

    $self->redirect_to( "/admin/comments/$project_id" );
}

sub edit_post($) {
    my $self = shift;

    my $project_id = $self->param( 'project' );
    my $date = localtime();

    my $comment = {
        "id" => $self->param('com'),
#        "user" => $self->session('user'),
        "author" => $self->param('author'),
        "date" => $date,
        "mnemo" => $self->param('mnemo'),
        "text" => $self->param('text'),
     };
    $self->projects->edit_project_comment($project_id, $comment);

    $self->redirect_to( "/admin/comments/$project_id" );
}

sub delete_post {
    my $self = shift;

    my $project_id = $self->param( 'project' );

    $self->projects->delete_project_comment($project_id, $self->param('com'));

    $self->redirect_to( "/admin/comments/$project_id" );
}

1;
