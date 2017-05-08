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

Usage: alambic <command>

Alambic commands: 
* bin/alambic about                 Initialise the database.
* bin/alambic init                  Initialise the database.
* bin/alambic backup                Backup the database.
* bin/alambic password user mypass  Reset password for user.

Other Mojolicious commands: 
* bin/alambic minion                Manage job queuing system.
* bin/alambic daemon                Run application in development mode.
* bin/alambic prefork               Run application in production (multithreaded) mode.

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
  

}


1;
