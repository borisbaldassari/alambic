package Alambic::Controller::ManualData;

use Mojo::Base 'Mojolicious::Controller';
use Data::Dumper;

# Displays the form for the specific manual data type.
sub display {
  my $self = shift;
  
  my $data_plugin = params( 'type' );
  
}

sub analyse {
  my $self = shift;
  
  
}


1;
