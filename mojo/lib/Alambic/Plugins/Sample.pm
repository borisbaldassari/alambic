package Alambic::Plugins::Sample;
use base 'Mojolicious::Plugin';

use strict; 
use warnings;

use Mojo::JSON qw( decode_json encode_json );
use Data::Dumper;

# Main configuration hash for the plugin
my %conf = (
    "id" => "alambic_sample",
    "name" => "Alambic Sample",
    "desc" => "Retrieves data from somewhere and include them in Alambic system.",
    "ability" => [ "metrics", "files", "viz" ],
    "requires" => {
        "data_a" => 'default value',
        "project_id" => "default value",
    },
    "provides_metrics" => [
        "SOME_METRIC"
    ],
    "provides_files" => [
        "_files"
    ]
);

my $app;

sub register {
    my $self = shift;
    $app = shift;
    
}

sub get_conf() {
    return \%conf;
}

sub check_plugin() {

}

sub check_project() {
    my $self = shift;
    my $project_id = shift;

    my @log;

    push( @log, "Checking [Plugins::Sample]..." );

    return \@log;
}

sub retrieve_data($) {
    my $self = shift;
    my $project_id = shift; 


}

sub compute_data($) {
    my $self = shift;
    my $project_id = shift;


}


1;
