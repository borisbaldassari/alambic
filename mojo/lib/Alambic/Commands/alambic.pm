package Alambic::Commands::alambic;
use Mojo::Base 'Mojolicious::Command';

has description => 'Command line for Alambic';
has usage       => "Usage: alambic [TARGET]\n";

sub run {
  my ($self, @args) = @_;

  # Initialise the database. Use dumb values for name and desc.
  # See RepoDB::_db_init for more information
  if ($args[0] eq 'init') { $self->app->al->init() }

  # Leak mode
  elsif ($args[0] eq 'mode') { say $self->app->mode }
}



1;
