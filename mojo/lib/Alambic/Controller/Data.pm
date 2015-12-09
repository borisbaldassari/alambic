package Alambic::Controller::Data;

use Mojo::Base 'Mojolicious::Controller';
use Data::Dumper;

# This action will render a template
sub download {
    my $self = shift;

    my $in_doc = $self->param( 'id' );
    
    $self->app->log->info( "[Controller::Data] request with [$in_doc]." );

    if ($in_doc =~ m!^quality_model_full.json$!) {

#        $self->res->headers->content_type('ascii/json');
#        push @{$static->paths}, $self->config->{'dir_models'};
        $self->reply->static('../models/quality_model_full.json');
#        $self->reply->static( $self->config->{'dir_models'} . '/quality_model_full.json');

    } elsif ($in_doc =~ m!^model_attributes.json$!) {

        my %attributes = %{$self->models->get_attributes_full()};
        $self->render( json => \%attributes );

    } elsif ($in_doc =~ m!^model_metrics.json$!) {

        my %metrics = %{$self->models->get_metrics_full()};
        $self->render( json => \%metrics);

    } elsif ($in_doc =~ m!^model_questions.json$!) {

        my %questions = %{$self->models->get_questions_full()};
        $self->render( json => \%questions );

    } elsif ($in_doc =~ m!^(\S+)_qm.json$!) {

        # numbers for projects quality model
        my $project_id = $1;
        my %project_values = $self->app->projects->get_project_all_values($project_id);
        $self->render(json => \%project_values);

    } elsif ($in_doc =~ m!^(\S+)_attributes.json$!) {

        my $project_id = $1;
        my %project_values = $self->app->projects->get_project_attrs($project_id);
        $self->render(json => \%project_values);

    } elsif ($in_doc =~ m!^(\S+)_metrics.json$!) {

        my $project_id = $1;
        my %project_values = $self->app->projects->get_project_metrics($project_id);
        $self->render(json => \%project_values);

    } elsif ($in_doc =~ m!^(\S+)_questions.json$!) {

        my $project_id = $1;
        my %project_values = $self->app->projects->get_project_questions($project_id);
        $self->render(json => \%project_values);

    } elsif ($in_doc =~ m!^(\S+)_violations.json$!) {

        my $project_id = $1;
        my %project_values = $self->app->projects->get_project_violations($project_id);
        $self->render(json => \%project_values);

    } else {

        $self->app->log->info( "[Controller::Data] [ERR] Data not found! " . $self->tx->req->url . "." );
	$self->reply->not_found;

    }
}

1;
