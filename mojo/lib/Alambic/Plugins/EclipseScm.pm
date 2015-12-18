package Alambic::Plugins::EclipseScm;
use base 'Mojolicious::Plugin';

use strict; 
use warnings;

use Mojo::JSON qw( decode_json encode_json );
use LWP::Simple;
use Data::Dumper;

# Main configuration hash for the plugin
my %conf = (
    "id" => "eclipse_scm",
    "name" => "Eclipse SCM",
    "desc" => "Retrieves configuration management data from the Eclipse dashboard repository. This plugin will look for a file named project-scm-prj-static.json on http://dashboard.eclipse.org/data/json/. This plugin is redundant with the EclipseGrimoire plugin",
    "ability" => [ "metrics" ],
    "requires" => {
        "grimoire_url" => "http://dashboard.eclipse.org/data/json/",
        "project_id" => "",
    },
    "provides_metrics" => {
        "AUTHORS" => "SCM_AUTHORS", 
        "AUTHORS_30" => "SCM_AUTHORS_30", 
        "AUTHORS_365" => "SCM_AUTHORS_365", 
        "AUTHORS_7" => "SCM_AUTHORS_7",
        "COMMITS" => "SCM_COMMITS", 
        "COMMITS_30" => "SCM_COMMITS_30",
        "COMMITS_365" => "SCM_COMMITS_365",
        "COMMITS_7" => "SCM_COMMITS_7", 
        "COMMITTERS" => "SCM_COMMITTERS",
        "FILES" => "SCM_FILES", 
        "REPOSITORIES" => "SCM_REPOSITORIES",
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
        . $project_id 
        . "-scm-prj-static.json";
    my $file_out = $app->config->{'dir_input'} . "/" . $project_id . "/" . $project_id . "_metrics_scm.json";
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
