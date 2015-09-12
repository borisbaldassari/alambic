package Alambic::Controller::Admin;

use Mojo::Base 'Mojolicious::Controller';

use Alambic::Model::Projects;

use Data::Dumper;


# This action will render a template
sub welcome {
    my $self = shift;
    
    my $in_doc = $self->param( 'id' );
    
    if ($in_doc =~ m!^users$!) {

	# Render template for quality_model
	$self->render( template => 'alambic/documentation/quality_model' );

    } elsif ($in_doc =~ m!^models$!) {

	# Render template for models
	$self->render( template => 'alambic/admin/models' );

    } else {

	print "In admin: displaying main title is " . $self->conf_title . ".\n";

        my %attrs_info = $self->models->get_attributes_info();
        my %metrics_info = $self->models->get_metrics_info();
        my %questions_info = $self->models->get_questions_info();
        my %model_info = $self->models->get_model_info();

        my %models = (
            'attrs' => \%attrs_info,
            'metrics' => \%metrics_info,
            'model' => \%model_info,
            'questions' => \%questions_info,
        );
        my %projects = $self->projects->get_all_projects();
        my %conf = (
            "title" => $self->conf_title || "No title defined",
            "desc" => $self->conf_desc || "No description defined",
            "dir_conf" => $self->conf_dir_conf || "No dir_conf defined",
            "dir_data" => $self->conf_dir_data || "No dir_data defined",
            "dir_projects" => $self->conf_dir_projects || "No dir_projects defined",
        );

	# Prepare data for template.
	$self->stash(
            conf => \%conf,
	    models => \%models,
	    projects => \%projects,
	    );    

	# Render template for main documentation
	$self->render( template => 'alambic/admin/welcome' );
    }
}

1;
