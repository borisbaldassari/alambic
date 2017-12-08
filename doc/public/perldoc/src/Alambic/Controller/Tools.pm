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

package Alambic::Controller::Tools;
use Mojo::Base 'Mojolicious::Controller';

use Data::Dumper;

# Displays a list of tools with information and actions
sub summary {
  my $self = shift;

  $self->render(template => 'alambic/admin/tools');

}

# Displays information about a single tool.
sub display {
  my $self = shift;

  my $tool_id = $self->param('id');

  # Prepare data for template and render.
  $self->stash(tool_id => $tool_id);
  $self->render(template => 'alambic/admin/tool');

}

1;

=encoding utf8

=head1 NAME

B<Alambic::Controller::Tools> - Routing logic for Alambic tools management UI.

=head1 SYNOPSIS

Routing logic for all tools-related administration actions in the Alambic web ui. This is automatically called by the Mojolicious routing framework.

=head1 METHODS

=head2 C<summary()> 

Main screen for Alambic Tools management.

=head2 C<display()> 

Display information about a specific tool.

=head1 SEE ALSO

L<Alambic>, L<http://alambic.io>, L<https://bitbucket.org/BorisBaldassari/alambic>, L<Mojolicious>.

=cut
