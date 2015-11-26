package Alambic::ManualData::OpennessRating;
use base 'Mojolicious::Plugin';

use strict; 
use warnings;

use Mojo::JSON qw( decode_json encode_json );
use Data::Dumper;

# Main configuration hash for the plugin
my %conf = (
    "id" => "data_openness_rating",
    "name" => "Manual Data: Openness",
    "desc" => "Proposes a survey to evaluate the openness of the project.",
    "ability" => [ "metrics", "files"],
    "requires" => {
        "project_id" => "default value",
    },
    "provides_metrics" => [
      "SOME_METRIC"
    ],
    "provides_files" => [
      "data_openness",
    ],
    "data" => [
      { 
        "id" => "License used",
        "name" => "license",
        "type" => "select",
        "desc" => "What is the license used for the project?",
        "choices" => [
          "GPL",
          "LGPL",
          "EPL",
        ],
      }
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

    push( @log, "No check defined in [Plugins::DataOpenness]..." );

    return \@log;
}

sub retrieve_data($) {
    my $self = shift;
    my $params = shift;

    
    
    my $file_json_to = $app->config->{'dir_input'} . "/" . $project_id . "/" . $project_id . "_data_openness.json";;

    $app->log->debug("[Plugins::DataOpenness] Writing manual data in json file to [$file_json_out].");
    open my $fh, ">", $file_json_out;
    print $fh $content;
    close $fh;
    
}

sub compute_data($) {
    my $self = shift;
    my $project_id = shift;


}


1;
