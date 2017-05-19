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
  my $job_info = $self->minion->backend->job_info($job_id);
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
