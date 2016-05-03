package Alambic::Controller::Alambic;
use Mojo::Base 'Mojolicious::Controller';

use Data::Dumper;

# Main screen for Alambic
sub welcome {
    my $self = shift;

    # Render template "alambic/welcome.html.ep"
    $self->render();
}



1;
