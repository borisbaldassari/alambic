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

package Alambic::Commands::backup;
use Mojo::Base 'Mojolicious::Command';

use Alambic::Model::RepoDB;

has description => 'Command line backup for Alambic';
has usage       => "Usage: alambic backup\n";

sub run() {

  my ($self, @args) = @_;

  if ( scalar(@args) != 0 ) {
      my $usage = "
Welcome to the Alambic application. 

See http://alambic.io for more information about the project. 

Usage: alambic backup

Other Alambic commands: 
* alambic about                 Display this help text.
* alambic init                  Initialise the database.
* alambic backup                Backup the database.
* alambic password user mypass  Reset password for user.

Other Mojolicious commands: 
* alambic minion                Manage job queuing system.
* alambic daemon                Run application in development mode.
* alambic prefork               Run application in production (multithreaded) mode.

";
      print $usage;
      exit;
  }

  say "Starting database backup.";

  my $sql      = $self->app->al->backup();
  my $repofs   = Alambic::Model::RepoFS->new();
  my $file_sql = $repofs->write_backup($sql);

  say "Database has been backed up in [$file_sql].";

}


1;


=encoding utf8

=head1 NAME

B<Alambic::Commands::backup> - Start a complete backup of the Alambic instance.

=head1 SYNOPSIS

Start a complete backup of the Alambic instance:

  $ bin/alambic backup
  Starting database backup.
  Database has been backed up in [backups/alambic_backup_201707281338.sql].


=head1 SEE ALSO

L<Alambic>, L<http://alambic.io>, L<https://bitbucket.org/BorisBaldassari/alambic>, L<Mojolicious>.

=cut
