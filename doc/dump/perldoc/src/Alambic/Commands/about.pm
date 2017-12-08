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

package Alambic::Commands::about;
use Mojo::Base 'Mojolicious::Command';

use Alambic::Model::RepoDB;

has description => 'Command line help for Alambic';
has usage       => "Usage: alambic about\n";

sub run {
  my ($self, @args) = @_;

  my $usage = "
Welcome to the Alambic application. 

See http://alambic.io for more information about the project. 

Usage: alambic <command>

Alambic commands: 
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

}


1;


=encoding utf8

=head1 NAME

B<Alambic::Commands::about> - Shows a quick help of Alambic commands.

=head1 SYNOPSIS

Shows a quick help of Alambic commands:

  $ bin/alambic about
  
  Welcome to the Alambic application. 
  
  See http://alambic.io for more information about the project. 
  
  Usage: alambic <command>
  
  Alambic commands: 
  * alambic about                 Display this help text.
  * alambic init                  Initialise the database.
  * alambic backup                Backup the database.
  * alambic password user mypass  Reset password for user.
  
  Other Mojolicious commands: 
  * alambic minion                Manage job queuing system.
  * alambic daemon                Run application in development mode.
  * alambic prefork               Run application in production (multithreaded) mode.


=head1 SEE ALSO

L<Alambic>, L<Alambic::Model::Alambic>, L<http://alambic.io>, L<https://bitbucket.org/BorisBaldassari/alambic>, L<Mojolicious>.

=cut
