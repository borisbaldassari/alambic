package Alambic::Commands::init;
use Mojo::Base 'Mojolicious::Command';

use Alambic::Model::RepoDB;

has description => 'Command line initialisation for Alambic';
has usage       => "Usage: alambic init\n";

sub run {
  my ($self, @args) = @_;

 # Initialise the database:create tables, and use dumb values for name and desc.
 # See RepoDB::_db_init for more information
  my $config     = $self->app->plugin('Config');
  my $pg_alambic = $config->{'conf_pg_alambic'};
  my $repodb     = Alambic::Model::RepoDB->new($pg_alambic);

  # We don't want to empty the database if it already contains data
  if ($repodb->is_db_empty()) {
    print "Initialising the database.\n";
    $repodb->init_db();
  }
  else {
    print "The database is not empty. Cowardly refusing to initialise it.\n\n";
    exit;
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
