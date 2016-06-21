package Alambic::Plugins::EclipseScm;

use strict; 
use warnings;

use Alambic::Model::RepoFS;
use Alambic::Tools::R;

use Mojo::JSON qw( decode_json encode_json );
use Mojo::UserAgent;
use Data::Dumper;

# Main configuration hash for the plugin
my %conf = (
    "id" => "EclipseScm",
    "name" => "Eclipse SCM",
    "desc" => [ 
	"Retrieves configuration management data from the Eclipse dashboard repository. This plugin will look for a file named project-scm-prj-static.json on http://dashboard.eclipse.org/data/json/. This plugin is redundant with the EclipseGrimoire plugin",
    ],
    "type" => "pre",
    "ability" => [ 'metrics', 'recs', 'figs', 'viz' ],
    "params" => {
        "project_id" => "",
    },
    "provides_cdata" => [
    ],
    "provides_info" => [
    ],
    "provides_data" => {
    },
    "provides_metrics" => {
        "AUTHORS" => "SCM_AUTHORS", 
        "AUTHORS_7" => "SCM_AUTHORS_7",
        "AUTHORS_30" => "SCM_AUTHORS_30", 
        "AUTHORS_365" => "SCM_AUTHORS_365", 
        "DIFF_NETAUTHORS_7" => "SCM_DIFF_NETAUTHORS_7",
        "DIFF_NETAUTHORS_30" => "SCM_DIFF_NETAUTHORS_30", 
        "DIFF_NETAUTHORS_365" => "SCM_DIFF_NETAUTHORS_365", 
        "PERCENTAGE_AUTHORS_7" => "SCM_PERCENTAGE_AUTHORS_7",
        "PERCENTAGE_AUTHORS_30" => "SCM_PERCENTAGE_AUTHORS_30", 
        "PERCENTAGE_AUTHORS_365" => "SCM_PERCENTAGE_AUTHORS_365", 
        "AVG_COMMITS_AUTHOR" => "SCM_AVG_COMMITS_AUTHOR",
        "AVG_COMMITS_MONTH" => "SCM_AVG_COMMITS_MONTH",
        "COMMITS" => "SCM_COMMITS", 
        "COMMITS_7" => "SCM_COMMITS_7", 
        "COMMITS_30" => "SCM_COMMITS_30",
        "COMMITS_365" => "SCM_COMMITS_365",
        "DIFF_NETCOMMITS_7" => "SCM_DIFF_NETCOMMITS_7", 
        "DIFF_NETCOMMITS_30" => "SCM_DIFF_NETCOMMITS_30",
        "DIFF_NETCOMMITS_365" => "SCM_DIFF_NETCOMMITS_365",
        "PERCENTAGE_COMMITS_7" => "SCM_PERCENTAGE_COMMITS_7", 
        "PERCENTAGE_COMMITS_30" => "SCM_PERCENTAGE_COMMITS_30",
        "PERCENTAGE_COMMITS_365" => "SCM_PERCENTAGE_COMMITS_365",
        "COMMITTERS" => "SCM_COMMITTERS",
        "FILES" => "SCM_FILES", 
        "REPOSITORIES" => "SCM_REPOSITORIES",
    },
    "provides_figs" => {
        'scm_evol_summary.rmd' => "scm_evol_summary.html",
        'scm_evol_lines.rmd' => "scm_evol_lines.html",
        'scm_evol_people.rmd' => "scm_evol_people.html",
        'scm_evol_commits.rmd' => "scm_evol_commits.html",
    },
    "provides_recs" => [
        "SCM_CLOSE_BUGS",
    ],
    "provides_viz" => {
        "eclipse_scm" => "Eclipse SCM",
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

    my $repofs = Alambic::Model::RepoFS->new();

    my $project_grim = $conf->{'project_grim'};

    $ret{'log'} = &_retrieve_data( $project_id, $project_grim, $repofs );
    
    my $tmp_ret = &_compute_data( $project_id, $project_grim, $repofs );
    
    $ret{'metrics'} = $tmp_ret->{'metrics'};
    $ret{'recs'} = $tmp_ret->{'recs'};
    push( @{$ret{'log'}}, @{$tmp_ret->{'log'}} );
    
    return \%ret;
}

sub _retrieve_data($) {
    my ($project_id, $project_grim, $repofs) = @_;
    
    my @log;

    my $url = "http://dashboard.eclipse.org/data/json/" 
            . $project_grim . "-scm-prj-static.json";

    push( @log, "[Plugins::EclipseMls] Starting retrieval of data for [$project_id] url [$url]." );
    
    # Fetch json file from the dashboard.eclipse.org
    my $ua = Mojo::UserAgent->new;
    my $content = $ua->get($url)->res->body;
    if (length($content) < 10) { 
	push( @log, "Cannot find [$url].\n" ) ;
    } else {
	$repofs->write_input( $project_id, "import_scm.json", $content );
	$repofs->write_output( $project_id, "import_scm.json", $content );
    }
    
    $url = "http://dashboard.eclipse.org/data/json/" 
            . $project_grim . "-scm-prj-evolutionary.json";
    
    push( @log, "[Plugins::EclipseMls] Retrieving evol [$url] to input.\n" );
    
    # Fetch json file from the dashboard.eclipse.org
    $ua = Mojo::UserAgent->new;
    $content = $ua->get($url)->res->body;
    if (length($content) < 10) {
	push( @log, "Cannot find [$url].\n" ) ;
    } else {
	$repofs->write_input( $project_id, "import_scm_evol.json", $content );
	$repofs->write_output( $project_id, "import_scm_evol.json", $content );
    }

    return \@log;
}


sub _compute_data($) {
    my ($project_id, $project_pmi, $repofs) = @_;

    my @recs;
    my @log;

    push( @log, "[Plugins::EclipseScm] Starting compute data for [$project_id]." );

    my $metrics_new;
    
    # Read data from its file in $data_input
    my $json = $repofs->read_input( $project_id, "import_its.json" );
    my $metrics_old = decode_json($json);

    foreach my $metric (keys %{$metrics_old}) {
        if ( exists( $conf{'provides_metrics'}{uc($metric)} ) ) {
            $metrics_new->{ $conf{'provides_metrics'}{uc($metric)} } = $metrics_old->{$metric};
        }
    }

    # TODO Execute checks and fill recs.
    if ( ( $metrics_new->{'ITS_OPENED'} || '' ) > 10) {
	push( @recs, { 'rid' => 'ITS_CLOSE_BUGS', 
		       'severity' => 1, 
		       'desc' => 'There are ' . $metrics_new->{'ITS_OPENED'} 
		       . ' issues still open. You could watch them and sort them out.' 
	      } 
	    );
    }
    
    # Write its metrics json file to disk.
    $repofs->write_output( $project_id, "metrics_scm.json", encode_json($metrics_new) );

    # Write static metrics file
    my @metrics = sort map {$conf{'provides_metrics'}{$_}} keys %{$conf{'provides_metrics'}};
    my $csv_out = join( ',', sort @metrics) . "\n";
    $csv_out .= join( ',', map { $metrics_new->{$_} || '' } sort @metrics) . "\n";
    
    $repofs->write_plugin( 'EclipseIts', $project_id . "_its.csv", $csv_out );
    
    # Read evol metrics file
    $json = $repofs->read_input( $project_id, "import_its_evol.json" );
    my $metrics_evol = decode_json($json);

    # Create csv data for evol
    $csv_out = "date,id,authors,added_lines,removed_lines,commits,committers,repositories,unixtime\n";
    foreach my $id ( 0 .. (scalar(@{$metrics_evol->{'date'}}) -1 ) ) {
	$csv_out .= ( $metrics_evol->{'date'}->[$id] || '' ) . ',';
	$csv_out .= ( $metrics_evol->{'id'}->[$id] || '' ) . ',';
	$csv_out .= ( $metrics_evol->{'authors'}->[$id] || '' ) . ',';
	$csv_out .= ( $metrics_evol->{'added_lines'}->[$id] || '' ) . ',';
	$csv_out .= ( $metrics_evol->{'removed_lines'}->[$id] || '' ) . ',';
	$csv_out .= ( $metrics_evol->{'commits'}->[$id] || '' ) . ',';
	$csv_out .= ( $metrics_evol->{'committers'}->[$id] || '' ) . ',';
	$csv_out .= ( $metrics_evol->{'repositories'}->[$id] || '' ) . ',';
	$csv_out .= ( $metrics_evol->{'unixtime'}->[$id] || '' ) . "\n";
    }
    $repofs->write_plugin( 'EclipseIts', $project_id . "_scm_evol.csv", $csv_out );
    $repofs->write_output( $project_id, "scm_evol.csv", $csv_out );

    # Now execute the main R script.
    push( @log, "[Plugins::EclipseScm] Executing R main file." );
    my $r = Alambic::Tools::R->new();
    @log = ( @log, @{$r->knit_rmarkdown_inc( 'EclipseScm', $project_id, 'eclipse_scm.Rmd' )} );

    # And execute the figures R scripts.
    my @figs = grep( /.*\.rmd$/i, keys %{$conf{'provides_figs'}} );
    foreach my $fig (sort @figs) {
	push( @log, "[Plugins::EclipseScm] Executing R fig file [$fig]." );
	@log = ( @log, @{$r->knit_rmarkdown_html( 'EclipseScm', $project_id, $fig )} );
    }
    
    return {
	"metrics" => $metrics_new,
	"recs" => \@recs,
	"log" => \@log,
    };
}


1;
