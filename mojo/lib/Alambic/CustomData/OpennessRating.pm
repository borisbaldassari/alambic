package Alambic::CustomData::OpennessRating;
use base 'Mojolicious::Plugin';

use strict; 
use warnings;

use Mojo::JSON qw( decode_json encode_json );
use Data::Dumper;

# Main configuration hash for the plugin
my %conf = (
    "id" => "data_openness_rating",
    "name" => "Custom Data: Openness rating",
    "desc" => "Proposes a survey to evaluate the openness of the project. See ref [xxx]  for more information.",
    "ability" => [ "metrics", "files"],
    "requires" => {
        "project_id" => "default value",
    },
    "provides_metrics" => [
      "SOME_METRIC"
    ],
    "provides_files" => [
      "data_openness_rating",
    ],
    "data" => [
      { 
        "id" => "licence",
        "name" => "Licence used",
        "type" => "select",
        "desc" => "What is the licence used for the project?",
        "choices" => [
          "GPL",
          "LGPL",
          "EPL",
        ],
      },
      { 
        "id" => "team_size",
        "name" => "Size of the team",
        "type" => "number",
        "desc" => "Number of people in the team.",
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



#
# Manages the results of the surveys and stores them in a file named <$projectid>_cdataid.json
#
sub retrieve_data($) {
    my $self = shift;
    my $project_id = shift;
    my $args = shift;

    # Read the file (if it exists), then update the content 
    # and write it back to disk.

    my $file_json = $app->config->{'dir_input'} . "/" . $project_id . "/" 
        . $project_id . "_data_openness_rating.json";

    my $result;

    if (-e $file_json) {
        my $str;
        open my $fh_in, "<", $file_json;
        while (<$fh_in>) { chomp; $str .= $_; }
        close $fh_in;
        $result = decode_json($str);

        # Update the date attribute (generated on ...)
        $result->{'version'} = "Generated on " . localtime();
        # Add our own values.
        push( @{$result->{'children'}}, $args );

    } else {

        # Return a hash to be saved with the specific values stored in.
        $result = {
            "project" => "$project_id",
            "cd" => "data_openness_rating",
            "version" => "Generated on " . localtime(),
            "children" => [
                $args,
                ]
        };
    }

    my $content = encode_json( $result );

    # Add new metric to the specific file for the project.
    $app->log->debug( "[Controller::CustomData] Writing custom data [$conf{'id'}] json file to [$file_json]." );
    open my $fh, ">", $file_json;
    print $fh $content;
    close $fh;

}


sub compute_metrics($) {
    my $self = shift;
    my $project_id = shift;

    # Here do the treatment of data and compute metrics.
    my %metrics_file = (
        "OPENNESS_RATING" => 3,
    );


    my $file_json = $app->config->{'dir_input'} . "/" . $project_id . "/" 
        . $project_id . "_metrics_openness_rating.json";
    
    my $content = encode_json( \%metrics_file );

    # Add new metric to the specific file for the project.
    $app->log->debug( "[Controller::CustomData] Writing custom data [$conf{'id'}] json file to [$file_json]." );
    open my $fh, ">", $file_json;
    print $fh $content;
    close $fh;

}


1;
