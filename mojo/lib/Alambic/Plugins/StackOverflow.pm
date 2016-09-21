package Alambic::Plugins::StackOverflow;

use strict;
use warnings;

use Alambic::Model::RepoFS;
use Alambic::Tools::R;

use Mojo::JSON qw( decode_json encode_json );
use Mojo::UserAgent;
use Data::Dumper;
use File::Copy;
use File::Path qw(remove_tree);
use DateTime;

my %conf = (
    "id" => "StackOverflow",
    "name" => "Stack Overflow",
    "desc" => [
	"Retrieves questions and answers related to a specific tag from the Stack Overflow question/answer web site.",
	"The analysed time range spans the last 5 years.",
        "Check the documentation for this plugin on the project wiki: <a href=\"https://bitbucket.org/BorisBaldassari/alambic/wiki/Plugins/3.x/StackOverflow\">https://bitbucket.org/BorisBaldassari/alambic/wiki/Plugins/3.x/StackOverflow</a>."
    ],
    "type" => "pre",
    "ability" => [ 'metrics', 'recs', 'figs', 'viz' ],
    "params" => {
        "so_keyword" => "A Stack Overflow tag to retrieve questions from.",
    },
    "provides_cdata" => [
    ],
    "provides_info" => [
    ],
    "provides_data" => {
	"so.json" => "The list of questions and answers for the project, in JSON format.",
	"so.csv" => "The list of questions and answers for the project, in CSV format.",
    },
    "provides_metrics" => {
    },
    "provides_figs" => {
    },
    "provides_recs" => [
        "SO_RULE_DEL",
        "SO_FIX_RULE",
    ],
    "provides_viz" => {
        "stack_overflow" => "Stack Overflow",
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

    my $so_keyword = $conf->{'so_keyword'};

    # Retrieve and store data from the remote repository.
    $ret{'log'} = &_retrieve_data( $project_id, $so_keyword, $repofs );

    # Analyse retrieved data, generate info, metrics, plots and visualisation.
    my $tmp_ret = &_compute_data( $project_id, $repofs );
    
    $ret{'metrics'} = $tmp_ret->{'metrics'};
    $ret{'recs'} = $tmp_ret->{'recs'};
    push( @{$ret{'log'}}, @{$tmp_ret->{'log'}} );
    
    return \%ret;
}


sub _retrieve_data() {
    my ( $project_id, $so_keyword, $repofs ) = @_;
    
    my @log;

    # URL for SO API access.
    my $url = 'https://api.stackexchange.com/2.2/';

    # Compute date for the time range (5 years)
    my $date_now = DateTime->now( time_zone => 'local' );
    my $date_before = DateTime->now( time_zone => 'local' )->subtract( years => 5 );
    my $date_before_ok = $date_before->strftime("%Y-%m-%d");

    my $content_json;
    my %final_json;
    
    my ( $quota_max, $quota_remaining );
    
    my $continue = 50;
    my $page = 1;

    # Read pages (100 items per page) from the SO API.
    while ($continue) {
        my $url_question = $url . "questions?order=desc&sort=activity&site=stackoverflow" 
            . "&tagged=" . $so_keyword . "&fromdate=${date_before_ok}"
            . "&pagesize=100&page=" . $page;
        
        push( @log, "[Plugins::StackOverflow] Fetching $url_question." );
        
        # Fetch JSON data from SO
        my $ua = Mojo::UserAgent->new;
        $content_json = $ua->get($url_question)->res->body;
        
        # Decode the json we got and add items to our set.
        my $content = decode_json( $content_json );
        
        foreach my $item ( @{$content->{'items'} } ) {
            $final_json{'items'}{ $item->{'question_id'} } = $item;
        }
        
        $page++;
        
        # Check if there are other pages.
        if ( $content->{'has_more'} ) {
            $continue--;
        } else {
            $continue = 0;
        }
        
        $quota_max = $content->{'quota_max'};
        $quota_remaining = $content->{'quota_remaining'};
    }
    my @items = keys %{$final_json{'items'}};
    push( @log, "[Plugins::StackOverflow] Fetched data from SO. Got " . scalar @items . " items." );
    
    my $json_out = encode_json( \%final_json );
    
    push( @log, "[Plugins::StackOverflow] Writing questions to JSON file." );
    $repofs->write_input( $project_id, "import_so.json", $json_out );
    $repofs->write_output( $project_id, "so.json", $json_out );
        
    push( @log, "[Plugins::StackOverflow] Quota: remaining $quota_remaining out of $quota_max." );

    return \@log;
}

sub _compute_data() {
    my ( $project_id, $repofs ) = @_;

    my %metrics;
    my @recs;
    my @log;
    
    push( @log, "[Plugins::StackOverflow] Starting compute data for [$project_id]." );

    # Compute dates to limit time range.
    my $date_now = DateTime->now( time_zone => 'local' );
    my $date_before = DateTime->now( time_zone => 'local' )->subtract( years => 5 );
    my $date_before_ok = $date_before->strftime("%Y-%m-%d");

    # Read file retrieved from repo and decode json.
    my $content_json = $repofs->read_input( $project_id, "import_so.json" );
    my $content = decode_json( $content_json );

    # Produce a CSV file with all information. Easier to read in R.
    my $csv_out = "id,views,score,creation_date,last_activity_date,answer_count,is_answered,title\n";;
    foreach my $id ( sort keys %{$content->{'items'}} ) {
        my $views = $content->{'items'}->{$id}->{'view_count'};
        my $score = $content->{'items'}->{$id}->{'score'};
        my $creation_date = $content->{'items'}->{$id}->{'creation_date'};
        my $last_activity_date = $content->{'items'}->{$id}->{'last_activity_date'};
        my $answer_count = $content->{'items'}->{$id}->{'answer_count'};
        my $is_answered = $content->{'items'}->{$id}->{'is_answered'};
        my $title = $content->{'items'}->{$id}->{'title'};
        $title =~ s!,!!g;    
        
        $csv_out .= "$id,$views,$score,$creation_date,$last_activity_date,$answer_count,$is_answered,$title\n";
    }
    # Write that to csv in plugins folder (for R treatment) and output (for download).
    $repofs->write_plugin( 'StackOverflow', $project_id . "_so.csv", $csv_out );
    $repofs->write_output( $project_id, "so.csv", $csv_out );
    
    # Now execute the main R script.
    push( @log, "[Plugins::StackOverflow] Executing R main file." );
    my $r = Alambic::Tools::R->new();
    @log = ( @log, @{$r->knit_rmarkdown_inc( 'StackOverflow', $project_id, 'stack_overflow.Rmd' )} );    
    
    return {
	"metrics" => \%metrics,
	"recs" => \@recs,
	"log" => \@log,
    };
}

1;
