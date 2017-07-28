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

package Alambic::Commands::init;
use Mojo::Base 'Mojolicious::Command';

use Alambic::Model::RepoDB;

has description => 'Command line initialisation for Alambic';
has usage       => "Usage: alambic init\n";

sub run {
  my ($self, @args) = @_;

  if ( scalar(@args) != 0 ) {
      my $usage = "
Welcome to the Alambic application. 

See http://alambic.io for more information about the project. 

Usage: alambic init

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

 # Initialise the database:create tables, and use dumb values for name and desc.
 # See RepoDB::_db_init for more information
  my $config     = $self->app->plugin('Config');
  my $pg_alambic = $config->{'conf_pg_alambic'};
  my $repodb     = Alambic::Model::RepoDB->new($pg_alambic);

  # We don't want to empty the database if it already contains data
  if ( $repodb->is_db_ok() and not $repodb->is_db_empty()) {
      print "Database is initialised and is not empty. Cowardly refusing to clear it.\n\n";
      exit;
  } else {
      print "Database is nok or is empty.\nInitialising database.\n";
      $repodb->init_db();
  }

  # Set instance parameters
  print "Initialising instance parameters.\n";
  $self->app->al->get_repo_db()->name('Default CLI init');
  $self->app->al->get_repo_db()->desc('Default CLI Init description');

  # Set administrator parameters.
  print "Creating administrator account.\n";
  my $project = $self->app->al->set_user('administrator', 'Administrator',
    'alambic@castalia.solutions', 'password', ['Admin'], {}, {});

}


1;

=encoding utf8

=head1 NAME

B<Alambic::Commands::init> - Initialise the database and set basic settings for Alambic.

=head1 SYNOPSIS

Initialise the database and set basic settings for Alambic:

  $ bin/alambic init
  Database is nok or is empty.
  Initialising database.
  NOTICE:  la table « conf » n'existe pas, poursuite du traitement
  NOTICE:  la table « users » n'existe pas, poursuite du traitement
  NOTICE:  la table « projects_conf » n'existe pas, poursuite du traitement
  NOTICE:  la table « projects_runs » n'existe pas, poursuite du traitement
  NOTICE:  la table « projects_info » n'existe pas, poursuite du traitement
  NOTICE:  la table « projects_cdata » n'existe pas, poursuite du traitement
  NOTICE:  la table « models_metrics » n'existe pas, poursuite du traitement
  NOTICE:  la table « models_attributes » n'existe pas, poursuite du traitement
  NOTICE:  la table « models_qms » n'existe pas, poursuite du traitement
  Initialising instance parameters.
  Creating administrator account.
  $

For safety, if the database is already populated then the init command fails. In this case
remove tables manually (or re-create the database) and re-execute the command.

=head1 SEE ALSO

L<Alambic>, L<http://alambic.io>, L<https://bitbucket.org/BorisBaldassari/alambic>, L<Mojolicious>.

=cut
