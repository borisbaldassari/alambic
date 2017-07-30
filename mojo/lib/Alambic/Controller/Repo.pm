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

package Alambic::Controller::Repo;
use Mojo::Base 'Mojolicious::Controller';

use Alambic::Model::RepoFS;

use Data::Dumper;

# Main screen for Alambic repo admin.
sub summary {
  my $self = shift;

  # Get list of backup files.
  my @files_backup = <backups/*.*>;

  $self->stash(files_backup => \@files_backup,);
  $self->render(template => 'alambic/admin/repo');
}


# Initalisation of DB for Alambic admin.
sub init {
  my $self = shift;

  $self->app->al->init();

  my $msg = "Database has been initialised.";

  $self->flash(msg => $msg);
  $self->redirect_to('/admin/summary');
}


# Backup DB for Alambic admin.
sub backup {
  my $self = shift;

  my $sql      = $self->app->al->backup();
  my $repofs   = Alambic::Model::RepoFS->new();
  my $file_sql = $repofs->write_backup($sql);

  my $msg = "Database has been backed up in [$file_sql].";

  $self->flash(msg => $msg);
  $self->redirect_to('/admin/repo');
}


# Download SQL backup file.
sub dl {
  my $self = shift;

  my $file_sql = $self->param('file');

  # Reply with the sql backup file.
  $self->reply->static('../../../../backups/' . $file_sql);
}


# Restore DB for Alambic admin.
sub restore {
  my $self = shift;

  my $file_sql = $self->param('file');

  my $repofs = Alambic::Model::RepoFS->new();
  my $sql    = $repofs->read_backup($file_sql);

  if (length($sql) < 10) {
    $self->flash(
      msg => "Could not find SQL file. Database has NOT been restored.");
    $self->redirect_to('/admin/summary');
  }

  $self->app->al->restore($sql);

  my $msg = "Database has been restored from [$file_sql].";

  $self->flash(msg => $msg);
  $self->redirect_to('/admin/repo');
}


# Delete a backup file on the server
sub delete() {
  my $self = shift;

  my $file = $self->param('file');

  my $ret = unlink('backups/' . $file);
  my $msg;
  if ($ret == 1) {
    $msg = "Deleted backup file [$file].";
  }
  else {
    $msg = "ERROR: could not delete backup file.";
  }

  $self->flash(msg => $msg);
  $self->redirect_to('/admin/repo/');
}


1;



=encoding utf8

=head1 NAME

B<Alambic::Controller::Repo> - Routing logic for Alambic administration UI.

=head1 SYNOPSIS

Routing logic for all repository-related administration actions in the Alambic web ui. This is automatically called by the Mojolicious framework.

=head1 METHODS

=head2 C<summary()> 

Main screen for Alambic repo admin.

=head2 C<init()> 

Initalisation of DB for Alambic admin.

=head2 C<backup()> 

Backup database for Alambic instance.

=head2 C<dl()> 

Download SQL backup file.

=head2 C<restore()> 

Restore DB for Alambic admin.

=head2 C<delete()> 

Delete a backup file on the server.

=head1 SEE ALSO

L<Alambic>, L<http://alambic.io>, L<https://bitbucket.org/BorisBaldassari/alambic>, L<Mojolicious>.

=cut
