package Alambic::Commands::alambic;
use Mojo::Base 'Mojolicious::Command';

use Alambic::Model::RepoDB;

has description => 'Command line for Alambic';
has usage       => "Usage: alambic [TARGET]\n";

sub run {
  my ($self, @args) = @_;

  # Initialise the database:create tables, and use dumb values for name and desc.
  # See RepoDB::_db_init for more information
  if ($args[0] eq 'init') { 
      my $config = $self->app->plugin('Config');
      my $pg_alambic = $config->{'conf_pg_alambic'};
      my $repodb = Alambic::Model::RepoDB->new($pg_alambic);
      $repodb->init_db();

      # Set instance parameters
      $self->app->al->get_repo_db()->name('Default CLI init');
      $self->app->al->get_repo_db()->desc('Default CLI Init description');
      
      # Set administrator parameters.
      my $project = $self->app->al->set_user( 
          'administrator', 'Administrator', 'alambic@castalia.solutions', 
          'password', ['Admin'], {}, {} );
  } elsif ($args[0] eq 'backup') { 

    my $sql = $self->app->al->backup();
    my $repofs = Alambic::Model::RepoFS->new();
    my $file_sql = $repofs->write_backup($sql);
    
    say "Database has been backed up in [$file_sql].";
      
      
  } elsif ($args[0] eq 'check') { 
      
      
  } elsif ($args[0] eq 'mode') { 
      say $self->app->mode 
  }
}



1;
