package Alambic::Controller::Projects;

use Mojo::Base 'Mojolicious::Controller';

use Data::Dumper;


# This action will render a template
sub display {
    my $self = shift;

    $self->param( 'id' ) =~ m!^(.*?)(_(\w+))?(.html)?$!;

    my $project_id = $1;
    my $page_id = $3 || "";

    $self->app->log->info( "[Controller::Projects] Project [$project_id] [$page_id]." );

    if ($page_id =~ m!^qm$!) {

        # Prepare data for template.
        $self->stash(
            project_id => $project_id,
            );    
        
        # Render template "alambic/dashboard_qm.html.ep"
        $self->render(template => 'alambic/dashboard_qm');   

    } elsif ($page_id =~ m!^attrs$!) {
        
        my %attributes = $self->models->get_attributes();

        # Prepare data for template.
        $self->stash(
            attributes => \%attributes,
            project_id => $project_id,
            project_attrs => $self->projects->get_project_attrs($project_id),
            project_attrs_conf => $self->projects->get_project_attrs_conf($project_id),
            );    
        
        # Render template "alambic/dashboard_qm.html.ep"
        $self->render(template => 'alambic/dashboard_attrs');
        
    } elsif ($page_id =~ m!^questions$!) {
        
        my %questions = $self->models->get_questions();

        # Prepare data for template.
        $self->stash(
            questions => \%questions,
            project_id => $project_id,
            project_questions => $self->projects->get_project_questions($project_id),
            project_questions_conf => $self->projects->get_project_questions_conf($project_id),
            );    
        
        # Render template "alambic/dashboard_questions.html.ep"
        $self->render(template => 'alambic/dashboard_questions');
        
    } elsif ($page_id =~ m!^metrics$!) {
        
        my %metrics = $self->models->get_metrics();

        # Prepare data for template.
        $self->stash(
            metrics => \%metrics,
            project_id => $project_id,
            project_metrics => $self->projects->get_project_metrics($project_id),
            project_inds => $self->projects->get_project_indicators($project_id),
            );    
        
        # Render template "alambic/dashboard_metrics.html.ep"
        $self->render(template => 'alambic/dashboard_metrics');
        
    } elsif ($page_id =~ m!^practices$!) {
        
        my %rules = $self->models->get_rules();

        # Prepare data for template.
        $self->stash(
            rules => \%rules,
            project_id => $project_id,
            project_violations => $self->projects->get_project_violations($project_id),
            );    
        
        # Render template "alambic/dashboard_practices.html.ep"
        $self->render(template => 'alambic/dashboard_practices');
        
    } else {

        # Prepare data for template.
        $self->stash(
            project_id => $project_id,
            project_attrs => $self->projects->get_project_attrs($project_id),
            project_attrs_conf => $self->projects->get_project_attrs_conf($project_id),
            project_pmi => $self->projects->get_project_pmi($project_id),
            project_comments => $self->projects->get_project_comments($project_id),
            );    
        
        # Render template "alambic/dashboard.html.ep"
        $self->render(template => 'alambic/dashboard');

    }

}

1;
