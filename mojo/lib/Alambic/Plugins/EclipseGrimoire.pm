package Alambic::Plugins::EclipseGrimoire;
use base 'Mojolicious::Plugin';

use strict; 
use warnings;

use Mojo::JSON qw( decode_json encode_json );
use LWP::Simple;
use Data::Dumper;

# Main configuration hash for the plugin
my %conf = (
    "id" => "eclipse_grimoire",
    "name" => "Eclipse Grimoire",
    "desc" => "Retrieves data from the Eclipse Grimoire repository. Please note that only a subset of Eclipse projects have the -grimoire.json file available, check on http://dashboard.eclipse.org/data/json/ to see if the project has it.",
    "ability" => [ "metrics" ],
    "requires" => {
        "grimoire_url" => "http://dashboard.eclipse.org/data/json/",
        "project_id" => "",
    },
    "provides_metrics" => {
        "ITS_AUTH_1M" => "ITS_AUTH_1M", 
        "ITS_BUGS_DENSITY" => "ITS_BUGS_DENSITY", 
        "ITS_BUGS_OPEN" => "ITS_BUGS_OPEN", 
        "ITS_FIX_MED_1M" => "ITS_FIX_MED_1M", 
        "ITS_UPDATES_1M" => "ITS_UPDATES_1M", 
        "MLS_DEV_AUTH_1M" => "MLS_DEV_AUTH_1M",
        "MLS_DEV_RESP_RATIO_1M" => "MLS_DEV_RESP_RATIO_1M",
        "MLS_DEV_RESP_TIME_MED_1M" => "MLS_DEV_RESP_TIME_MED_1M",
        "MLS_DEV_SUBJ_1M" => "MLS_DEV_SUBJ_1M", 
        "MLS_DEV_VOL_1M" => "MLS_DEV_VOL_1M", 
        "MLS_USR_AUTH_1M" => "MLS_USR_AUTH_1M", 
        "MLS_USR_RESP_RATIO_1M" => "MLS_USR_RESP_RATIO_1M", 
        "MLS_USR_RESP_TIME_MED_1M" => "MLS_USR_RESP_TIME_MED_1M", 
        "MLS_USR_SUBJ_1M" => "MLS_USR_SUBJ_1M",
        "MLS_USR_VOL_1M" => "MLS_USR_VOL_1M",
        "SCM_COMMITS_1M" => "SCM_COMMITS_1M", 
        "SCM_COMMITTED_FILES_1M" => "SCM_COMMITTED_FILES_1M",
        "SCM_COMMITTERS_1M" => "SCM_COMMITTERS_1M", 
        "SCM_STABILITY_1M" => "SCM_STABILITY_1M"
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
        . "-metrics-grimoirelib.json";
    my $file_out = $app->config->{'dir_input'} . "/" . $project_id . "/" . $project_id . "_import_grimoire.json";
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

    my $file_in = $app->config->{'dir_input'} . "/" . $project_id . "/" . $project_id . "_import_grimoire.json";
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

    my $file_out = $app->config->{'dir_input'} . "/" . $project_id . "/" . $project_id . "_metrics_grimoire.json";
    my $json_content = encode_json($metrics_new);
    do { 
        local $/;
        open my $fh, '>', $file_out or die "Could not open data file [$file_out].\n";
        print $fh $json_content;
        close $fh;
    };

    return [];
}


1;
