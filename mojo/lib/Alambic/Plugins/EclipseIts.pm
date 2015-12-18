package Alambic::Plugins::EclipseIts;
use base 'Mojolicious::Plugin';

use strict; 
use warnings;

use Mojo::JSON qw( decode_json encode_json );
use LWP::Simple;
use Data::Dumper;

# Main configuration hash for the plugin
my %conf = (
    "id" => "eclipse_its",
    "name" => "Eclipse ITS",
    "desc" => "Retrieves bug tracking system data from the Eclipse dashboard repository. This plugin will look for a file named project-its-prj-static.json on http://dashboard.eclipse.org/data/json/. This plugin is redundant with the EclipseGrimoire plugin",
    "ability" => [ "metrics" ],
    "requires" => {
        "grimoire_url" => "http://dashboard.eclipse.org/data/json/",
        "project_id" => "",
    },
    "provides_metrics" => {
        "CHANGED" => "ITS_CHANGED", 
        "CHANGERS" => "ITS_CHANGERS", 
        "CLOSED" => "ITS_CLOSED", 
        "CLOSED_30" => "ITS_CLOSED_30", 
        "CLOSED_365" => "ITS_CLOSED_365", 
        "CLOSED_7" => "ITS_CLOSED_7",
        "CLOSERS" => "ITS_CLOSERS", 
        "CLOSERS_30" => "ITS_CLOSERS_30", 
        "CLOSERS_365" => "ITS_CLOSERS_365", 
        "CLOSERS_7" => "ITS_CLOSERS_7", 
        "TRACKERS" => "ITS_TRACKERS", 
        "OPENED" => "ITS_OPENED", 
        "OPENERS" => "ITS_OPENERS", 
        "PERCENTAGE_CLOSED" => "ITS_PERCENTAGE_CLOSED", 
        "PERCENTAGE_CLOSED_30" => "ITS_PERCENTAGE_CLOSED_30", 
        "PERCENTAGE_CLOSED_365" => "ITS_PERCENTAGE_CLOSED_365",
        "PERCENTAGE_CLOSED_7" => "ITS_PERCENTAGE_CLOSED_7", 
    },
    "provides_files" => [
    ],
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
        . "-its-prj-static.json";
    my $file_out = $app->config->{'dir_input'} . "/" . $project_id . "/" . $project_id . "_import_its.json";
    push( @log, "Retrieving [$url] to [$file_out].\n" );
    
    # Fetch json file from the dashboard.eclipse.org
    my $content = getstore($url, $file_out);
    if ($content != 200) { push( @log, "Cannot find [$url].\n" ) };

    return \@log;
}

sub compute_data($) {
    my $self = shift;
    my $project_id = shift;

    my $metrics_new;

    my $file_in = $app->config->{'dir_input'} . "/" . $project_id . "/" . $project_id . "_import_its.json";
    my $json;
    do { 
        local $/;
        open my $fh, '<', $file_in or die "Could not open data file [$file_in].\n";
        $json = <$fh>;
        close $fh;
    };
    my $metrics_old = decode_json($json);

    foreach my $metric (keys %{$metrics_old}) {
        if ( exists( $conf{'provides_metrics'}{uc($metric)} ) ) {
            $metrics_new->{ $conf{'provides_metrics'}{uc($metric)} } = $metrics_old->{$metric};
        }
    }

    my $file_out = $app->config->{'dir_input'} . "/" . $project_id . "/" . $project_id . "_metrics_its.json";
    my $json_content = encode_json($metrics_new);
    do { 
        local $/;
        open my $fh, '>', $file_out or die "Could not open data file [$file_out].\n";
        print $fh $json_content;
        close $fh;
    };

    return ["Done."];
}


1;
