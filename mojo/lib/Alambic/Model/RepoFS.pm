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

package Alambic::Model::RepoFS;

use warnings;
use strict;

use File::Path qw( remove_tree );
use Mojo::Home;
use Mojo::JSON qw( decode_json encode_json );
use POSIX;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(
  write_input
  read_input
  write_output
  read_output
  write_plugin
  read_plugin
  write_models
  read_models
  write_users
  read_users
  delete_project
);

# Create a new RepoFS object.
sub new {
  my ($class, $args) = @_;

  return bless {}, $class;
}


# Write a file to the project input directory.
sub write_input($$$) {
  my ($self, $project_id, $file_name, $content) = @_;

  # Create projects input dir if it does not exist
  if (not -d 'projects/' . $project_id) {
    mkdir('projects/' . $project_id);
  }
  if (not -d 'projects/' . $project_id . '/input') {
    mkdir('projects/' . $project_id . '/input');
  }

  my $file_content_out
    = "projects/" . $project_id . "/input/" . $project_id . "_" . $file_name;
  open my $fh, ">", $file_content_out;
  print $fh $content;
  close $fh;
}


# Read a file from the project input directory.
sub read_input($$) {
  my ($self, $project_id, $file_name) = @_;

  my $content;
  my $file
    = "projects/" . $project_id . "/input/" . $project_id . "_" . $file_name;

  if (-e $file) {
    do {
      local $/;
      open my $fh, '<', $file;
      $content = <$fh>;
      close $fh;
    };
  }

  return $content;
}


# Write a file to the project output directory.
sub write_output($$$) {
  my ($self, $project_id, $file_name, $content) = @_;

  if (not defined($content)) { return; }

  # Create projects output dir if it does not exist
  if (not -d 'projects/' . $project_id) {
    mkdir('projects/' . $project_id);
  }
  if (not -d 'projects/' . $project_id . '/output') {
    mkdir('projects/' . $project_id . '/output');
  }

  my $file_content_out
    = "projects/" . $project_id . "/output/" . $project_id . "_" . $file_name;
  open my $fh, ">", $file_content_out;
  print $fh $content;
  close $fh;
}


# Write a file to the models directory.
sub read_output($$) {
  my ($self, $project_id, $file_name) = @_;

  my $content;
  my $file
    = "projects/" . $project_id . "/output/" . $project_id . "_" . $file_name;

  if (-e $file) {
    do {
      local $/;
      open my $fh, '<', $file;
      $content = <$fh>;
      close $fh;
    };
  }

  return $content;
}


# Write a file to the plugins directory.
sub write_plugin($$$) {
  my ($self, $plugin_id, $file_name, $content) = @_;

  my $dir_content_out  = "lib/Alambic/Plugins/" . $plugin_id;
  my $file_content_out = $dir_content_out . "/" . $file_name;

  # Create plugin dir if it does not exist
  if (not -d $dir_content_out) {
    mkdir($dir_content_out);
  }

  open my $fh, ">", $file_content_out;
  print $fh $content;
  close $fh;
}


# Read a file from the plugins directory.
sub read_plugin($$) {
  my ($self, $plugin_id, $file_name) = @_;

  my $content;

  my $file = "lib/Alambic/Plugins/" . $plugin_id . "/" . $file_name;
  if (-e $file) {
    do {
      local $/;
      open my $fh, '<', $file;
      $content = <$fh>;
      close $fh;
    };
  }

  return $content;
}

# Write a file to the backups directory.
sub write_backup($$$) {
  my ($self, $content) = @_;

  # Create backups dir if it does not exist
  if (not -d 'backups/') {
    mkdir('backups/');
  }

  my $file_name = strftime("backups/alambic_backup_%Y%m%d%H%M.sql", localtime);
  open my $fh, ">", $file_name;
  print $fh $content;
  close $fh;

  return $file_name;
}

# Read a file from the backups directory.
sub read_backup($$) {
  my ($self, $file_name) = @_;

  my $content;
  my $file = "backups/" . $file_name;

  if (-e $file) {
    do {
      local $/;
      open my $fh, '<', $file or return 0;
      $content = <$fh>;
      close $fh;
    };
  }

  return $content;
}


# Write a file to the models directory.
sub write_models($$$) {
  my ($self, $type, $file_name, $content) = @_;

  my $models = $self->home(Mojo::Home->new) . '/lib/Alambic/files/models';

  # Create models dir if it does not exist
  if (not -d $models) {
    mkdir($models);
  }

  my $path = $models . '/' . $type . '/' . $file_name;
  open my $fh, ">", $path;
  print $fh $content;
  close $fh;
}

# Read a file from the models directory.
sub read_models($$) {
  my ($self, $type, $file_name) = @_;

  my $content;
  my $models = Mojo::Home->new . '/lib/Alambic/files/models';
  my $file   = $models . '/' . $type . "/" . $file_name;

  if (-e $file) {
    do {
      local $/;
      open my $fh, '<', $file or return 0;
      $content = <$fh>;
      close $fh;
    };
  }

  return $content;
}


# Write user operations to the projects/<project_id>/users/ directory.
sub write_users($$$) {
  my ($self, $plugin_id, $project_id, $content) = @_;

  # Create users dir if it does not exist
  my $dir_path = 'projects/' . $project_id . '/users/';
  if (not -d $dir_path) {
    mkdir($dir_path);
  }

  my $path = $dir_path . $plugin_id . "_users.json";
  open my $fh, ">", $path;
  print $fh encode_json($content);
  close $fh;
}

# Read user operations from the projects/<project_id>/users/ directory.
sub read_users($$$) {
  my ($self, $project_id) = @_;

  my @files_users = <projects/${project_id}/users/*_users.json>;
  my %users;
  foreach my $file (@files_users) {
    if (-e $file && $file =~ m!.*/([^/]+)_users.json!) {
      my $plugin_id = $1;
      do {
        local $/;
        open my $fh, '<', $file or return 0;
        my $json = <$fh>;
        close $fh;
        my $content = decode_json($json);
        foreach my $u (keys %$content) {
          $users{$u}{$plugin_id} = $content->{$u};
        }
      };
    }
  }

  return \%users;
}

# Delete the complete hierarchy of files in projects/<project_id>.
sub delete_project($) {
  my ($self, $project_id) = @_;

  remove_tree("projects/${project_id}/");
}


1;


=encoding utf8

=head1 NAME

B<Alambic::Model::RepoFS> - Interface to all file-system-related actions and
information defined in Alambic.

=head1 SYNOPSIS

    my $repofs = Alambic::Model::RepoFS->new();
    
    $repofs->delete_project('modeling.sirius');

=head1 DESCRIPTION

B<Alambic::Model::RepoFS> provides autility methods for all operations 
related to file system: read and copy files, delete projects, etc.

=head1 METHODS

=head2 C<new()>

    my $repofs = Alambic::Model::RepoFS->new();

Create a new L<Alambic::Model::RepoFS> object.

=head2 C<write_input()>

    $repofs->write_input(
      'modeling.sirius', 
      'myfilename.txt'
      $content
    );

Write a file to the project input directory.

=head2 C<read_input()>

    $repofs->read_input('modeling.sirius', 'myfile.txt');
    
Read a file from the project input directory.

=head2 C<write_output()>

    $repofs->write_output(
      'modeling.sirius', 
      'myfilename.txt'
      $content
    );

Write a file to the project output directory.

=head2 C<read_output()>

    $repofs->read_output('modeling.sirius', 'myfile.txt');
    
Read a file from the project output directory.

=head2 C<write_plugin()>

    $repofs->write_plugin(
      'EclipsePmi', 
      'myfilename.txt'
      $content
    );

Write a file to the plugin directory.

=head2 C<read_plugin()>

    $repofs->read_plugin('EclipsePmi', 'myfile.txt');
    
Read a file from the plugin directory.

=head2 C<write_backup()>

    $repofs->write_backup(
      $content
    );

Write a file to the backup directory.

=head2 C<read_backup()>

    $repofs->read_backup('mybackup.sql');
    
Read a file from the backup directory.

=head2 C<write_models()>

    $repofs->write_models(
      'metrics', 
      'myfilename.txt'
      $content
    );

Write a file to the models directory.

=head2 C<read_models()>

    $repofs->read_models('metrics', 'myfile.txt');
    
Read a file from the models directory.

=head2 C<write_users()>

    $repofs->write_users(
      'EclipsePmi', 'modeling.sirius', $content
    );

Write user operations to the projects/<project_id>/users/ directory.

=head2 C<read_users()>

    my $users = $repofs->read_users('modeling.sirius');

Read user operations to the projects/<project_id>/users/ directory.

=head2 C<delete_project()>

    $repofs->delete_project('modeling.sirius');

Delete the complete hierarchy of files in projects/<project_id>.


=head1 SEE ALSO

L<Mojolicious>, L<http://alambic.io>, L<https://bitbucket.org/BorisBaldassari/alambic>

=cut
