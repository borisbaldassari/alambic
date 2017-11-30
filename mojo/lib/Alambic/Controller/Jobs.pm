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

package Alambic::Controller::Jobs;
use Mojo::Base 'Mojolicious::Controller';

use Data::Dumper;

# Displays a list of jobs with information and actions
sub summary {
  my $self = shift;

  $self->render(template => 'alambic/admin/jobs');

}

# Displays information about a single job.
sub display {
  my $self = shift;

  my $job_id = $self->param('id');

  # Prepare data for template and render.
  $self->stash(job_id => $job_id);
  $self->render(template => 'alambic/admin/job');

}

# Recycles a job (re-start it).
sub redo {
  my $self   = shift;
  my $job_id = $self->param('id');

  # Enqueue job
  my $job_info = shift @{$self->minion->backend->list_jobs(0,1, { ids => [$job_id] })->{'jobs'}};
  my $job      = $self->minion->enqueue(
      $job_info->{'task'} => $job_info->{'args'} => {delay => 0});
  
  $self->flash(msg => "Job has been relaunched with ID [$job].");
  $self->redirect_to("/admin/jobs/$job");

}

# Deletes a job
sub delete {
  my $self   = shift;
  my $job_id = $self->param('id');

  $self->minion->backend->remove_job($job_id);

  $self->flash(msg => "Job [$job_id] has been deleted.");
  $self->redirect_to('/admin/jobs');

}


1;


=encoding utf8

=head1 NAME

B<Alambic::Controller::Jobs> - Routing logic for Alambic jobs management.

=head1 SYNOPSIS

Routing logic for all jobs-related actions in the Alambic web ui. This is automatically called by the Mojolicious framework.

=head1 METHODS

=head2 C<summary()>

Displays a list of jobs with information and actions.

=head2 C<display()>

Display information about a single job.

=head2 C<redo()>

Re-cycle a job (re-start it).

=head2 C<delete()>

Delete a job.

=head1 SEE ALSO

L<Alambic>, L<http://alambic.io>, L<https://bitbucket.org/BorisBaldassari/alambic>, L<Mojolicious>.

=cut
