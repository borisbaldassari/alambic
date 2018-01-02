#########################################################
#
# Copyright (c) 2015-2017 Castalia Solutions and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
#
# Contributors:
#   Boris Baldassari - Castalia Solutions
#
#########################################################

package Alambic::Controller::Documentation;
use Mojo::Base 'Mojolicious::Controller';

use Mojo::JSON qw( decode_json );
use Data::Dumper;

# Renders all documentation pages.
sub welcome {
  my $self = shift;

  # 'id' is the specific documentation page from url.
  my $in_doc = $self->param('id') || '';

  my $repodb = $self->app->al->get_repo_db();

  if ($in_doc =~ m!^quality_model(.html)?$!) {

    # Render template for quality_model
    $self->render(template => 'alambic/documentation/quality_model');

  }
  elsif ($in_doc =~ m!^plugins(.html)?$!) {

    # Render template for plugins
    $self->stash(type => $self->param('type'),);
    $self->render(template => 'alambic/documentation/plugins');

  }
  elsif ($in_doc =~ m!^data(.html)?$!) {

    $self->render(template => 'alambic/documentation/data');

  }
  elsif ($in_doc =~ m!^attributes(.html)?$!) {

    my $models     = $self->app->al->get_models();
    my $attributes = $models->get_attributes();

    # Render template for attributes
    $self->stash(attributes => $attributes, models => $models);
    $self->render(template => 'alambic/documentation/attributes');

  }
  elsif ($in_doc =~ m!^metrics(_(\w+))?(.html)?$!) {

    my $repo = $2 || "";

    my $models  = $self->app->al->get_models();
    my $metrics = $models->get_metrics();
    my $repos   = $models->get_metrics_repos();

    # Render template for metrics
    $self->stash(
      metrics => $metrics,
      models  => $models,
      repos   => $repos,
      repo    => $repo
    );
    $self->render(template => 'alambic/documentation/metrics');

  }
  elsif ($in_doc =~ m!^references(.html)?$!) {

    # Render template for references (bib)
    $self->render(template => 'alambic/documentation/references');

  }
  else {

    $self->render(template => 'alambic/documentation/main');

  }
}

1;


=encoding utf8

=head1 NAME

B<Alambic::Controller::Documentation> - Routing logic for the Alambic documentation pages.

=head1 SYNOPSIS

Routing logic for all online documentation-related actions in the Alambic web ui. This is automatically called by the Mojolicious framework.

=head1 METHODS

=head2 C<welcome()>

Main page for Alambic documentation.


=head1 SEE ALSO

L<Alambic>, L<http://alambic.io>, L<https://bitbucket.org/BorisBaldassari/alambic>, L<Mojolicious>.

=cut
