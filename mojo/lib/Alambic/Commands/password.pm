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

package Alambic::Commands::password;
use Mojo::Base 'Mojolicious::Command';

use Alambic::Model::RepoDB;
use Data::Dumper;

has description => 'Alambic Reset administrator password for users.';
has usage       => "Usage: alambic password user newpassword\n";

sub run {
  my ($self, @args) = @_;

  if ( scalar(@args) != 2 ) {
      my $usage = "
Welcome to the Alambic application. 

See http://alambic.io for more information about the project. 

Usage: alambic password user newpassword

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

  my $user = shift @args;
  my $passwd = shift @args;
  my $al_user = $self->app->al->users->get_user($user);
  
  my $project = $self->app->al->set_user( 
      $al_user->{'id'}, $al_user->{'name'}, $al_user->{'email'}, 
      $passwd, $al_user->{'roles'}, $al_user->{'projects'},
      $al_user->{'notifs'});
  
  say "Successfully changed password for user [$al_user->{'name'}] id [$al_user->{'id'}].\n";
  
}


1;

=encoding utf8

=head1 NAME

B<Alambic::Commands::password> - Resets the password of an Alambic user.

=head1 SYNOPSIS

Resets the password of an Alambic user.

  $ alambic password administrator newpassword
  Successfully changed password for user [Administrator].
  
  $ 

=head1 SEE ALSO

L<Alambic>, L<Alambic::Model::Alambic>, L<http://alambic.io>, L<https://bitbucket.org/BorisBaldassari/alambic>, L<Mojolicious>.

=cut
