package Alambic::Plugins::EclipseMls;

use strict; 
use warnings;

use Alambic::Model::RepoFS;
use Alambic::Tools::R;

use Mojo::JSON qw( decode_json encode_json );
use Mojo::UserAgent;
use Data::Dumper;

# Main configuration hash for the plugin
my %conf = (
    "id" => "EclipseMls",
    "name" => "Eclipse MLS",
    "desc" => [
	'Retrieves mailing list data from the Eclipse dashboard repository. This plugin will look for a file named project-mls-prj-static.json on http://dashboard.eclipse.org/data/json/. This plugin is redundant with the EclipseGrimoire plugin',
	'See <a href="https://bitbucket.org/BorisBaldassari/alambic/wiki/Plugins/3.x/EclipseMls">the project\'s wiki</a> for more information.',
    ],
    "type" => 'pre',
    "ability" => [ 'metrics', 'data', 'recs', 'figs', 'viz' ],
    "params" => {
        "project_grim" => "The ID used to identify the project on the dashboard server. Note that it may be different from the id used in the PMI.",
    },
    "provides_cdata" => [
    ],
    "provides_info" => [
    ],
    "provides_data" => {
	"import_mls.json" => "The original file of current metrics from the Eclipse dashboard server (JSON).",
	"metrics_mls.json" => "Current metrics for the MLS plugin (JSON).",
	"metrics_mls.csv" => "Current metrics for the MLS plugin (CSV).",
	"metrics_mls_evol.json" => "Evolution metrics for the MLS plugin (JSON).",
	"metrics_mls_evol.csv" => "Evolution metrics for the MLS plugin (CSV).",
    },
    "provides_metrics" => {
        "REPOSITORIES" => "MLS_REPOSITORIES", 
        "SENDERS" => "MLS_SENDERS", 
        "SENDERS_30" => "MLS_SENDERS_30", 
        "SENDERS_365" => "MLS_SENDERS_365", 
        "SENDERS_7" => "MLS_SENDERS_7", 
        "DIFF_NETSENDERS_30" => "MLS_DIFF_NETSENDERS_30", 
        "DIFF_NETSENDERS_365" => "MLS_DIFF_NETSENDERS_365", 
        "DIFF_NETSENDERS_7" => "MLS_DIFF_NETSENDERS_7", 
        "SENDERS_RESPONSE" => "MLS_SENDERS_RESPONSE",
        "PERCENTAGE_SENDERS_30" => "MLS_PERCENTAGE_SENDERS_30", 
        "PERCENTAGE_SENDERS_365" => "MLS_PERCENTAGE_SENDERS_365", 
        "PERCENTAGE_SENDERS_7" => "MLS_PERCENTAGE_SENDERS_7", 
        "SENT" => "MLS_SENT", 
        "SENT_30" => "MLS_SENT_30", 
        "SENT_365" => "MLS_SENT_365", 
        "SENT_7" => "MLS_SENT_7", 
        "DIFF_NETSENT_30" => "MLS_DIFF_NETSENT_30", 
        "DIFF_NETSENT_365" => "MLS_DIFF_NETSENT_365", 
        "DIFF_NETSENT_7" => "MLS_DIFF_NETSENT_7", 
        "PERCENTAGE_SENT_30" => "MLS_PERCENTAGE_SENT_30", 
        "PERCENTAGE_SENT_365" => "MLS_PERCENTAGE_SENT_365", 
        "PERCENTAGE_SENT_7" => "MLS_PERCENTAGE_SENT_7", 
        "SENT_RESPONSE" => "MLS_SENT_RESPONSE", 
        "THREADS" => "MLS_THREADS",
    },
    "provides_figs" => {
	"mls_evol_summary.rmd" => "mls_evol_summary.html",
	"mls_evol_people.rmd" => "mls_evol_people.html",
	"mls_evol_sent.rmd" => "mls_evol_sent.html",
    },
    "provides_recs" => [
        "MLS_SENT",
    ],
    "provides_viz" => {
        "eclipse_mls.html" => "Eclipse MLS",
    },
);


# Constructor
sub new {
    my ($class) = @_;
    
    return bless {}, $class;
}


sub get_conf() {
    return \%conf;
}


# Run plugin: retrieves data + compute_data 
sub run_plugin($$) {
    my ($self, $project_id, $conf) = @_;
    
    my %ret = (
	'metrics' => {},
	'info' => {},
	'recs' => [],
	'log' => [],
	);

    # Create RepoFS object for writing and reading files on FS.
    my $repofs = Alambic::Model::RepoFS->new();

    my $project_grim = $conf->{'project_grim'};

    # Retrieve and store data from the remote repository.
    $ret{'log'} = &_retrieve_data( $project_id, $project_grim, $repofs );
    
    # Analyse retrieved data, generate info, metrics, plots and visualisation.
    my $tmp_ret = &_compute_data( $project_id, $project_grim, $repofs );
    
    $ret{'metrics'} = $tmp_ret->{'metrics'};
    $ret{'recs'} = $tmp_ret->{'recs'};
    push( @{$ret{'log'}}, @{$tmp_ret->{'log'}} );
    
    return \%ret;
}


# Download json file from dashboard.eclipse.org
sub _retrieve_data($$$) {
    my ($project_id, $project_grim, $repofs) = @_;

    my @log;

    my $url = "http://dashboard.eclipse.org/data/json/" 
            . $project_grim . "-mls-prj-static.json";

    push( @log, "[Plugins::EclipseMls] Starting retrieval of data for [$project_id] url [$url]." );

    # Fetch json file from the dashboard.eclipse.org
    my $ua = Mojo::UserAgent->new;
    my $content = $ua->get($url)->res->body;
    if (length($content) < 10) { 
	push( @log, "[Plugins::EclipseMls] Cannot find [$url].\n" ) ;
    } else {
	$repofs->write_input( $project_id, "import_mls.json", $content );
	$repofs->write_output( $project_id, "import_mls.json", $content );
    }

    $url = "http://dashboard.eclipse.org/data/json/" 
            . $project_grim . "-mls-prj-evolutionary.json";
    
    push( @log, "[Plugins::EclipseMls] Retrieving evol [$url] to input.\n" );
    
    # Fetch json file from the dashboard.eclipse.org
    $ua = Mojo::UserAgent->new;
    $content = $ua->get($url)->res->body;
    if (length($content) < 10) {
	push( @log, "[Plugins::EclipseMls] Cannot find [$url].\n" ) ;
    } else {
	$repofs->write_input( $project_id, "import_mls_evol.json", $content );
	$repofs->write_output( $project_id, "metrics_mls_evol.json", $content );
    }

    return \@log;
}


# Basically read the imported files and make the mapping to the 
# new metric names.
sub _compute_data($$$) {
    my ($project_id, $project_pmi, $repofs) = @_;

    my @recs;
    my @log;

    push( @log, "[Plugins::EclipseMls] Starting compute data for [$project_id]." );

    my $metrics_new;

    # Read data from mls file in $data_input
    my $json = $repofs->read_input( $project_id, "import_mls.json" );
    my $metrics_old = decode_json($json);

    foreach my $metric (keys %{$metrics_old}) {
        if ( exists( $conf{'provides_metrics'}{uc($metric)} ) ) {
            $metrics_new->{ $conf{'provides_metrics'}{uc($metric)} } = $metrics_old->{$metric};
        }
    }
    
    # Write mls metrics json file to disk.
    $repofs->write_output( $project_id, "metrics_mls.json", encode_json($metrics_new) );

    # Write static metrics file
    my @metrics = sort map {$conf{'provides_metrics'}{$_}} keys %{$conf{'provides_metrics'}};
    my $csv_out = join( ',', sort @metrics) . "\n";
    $csv_out .= join( ',', map { $metrics_new->{$_} } sort @metrics) . "\n";
    
    $repofs->write_plugin( 'EclipseMls', $project_id . "_mls.csv", $csv_out );
    $repofs->write_output( $project_id, "metrics_mls.csv", $csv_out );

    # Read evol metrics file
    $json = $repofs->read_input( $project_id, "import_mls_evol.json" );
    my $metrics_evol = decode_json($json);

    # Create csv data for evol
    $csv_out = "date,sent_response,id,senders_init,senders_response,sent,threads,repositories,senders,unixtime\n";
    foreach my $id ( 0 .. (scalar(@{$metrics_evol->{'date'}}) -1 ) ) {
	$csv_out .= $metrics_evol->{'date'}->[$id] . ',';
	$csv_out .= $metrics_evol->{'sent_response'}->[$id] . ',';
	$csv_out .= $metrics_evol->{'id'}->[$id] . ',';
	$csv_out .= $metrics_evol->{'senders_init'}->[$id] . ',';
	$csv_out .= $metrics_evol->{'senders_response'}->[$id] . ',';
	$csv_out .= $metrics_evol->{'sent'}->[$id] . ',';
	$csv_out .= $metrics_evol->{'threads'}->[$id] . ',';
	$csv_out .= $metrics_evol->{'repositories'}->[$id] . ',';
	$csv_out .= $metrics_evol->{'senders'}->[$id] . ',';
	$csv_out .= $metrics_evol->{'unixtime'}->[$id] . "\n";
    }
    $repofs->write_plugin( 'EclipseMls', $project_id . "_mls_evol.csv", $csv_out );
    $repofs->write_output( $project_id, "metrics_mls_evol.csv", $csv_out );
    
    # Now execute the main R script.
    push( @log, "[Plugins::EclipseMls] Executing R main file." );
    my $r = Alambic::Tools::R->new();
    @log = ( @log, @{$r->knit_rmarkdown_inc( 'EclipseMls', $project_id, 'eclipse_mls.Rmd' )} );

    # And execute the figures R scripts.
    my @figs = grep( /.*\.rmd$/i, keys %{$conf{'provides_figs'}} );
    foreach my $fig (sort @figs) {
	push( @log, "[Plugins::EclipseMls] Executing R fig file [$fig]." );
	@log = ( @log, @{$r->knit_rmarkdown_html( 'EclipseMls', $project_id, $fig )} );
    }

    # TODO Execute checks and fill recs.
    if ($metrics_new->{'MLS_SENT'} < 10) {
	push( @recs, { 'rid' => 'MLS_SENT', 
		       'severity' => 1, 
		       'desc' => 'There are only ' . $metrics_new->{'MLS_SENT'} 
		       . ' mails sent in the archive. You should watch the mailing list and create some activity so users can get more information, see that the project is active, in order to attract new participants.' 
	      } 
	    );
    }
    
    return {
	"metrics" => $metrics_new,
	"recs" => \@recs,
	"log" => \@log,
    };
}


1;
