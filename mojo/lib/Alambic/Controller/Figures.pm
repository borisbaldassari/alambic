package Alambic::Controller::Figures;

use Mojo::Base 'Mojolicious::Controller';
use Data::Dumper;

# This action will render a template
sub plugins {
    my $self = shift;

    my $in_plugin = $self->param( 'plugin' );
    my $in_fig = $self->param( 'fig' );
    my $project_id = $self->param( 'project' );
    
    $self->app->log->info( "[Controller::Figures] request with [$in_plugin] [$in_fig]." );

    $self->reply->static('../data/' . $project_id . '/figures/' 
                      . $in_plugin . '/' . $in_fig);

}

1;
