package Alambic::Plugins::EclipsePmi;
use base 'Mojolicious::Plugin';

use strict; 
use warnings;

use Mojo::JSON qw( decode_json encode_json );
use Mojo::UserAgent;
use Data::Dumper;

# Main configuration hash for the plugin
my %conf = (
    "id" => "eclipse_pmi",
    "name" => "Eclipse PMI",
    "desc" => "Retrieves data from the Eclipse PMI infrastructure.",
    "ability" => [ "metrics", "files" ],
    "requires" => {
        "project_id" => "",
    },
    "provides_metrics" => {
        
        "PUB_SCM_INFO_PMI" => "PUB_SCM_INFO_PMI",
        "PUB_ITS_INFO_PMI" => "PUB_ITS_INFO_PMI",
    },
    "provides_files" => [
        "pmi", 
    ]
);


my $eclipse_url = "https://projects.eclipse.org/json/project/";
my $polarsys_url = "https://polarsys.org/json/project/";

# my @pmi_attrs = (
#     "title", "desc", "id",
#     "bugzilla bugzilla_product", "bugzilla bugzilla_component", 
#     "bugzilla bugzilla_create_url", "bugzilla bugzilla_query_url", 
#     );

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

    my $ua = Mojo::UserAgent->new;

    push( @log, "Checking [Plugins::EclipsePMI] for [$project_id]..." );

    my ($url, $content);
    if ($project_id =~ m!^polarsys!) {
        $url = $polarsys_url . $project_id;
        push( @log, "Using PolarSys PMI infra at $url..." );
        $content = $ua->get($url)->res->body;
    } else {
        $url = $eclipse_url . $project_id;
        push( @log, "Using Eclipse PMI infra at $url." );
        $content = $ua->get($url)->res->body;
    }
    
    if (defined $content && $content =~ m!^{"projects":{"${project_id}!) {
        push( @log, "JSON looks good. ok." );
    } else {
        push( @log, "Error: cannot recognise JSON content." );
    }

    return \@log;
}

sub retrieve_data($) {
    my $self = shift;
    my $project_id = shift;
    
    my $project_conf = $app->projects->get_project_info($project_id)->{'ds'}->{$self->get_conf->{'id'}};
    my $project_pmi = $project_conf->{'project_id'};
    
    my @log;

    my $ua = Mojo::UserAgent->new;
    $ua->max_redirects(10);

    # Fetch json file from projects.eclipse.org
    my ($url, $content);
    if ($project_pmi =~ m!^polarsys!) {
        $url = $polarsys_url . $project_pmi;
        push( @log, "Using PolarSys PMI infra at [$url]." );
        $content = $ua->get($url)->res->body;
    } else {
        $url = $eclipse_url . $project_pmi;
        push( @log, "Using Eclipse PMI infra at [$url]." );
        $content = $ua->get($url)->res->body;
    }

    # Check if we actually get some results.
    my $pmi = decode_json($content);
    my $custom_pmi;
    if ( defined($pmi->{'projects'}->{$project_pmi}) ) {
        $custom_pmi = $pmi->{'projects'}->{$project_pmi};
    } else {
        my $msg_failed = [ "ERROR: Could not get [$url]!" ];
        return $msg_failed unless defined $content;
    }
    
    my $file_json_out = $app->config->{'dir_input'} . "/" . $project_id . "/" . $project_id . "_import_pmi.json";

    $app->log->debug("[Plugins::EclipsePMI] Writing PMI json file to [$file_json_out].");
    open my $fh, ">", $file_json_out;
    print $fh encode_json($custom_pmi);
    close $fh;

    return \@log;
}

sub compute_data($) {
    my $self = shift;
    my $project_id = shift;

    my %pmi;
    my %metrics;
    my @log;

    my $ua = Mojo::UserAgent->new;
    $ua->max_redirects(10);

    # Read data from pmi file in $data_input
    my $json; 
    my $file = $app->config->{'dir_input'} . "/" . $project_id . "/" . $project_id . "_import_pmi.json";
    my $msg_failed = [ "Could not open data file [$file]." ];
    do { 
        local $/;
        open my $fh, '<', $file or return $msg_failed;
        $json = <$fh>;
        close $fh;
    };

    # Decode the entire JSON
    my $raw_project = decode_json( $json ) or return [ "ERROR: Could not decode json: \n$json" ];;

    # Retrieve basic information about the project
    $pmi{"title"} = $raw_project->{"title"};
    $pmi{"desc"} = $raw_project->{"description"}->[0]->{"safe_value"};
    $pmi{"id"} = $raw_project->{"id"}->[0]->{"value"};

    # Retrieve information about Bugzilla
    my $pub_its_info = 0;
    if (scalar @{$raw_project->{"bugzilla"}} > 0) {

        $pmi{"bugzilla_product"} = $raw_project->{"bugzilla"}->[0]->{"product"};
        if ($pmi{"bugzilla_product"} =~ m!\S+!) { $pub_its_info++ };

        $pmi{"bugzilla_component"} = $raw_project->{"bugzilla"}->[0]->{"component"};
	
        $pmi{"bugzilla_create_url"} = $raw_project->{"bugzilla"}->[0]->{"create_url"};
        if ($pmi{"bugzilla_create_url"} =~ m!\S+!) { $pub_its_info++ };
        if ($ua->head($pmi{"bugzilla_create_url"})) {
            $pub_its_info++; 
        }

        $pmi{"bugzilla_query_url"} = $raw_project->{"bugzilla"}->[0]->{"query_url"};
        if ($pmi{"bugzilla_query_url"} =~ m!\S+!) { $pub_its_info++; }
        if ($ua->head($pmi{"bugzilla_query_url"})) {
            $pub_its_info++;
        }
    }	
    $metrics{"PUB_ITS_INFO_PMI"} = $pub_its_info;

    # Retrieve information about source repos
    my $pub_scm_info = 0;
    if (scalar @{$raw_project->{"source_repo"}} > 0) {
	$pmi{"source_repo_type"} = $raw_project->{"source_repo"}->[0]->{"type"};
	if ($pmi{"source_repo_type"} =~ m!\S+!) { $pub_scm_info += 2; };

	$pmi{"source_repo_name"} = $raw_project->{"source_repo"}->[0]->{"name"};
	if ($pmi{"source_repo_name"} =~ m!\S+!) { $pub_scm_info++ };

	$pmi{"source_repo_url"} = $raw_project->{"source_repo"}->[0]->{"url"};
	if ($pmi{"source_repo_url"} =~ m!\S+!) { $pub_scm_info++ };
	if ($ua->head($pmi{"source_repo_url"})) {
	    $pub_scm_info++;
	    $app->log->info( "  Got git url [" . $pmi{"source_repo_url"} . "]!" ); 
	}

    }
    $metrics{"PUB_SCM_INFO_PMI"} = $pub_scm_info;

    my $json_metrics = encode_json(\%metrics);

    my $file_json_out = $app->config->{'dir_input'} . "/" . $project_id . "/" . $project_id . "_metrics_pmi.json";
    $app->log->debug("[Plugins::EclipsePMI] Writing PMI metrics json file to [$file_json_out].");
    open my $fh, ">", $file_json_out;
    print $fh $json_metrics;
    close $fh;

    $file_json_out = $app->config->{'dir_input'} . "/" . $project_id . "/" . $project_id . "_pmi.json";

    $app->log->debug("[Plugins::EclipsePMI] Writing updated PMI json file to [$file_json_out].");
    open $fh, ">", $file_json_out;
    print $fh encode_json($raw_project);
    close $fh;

    return ["Copied " . scalar ( keys %metrics ) . " metrics."];
}


1;
