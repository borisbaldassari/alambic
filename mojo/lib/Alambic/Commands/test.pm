#########################################################
#
# Copyright (c) 2015-2020 Castalia Solutions and others.
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

package Alambic::Commands::test;
use Mojo::Base 'Mojolicious::Command';

use App::Prove;

has description => 'Execute tests for Alambic';
has usage       => "Usage: alambic test\n";

sub run() {

  my ($self, @args) = @_;

  if (scalar(@args) != 0) {
    my $usage = "
Welcome to the Alambic application. 

See http://alambic.io for more information about the project. 

Usage: alambic backup

Other Alambic commands: 
* alambic about                 Display this help text.
* alambic init                  Initialise the database.
* alambic test                  Execute all tests.
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

  # Initialise the instance before running the tests.
  say "# Initialising the instance for the tests.";

  # Initialise the database:create tables, and use dumb values for name and desc.
  # See RepoDB::_db_init for more information
  my $config     = $self->app->plugin('Config');
  my $pg_alambic = $config->{'conf_pg_alambic'};
  my $repodb     = Alambic::Model::RepoDB->new($pg_alambic);

  # We don't want to empty the database if it already contains data
  if ($repodb->is_db_ok() and not $repodb->is_db_empty()) {
    print
      "Database is initialised and is not empty. Cowardly refusing to test and clear it.\n\n";
    exit;
  }
  else {
    print "Database is nok or is empty.\nInitialising database.\n";
    $repodb->init_db();
  }

  # Set instance parameters
  print "Initialising instance parameters.\n";
  $self->app->al->get_repo_db()->name('Default CLI init');
  $self->app->al->get_repo_db()->desc('Default CLI Init description');
  $self->app->al->get_repo_db()->anonymise_data('1');

  # Set administrator parameters.
  print "Creating administrator account.\n";
  my $project = $self->app->al->set_user('administrator', 'Administrator',
    'alambic@castalia.solutions', 'password', ['Admin'], {}, {});

  say "# Starting tests for Alambic.";

  my $app = App::Prove->new;
  $app->process_args(('-lr', 't/'));
  $app->run;

}


1;


=encoding utf8

=head1 NAME

B<Alambic::Commands::test> - Execute all tests for Alambic.

=head1 SYNOPSIS

Start the execution of all tests available in the t/ directory:

  $ bin/alambic test
  Starting tests for Alambic.
  t/ui/001_basic.t ...................... ok    
  t/ui/002_documentation.t .............. ok    
  [SNIP]
  t/unit/Tools/R.t ...................... ok    
  All tests successful.
  Files=26, Tests=1268, 810 wallclock secs ( 0.14 usr  0.06 sys + 60.37 cusr  5.06 csys = 65.63 CPU)
  Result: PASS

=head1 SEE ALSO

L<Alambic>, L<Alambic::Model::Alambic>, L<http://alambic.io>, L<https://bitbucket.org/BorisBaldassari/alambic>, L<Mojolicious>.

=cut
