package Alambic::Model::Helpers;

use base 'Mojolicious::Plugin';

use Data::Dumper;


sub register {
    
    my ($self, $app) = @_;
    
    $app->helper(
        comp_c => sub { 
            my $self = shift;
            my $value = shift || 0;
            return $app->al_config->get_colours()->[int($value)];
        },
        );
    
}

1;
