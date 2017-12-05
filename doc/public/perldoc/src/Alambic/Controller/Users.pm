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

package Alambic::Controller::Users;
use Mojo::Base 'Mojolicious::Controller';

use Data::Dumper;

# Displays profile information about a single user.
sub profile {
  my $self = shift;

  my $user_id = $self->param('id');

  # Prepare data for template and render.
  $self->stash(user_id => $user_id);
  $self->render(template => 'alambic/user/profile');

}

# Displays projects information about a single user.
sub projects {
  my $self = shift;

  my $user_id    = $self->param('id');
  my $project_id = $self->param('project');

  # Prepare data for template and render.
  $self->stash(user_id => $user_id, project_id => $project_id);
  $self->render(template => 'alambic/user/project');

}


1;


=encoding utf8

=head1 NAME

B<Alambic::Controller::Users> - Routing logic for Alambic users profiles.

=head1 SYNOPSIS

Routing logic for all user profile-related actions in the Alambic web ui. This is automatically called by the Mojolicious routing framework.

=head1 METHODS

=head2 C<profile()> 

Display profile information for a user.

=head2 C<projects()> 

Display the list of projects the user contribted to.

=head1 SEE ALSO

L<Alambic>, L<http://alambic.io>, L<https://bitbucket.org/BorisBaldassari/alambic>, L<Mojolicious>.

=cut
