package Alambic::Plugins::EclipseMls;
use base 'Mojolicious::Plugin';

use strict; 
use warnings;

use Mojo::JSON qw( decode_json encode_json );
use LWP::Simple;
use Data::Dumper;

# Main configuration hash for the plugin
my %conf = (
    "id" => "eclipse_mls",
    "name" => "Eclipse MLS",
    "desc" => "Retrieves mailing list data from the Eclipse dashboard repository. This plugin will look for a file named project-mls-prj-static.json on http://dashboard.eclipse.org/data/json/. This plugin is redundant with the EclipseGrimoire plugin",
    "ability" => [ "metrics" ],
    "requires" => {
        "grimoire_url" => "http://dashboard.eclipse.org/data/json/",
        "project_id" => "",
    },
    "provides_metrics" => {
        "REPOSITORIES" => "MLS_REPOSITORIES", 
        "SENDERS" => "MLS_SENDERS", 
        "SENDERS_30" => "MLS_SENDERS_30", 
        "SENDERS_365" => "MLS_SENDERS_365", 
        "SENDERS_7" => "MLS_SENDERS_7", 
        "SENDERS_RESPONSE" => "MLS_SENDERS_RESPONSE",
        "SENT" => "MLS_SENT", 
        "SENT_30" => "MLS_SENT_30", 
        "SENT_365" => "MLS_SENT_365", 
        "SENT_7" => "MLS_SENT_7", 
        "SENT_RESPONSE" => "MLS_SENT_RESPONSE", 
        "THREADS" => "MLS_THREADS",
    },
    "provides_files" => [
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

    return [];
}

sub retrieve_data($) {
    my $self = shift;
    my $project_id = shift;
    
    my @log;
    my $url = "http://dashboard.eclipse.org/data/json/" 
        . $project_id . "-mls-prj-static.json";
    my $file_out = $app->config->{'dir_input'} . "/" . $project_id . "/" . $project_id . "_metrics__mls.json";
    push( @log, "Retrieving [$url] to [$file_out].\n" );
    
    # Fetch json file from the dashboard.eclipse.org
    my $content = getstore($url, $file_out);
    if ($content != 200) { push( @log, "Cannot find [$url].\n" ) };

    return \@log;
}

sub compute_data($) {
    my $self = shift;
    my $project_id = shift;

    return ["Done."];
}


1;
