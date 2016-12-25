package Alambic::Plugins::EclipseIts;

use strict; 
use warnings;

use Alambic::Model::RepoFS;
use Alambic::Tools::R;

use Mojo::JSON qw( decode_json encode_json );
use Mojo::UserAgent;
use Data::Dumper;

# Main configuration hash for the plugin
my %conf = (
    "id" => "EclipseIts",
    "name" => "Eclipse ITS",
    "desc" => [
	'Eclipse ITS retrieves bug tracking system data from the Eclipse dashboard repository. This plugin will look for a file named project-its-prj-static.json on <a href="http://dashboard.eclipse.org/data/json/">the Eclipse dashboard</a>.',
	'See <a href="https://bitbucket.org/BorisBaldassari/alambic/wiki/Plugins/3.x/EclipseIts">the project\'s wiki</a> for more information.',
    ],
    "type" => "pre",
    "ability" => [ 'metrics', 'data', 'recs', 'figs', 'viz' ],
    "params" => {
        "project_grim" => "The ID used to identify the project on the dashboard server. Note that it may be different from the id used in the PMI.",
    },
    "provides_cdata" => [
    ],
    "provides_info" => [
    ],
    "provides_data" => {
	"import_its.json" => "The original file of current metrics downloaded from the Eclipse dashboard server (JSON).",
	"metrics_its.json" => "Current metrics for the ITS plugin (JSON).",
	"metrics_its.csv" => "Current metrics for the ITS plugin (CSV).",
	"metrics_its_evol.json" => "Evolution metrics for the ITS plugin (JSON).",
	"metrics_its_evol.csv" => "Evolution metrics for the ITS plugin (CSV).",
    },
    "provides_metrics" => {
        "CHANGED" => "ITS_CHANGED", 
        "CHANGERS" => "ITS_CHANGERS", 
        "CLOSED" => "ITS_CLOSED", 
        "CLOSED_30" => "ITS_CLOSED_30", 
        "CLOSED_365" => "ITS_CLOSED_365", 
        "CLOSED_7" => "ITS_CLOSED_7",
        "DIFF_NETCLOSED_30" => "ITS_DIFF_NETCLOSED_30", 
        "DIFF_NETCLOSED_365" => "ITS_DIFF_NETCLOSED_365", 
        "DIFF_NETCLOSED_7" => "ITS_DIFF_NETCLOSED_7",
        "PERCENTAGE_CLOSED_30" => "ITS_PERCENTAGE_CLOSED_30", 
        "PERCENTAGE_CLOSED_365" => "ITS_PERCENTAGE_CLOSED_365",
        "PERCENTAGE_CLOSED_7" => "ITS_PERCENTAGE_CLOSED_7", 
        "CLOSERS" => "ITS_CLOSERS", 
        "CLOSERS_30" => "ITS_CLOSERS_30", 
        "CLOSERS_365" => "ITS_CLOSERS_365", 
        "CLOSERS_7" => "ITS_CLOSERS_7", 
        "DIFF_NETCLOSERS_30" => "ITS_DIFF_NETCLOSERS_30", 
        "DIFF_NETCLOSERS_365" => "ITS_DIFF_NETCLOSERS_365", 
        "DIFF_NETCLOSERS_7" => "ITS_DIFF_NETCLOSERS_7", 
        "PERCENTAGE_CLOSERS_30" => "ITS_PERCENTAGE_CLOSERS_30", 
        "PERCENTAGE_CLOSERS_365" => "ITS_PERCENTAGE_CLOSERS_365", 
        "PERCENTAGE_CLOSERS_7" => "ITS_PERCENTAGE_CLOSERS_7", 
        "TRACKERS" => "ITS_TRACKERS", 
        "OPENED" => "ITS_OPENED", 
        "OPENERS" => "ITS_OPENERS", 
    },
    "provides_figs" => {
        'its_evol_summary.rmd' => "its_evol_summary.html",
        'its_evol_changed.rmd' => "its_evol_changed.html",
        'its_evol_opened.rmd' => "its_evol_opened.html",
        'its_evol_people.rmd' => "its_evol_people.html",
    },
    "provides_recs" => [
        "ITS_OPEN_BUGS",
        "ITS_CLOSERS",
    ],
    "provides_viz" => {
        "eclipse_its.html" => "Eclipse ITS",
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
	. $project_grim . "-its-prj-static.json";

    push( @log, "[Plugins::EclipseIts] Starting retrieval of data for [$project_id] url [$url]." );
    
    # Fetch json file from the dashboard.eclipse.org
    my $ua = Mojo::UserAgent->new;
    my $content = $ua->get($url)->res->body;
    if (length($content) < 10) {
	push( @log, "[Plugins::EclipseIts] Cannot find [$url].\n" ) ;
    } else {
	$repofs->write_input( $project_id, "import_its.json", $content );
	$repofs->write_output( $project_id, "import_its.json", $content );
    }

    $url = "http://dashboard.eclipse.org/data/json/" 
            . $project_grim . "-its-prj-evolutionary.json";
    
    push( @log, "[Plugins::EclipseIts] Retrieving evol [$url] to input.\n" );
    
    # Fetch json file from the dashboard.eclipse.org
    $ua = Mojo::UserAgent->new;
    $content = $ua->get($url)->res->body;
    if (length($content) < 10) {
	push( @log, "[Plugins::EclipseIts] Cannot find [$url].\n" ) ;
    } else {
	$repofs->write_input( $project_id, "import_its_evol.json", $content );
	$repofs->write_output( $project_id, "metrics_its_evol.json", $content );
    }

    return \@log;
}


# Basically read the imported files and make the mapping to the 
# new metric names.
sub _compute_data($$$) {
    my ($project_id, $project_pmi, $repofs) = @_;

    my @recs;
    my @log;
    
    push( @log, "[Plugins::EclipseIts] Starting compute data for [$project_id]." );

    my $metrics_new;

    # Read data from its file in $data_input
    my $json = $repofs->read_input( $project_id, "import_its.json" );
    my $metrics_old = decode_json($json);

    foreach my $metric (keys %{$metrics_old}) {
        if ( exists( $conf{'provides_metrics'}{uc($metric)} ) ) {
            $metrics_new->{ $conf{'provides_metrics'}{uc($metric)} } = $metrics_old->{$metric};
        }
    }
    
    # Write its metrics json file to disk.
    $repofs->write_output( $project_id, "metrics_its.json", encode_json($metrics_new) );

    # Write static metrics file
    my @metrics = sort map {$conf{'provides_metrics'}{$_}} keys %{$conf{'provides_metrics'}};
    my $csv_out = join( ',', sort @metrics) . "\n";
    $csv_out .= join( ',', map { $metrics_new->{$_} } sort @metrics) . "\n";
    
    $repofs->write_plugin( 'EclipseIts', $project_id . "_its.csv", $csv_out );
    $repofs->write_output( $project_id, "metrics_its.csv", $csv_out );
    
    # Read evol metrics file
    $json = $repofs->read_input( $project_id, "import_its_evol.json" );
    my $metrics_evol = decode_json($json);

    # Create csv data for evol
    $csv_out = "date,changed,changers,closed,closers,opened,openers,trackers,unixtime\n";
    foreach my $id ( 0 .. (scalar(@{$metrics_evol->{'date'}}) -1 ) ) {
	$csv_out .= $metrics_evol->{'date'}->[$id] . ',';
	$csv_out .= $metrics_evol->{'changed'}->[$id] . ',';
	$csv_out .= $metrics_evol->{'changers'}->[$id] . ',';
	$csv_out .= $metrics_evol->{'closed'}->[$id] . ',';
	$csv_out .= $metrics_evol->{'closers'}->[$id] . ',';
	$csv_out .= $metrics_evol->{'opened'}->[$id] . ',';
	$csv_out .= $metrics_evol->{'openers'}->[$id] . ',';
	$csv_out .= $metrics_evol->{'trackers'}->[$id] . ',';
	$csv_out .= $metrics_evol->{'unixtime'}->[$id] . "\n";
    }
    $repofs->write_plugin( 'EclipseIts', $project_id . "_its_evol.csv", $csv_out );
    $repofs->write_output( $project_id, "metrics_its_evol.csv", $csv_out );

    # Now execute the main R script.
    push( @log, "[Plugins::EclipseIts] Executing R main file." );
    my $r = Alambic::Tools::R->new();
    @log = ( @log, @{$r->knit_rmarkdown_inc( 'EclipseIts', $project_id, 'eclipse_its.Rmd' )} );

    # And execute the figures R scripts.
    my @figs = grep( /.*\.rmd$/i, keys %{$conf{'provides_figs'}} );
    foreach my $fig (sort @figs) {
	push( @log, "[Plugins::EclipseIts] Executing R fig file [$fig]." );
	@log = ( @log, @{$r->knit_rmarkdown_html( 'EclipseIts', $project_id, $fig )} );
    }

    
    # Execute checks and fill recs.

    # Check number of open bugs.
    # If there are at least twice as many opened bugs as closed bugs, raise an alert.
    my $weeks = -4;
    my $closed_old = $metrics_evol->{'closed'}->[$weeks];
    my $opened_old = $metrics_evol->{'opened'}->[$weeks];
    if ( $closed_old < ( 2 * $opened_old) ) {
	push( @recs, { 'rid' => 'ITS_OPENED_BUGS', 
		       'severity' => 1,
		       'src' => 'EclipseIts',
		       'desc' => 'During last 4 weeks, there has been twice as many opened bugs (' 
			   . $opened_old . ') as closed bugs (' . $closed_old . '). This may be ok '
			   . 'if the activity has notably increased, but it could also reveal some '
			   . 'instability or decrease in project quality.' 
	      } 
	    );
    }
    
    # Check the number of closers.
    # If there are less closers than last year, raise an alert.
    if ($metrics_new->{'ITS_DIFF_NETCLOSERS_365'} < 0) {
	push( @recs, { 'rid' => 'ITS_CLOSERS', 
		       'severity' => 1,
		       'src' => 'EclipseIts',
		       'desc' => 'During past year, the number of people closing issues has '
			   . ' fallen by ' . $metrics_new->{'ITS_DIFF_NETCLOSERS_365'}
		           . '. This usually means a decrease in project diversity and activity.' 
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
