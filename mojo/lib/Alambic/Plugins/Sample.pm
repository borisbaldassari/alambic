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
    "provides_metrics" => {
        "SOME_METRIC_IN" => "SOME_METRIC_OUT",
    },
    "provides_files" => [
        "sample"
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

    my $metrics_new;

    my $file_in = $app->config->{'dir_input'} . "/" . $project_id . "/" . $project_id . "_import_mls.json";
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

    my $file_out = $app->config->{'dir_input'} . "/" . $project_id . "/" . $project_id . "_metrics_mls.json";
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
