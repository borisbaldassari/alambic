package Alambic::Plugins::JiraIts;

use strict;
use warnings;

use Alambic::Model::RepoFS;
use Alambic::Tools::R;

use Mojo::JSON qw( decode_json encode_json );
use Date::Parse;
use JIRA::REST;
use Time::Piece;
use Time::Seconds;
use Data::Dumper;

# Main configuration hash for the plugin
my %conf = (
    "id" => "JiraIts",
    "name" => "Jira",
    "desc" => [
	'The Jira plugin retrieves issue information from an Atlassian Jira server, using the <a href="https://developer.atlassian.com/jiradev/jira-apis/jira-rest-apis">Jira REST API</a>.',
	'See <a href="https://bitbucket.org/BorisBaldassari/alambic/wiki/Plugins/3.x/Jira">the project\'s wiki</a> for more information.',
    ],
    "type" => "pre",
    "ability" => [ 'info', 'metrics', 'data', 'figs', 'recs', 'viz' ],
    "params" => {
        "jira_url" => "The URL of the Jira server, e.g. http://myserver.",
        "jira_user" => "The user for authentication on the Jira server.",
        "jira_passwd" => "The password for authentication on the Jira server.",
        "jira_project" => "The project ID to be requested on the Jira server.",
    },
    "provides_cdata" => [
    ],
    "provides_info" => [
	"JIRA_SERVER",
    ],
    "provides_data" => {
	"import_jira.json" => "The original file of current information, downloaded from the Jira server (JSON).",
	"jira_evol.csv" => "The evolution of issues created and authors by day (CSV).",
	"jira_issues.csv" => "The list of issues, with fields 'id, summary, status, assignee, reporter, due_date, created_at, updated_at' (CSV).",
	"jira_issues_late.csv" => "The list of late issues (i.e. their due_date has past), with fields 'id, summary, status, assignee, reporter, due_date, created_at, updated_at' (CSV).",
	"jira_issues_open.csv" => "The list of open issues, with fields 'id, summary, status, assignee, reporter, due_date, created_at, updated_at' (CSV).",
	"jira_issues_open_unassigned.csv" => "The list of open and unassigned issues, with fields 'id, summary, status, assignee, reporter, due_date, created_at, updated_at' (CSV).",
    },
    "provides_metrics" => {
        "JIRA_VOL" => "JIRA_VOL",
        "JIRA_AUTHORS" => "JIRA_AUTHORS",
	"JIRA_AUTHORS_1W" => "JIRA_AUTHORS_1W",
	"JIRA_AUTHORS_1M" => "JIRA_AUTHORS_1M",
	"JIRA_AUTHORS_1Y" => "JIRA_AUTHORS_1Y",
	"JIRA_CREATED_1W" => "JIRA_CREATED_1W",
	"JIRA_CREATED_1M" => "JIRA_CREATED_1M",
	"JIRA_CREATED_1Y" => "JIRA_CREATED_1Y",
	"JIRA_UPDATED_1W" => "JIRA_UPDATED_1W",
	"JIRA_UPDATED_1M" => "JIRA_UPDATED_1M",
	"JIRA_UPDATED_1Y" => "JIRA_UPDATED_1Y",
        "JIRA_OPEN" => "JIRA_OPEN",
        "JIRA_OPEN_PERCENT" => "JIRA_OPEN_PERCENT",
        "JIRA_AUTHORS" => "JIRA_AUTHORS",
        "JIRA_LATE" => "JIRA_LATE",
        "JIRA_OPEN_UNASSIGNED" => "JIRA_OPEN_UNASSIGNED",
    },
    "provides_figs" => {
        'jira_summary.html' => "HTML summary of Jira issues main metrics (HTML)",
        'jira_evol_summary.html' => "Evolution of Jira main metrics (HTML)",
        'jira_evol_created.html' => "Evolution of Jira issues creation (HTML)",
        'jira_evol_authors.html' => "Evolution of Jira issues authors (HTML)",
    },
    "provides_recs" => [
	"JIRA_LATE_ISSUES",
    ],
    "provides_viz" => {
        "jira_its.html" => "Jira ITS",
    },
);

my $j_status_open = 'To Do';

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

    # Time::Piece object. Will be used for the date calculations.
    my $t_now = localtime;
    my $t_1w = $t_now - ONE_WEEK;
    my $t_1m = $t_now - ONE_MONTH;
    my $t_1y = $t_now - ONE_YEAR;

    my $jira_url = $conf->{'jira_url'};
    my $jira_user = $conf->{'jira_user'};
    my $jira_passwd = $conf->{'jira_passwd'};
    my $jira_project = $conf->{'jira_project'};

    my $jira = JIRA::REST->new({
        url      => $jira_url,
        username => $jira_user,
        password => $jira_passwd });

    $ret{'info'}{'JIRA_SERVER'} = $jira_url . "/projects/" . $jira_project . "/";


    # Iterate on issues
    push( @{$ret{'log'}}, "[Plugins::JiraIts] Retrieving information from [$jira_url].");
    my $search = $jira->POST('/search', undef, {
        jql        => 'project=' . $jira_project,
        startAt    => 0,
        maxResults => -1,
        fields     => [ qw/summary status assignee reporter created updated duedate/ ],
    });

    # Write json file to import directory
    $repofs->write_input( $project_id, "import_jira.json", encode_json($search->{'issues'}) );
    
    my (@late, @open, @unassigned_open, %people);
    my $csv = "id,summary,status,assignee,reporter,due_date,created_at,updated_at\n";
    my $csv_late = $csv;
    my $csv_open = $csv;
    my $csv_open_unassigned = $csv;
    
    my ($jira_created_1w, $jira_created_1m, $jira_created_1y) = (0,0,0);
    my ($jira_updated_1w, $jira_updated_1m, $jira_updated_1y) = (0,0,0);
    my (%authors, %authors_1w, %authors_1m, %authors_1y, %users);
    my %timeline_c;
    my %timeline_a;
    
    foreach my $issue (@{$search->{'issues'}}) {
	my $date = Time::Piece->strptime(str2time($issue->{'fields'}{'created'} || 0), "%s");
	my $date_m = $date->strftime("%Y-%m-%d");
	$timeline_c{$date_m}++;
	$timeline_a{$date_m}{$issue->{'fields'}{'reporter'}{'name'}}++;
	$authors{$issue->{'fields'}{'reporter'}{'name'}}++;
	
        if ($issue->{'fields'}{'status'}{'name'} eq $j_status_open) {
            push( @open, $issue->{'key'});
	    $csv_open .= $issue->{'key'} . ",\"" . $issue->{'fields'}{'summary'} . "\","
                . $issue->{'fields'}{'status'}{'name'} . ","
                . ($issue->{'fields'}{'assignee'}{'name'} || '') . ","
                . ($issue->{'fields'}{'reporter'}{'name'} || '') . ","
                . ($issue->{'fields'}{'duedate'} || '') . ","
                . ($issue->{'fields'}{'created'} || '') . ","
                . ($issue->{'fields'}{'updated'} || '')
                . "\n";
        }

        # Convert string dates to epoch seconds
        my $date_due = str2time($issue->{'fields'}{'duedate'}) if defined($issue->{'fields'}{'duedate'});
        my $date_created = str2time($issue->{'fields'}{'created'}) if defined($issue->{'fields'}{'created'});
        my $date_updated = str2time($issue->{'fields'}{'updated'}) if defined($issue->{'fields'}{'updated'});
        my $t_now = time();
	
        # Check if issue's due date has past
        if ( defined($date_due) and $date_due < $t_now ) {
            push( @late, $issue->{'key'} );
	    $csv_late .= $issue->{'key'} . ",\"" . $issue->{'fields'}{'summary'} . "\","
                . $issue->{'fields'}{'status'}{'name'} . ","
                . ($issue->{'fields'}{'assignee'}{'name'} || '') . ","
                . ($issue->{'fields'}{'reporter'}{'name'} || '') . ","
                . ($issue->{'fields'}{'duedate'} || '') . ","
                . ($issue->{'fields'}{'created'} || '') . ","
                . ($issue->{'fields'}{'updated'} || '')
                . "\n";
        }

        # Check if issue is assigned and open
        if ( (not defined($issue->{'fields'}{'assignee'}{'name'}))
              && $issue->{'fields'}{'status'}{'name'} eq $j_status_open ) {
            push( @unassigned_open, $issue->{'key'} );
	    $csv_open_unassigned .= $issue->{'key'} . ",\"" . $issue->{'fields'}{'summary'} . "\","
                . $issue->{'fields'}{'status'}{'name'} . ","
                . ($issue->{'fields'}{'assignee'}{'name'} || '') . ","
                . ($issue->{'fields'}{'reporter'}{'name'} || '') . ","
                . ($issue->{'fields'}{'duedate'} || '') . ","
                . ($issue->{'fields'}{'created'} || '') . ","
                . ($issue->{'fields'}{'updated'} || '')
                . "\n";
        }

        $csv .= $issue->{'key'} . ",\"" . $issue->{'fields'}{'summary'} . "\","
                . $issue->{'fields'}{'status'}{'name'} . ","
                . ($issue->{'fields'}{'assignee'}{'name'} || '') . ","
                . ($issue->{'fields'}{'reporter'}{'name'} || '') . ","
                . ($issue->{'fields'}{'duedate'} || '') . ","
                . ($issue->{'fields'}{'created'} || '') . ","
                . ($issue->{'fields'}{'updated'} || '')
                . "\n";

	# Populate %users to show activity in the user's profile
	if ( exists $issue->{'fields'}{'assignee'}{'emailAddress'} ) {
	    my $event = { 
		"type" => "issue_assigned", 
		"id" => $issue->{'key'},
		"msg" => $issue->{'fields'}{'summary'},
		"url" => $issue->{'self'}
	    };
	    push( @{$people{ $issue->{'fields'}{'assignee'}{'emailAddress'} }}, $event );
	}

	# Populate %users to show activity in the user's profile
	if ( exists $issue->{'fields'}{'reporter'}{'emailAddress'} ) {
	    my $event = { 
		"type" => "issue_created", 
		"id" => $issue->{'key'},
		"msg" => $issue->{'fields'}{'summary'},
		"url" => $issue->{'self'},
		"time" => $issue->{'created'}
	    };
	    push( @{$people{ $issue->{'fields'}{'reporter'}{'emailAddress'} }}, $event );
	}

	# Is the issue recent (<1W)?
	if ( $date_created > $t_1w->epoch ) {
	    $authors_1w{$issue->{'fields'}{'reporter'}{'name'}}++;
	    $jira_created_1w++;
	}
	# Is the issue recent (<1M)?
	if ( $date_created > $t_1m->epoch ) {
	    $authors_1m{$issue->{'fields'}{'reporter'}{'name'}}++;
	    $jira_created_1m++;
	}
	# Is the issue recent (<1Y)?
	if ( $date_created > $t_1y->epoch ) {
	    $authors_1y{$issue->{'fields'}{'reporter'}{'name'}}++;
	    $jira_created_1y++;
	}

	# Has the issue been closed recently (<1W)?
	if ( $date_updated > $t_1w->epoch ) {
	    $jira_updated_1w++;
	}
	# Has the issue been closed recently (<1M)?
	if ( $date_updated > $t_1m->epoch ) {
	    $jira_updated_1m++;
	}
	# Has the issue been closed recently (<1Y)?
	if ( $date_updated > $t_1y->epoch ) {
	    $jira_updated_1y++;
	}	
    }

    # Write metrics to csv and json files.
    $repofs->write_output( $project_id, "jira_issues.csv", $csv );
    $repofs->write_output( $project_id, "jira_issues_late.csv", $csv_late );
    $repofs->write_output( $project_id, "jira_issues_open.csv", $csv_open );
    $repofs->write_output( $project_id, "jira_issues_open_unassigned.csv", $csv_open_unassigned );

    # Compute and store metrics
    $ret{'metrics'}{'JIRA_VOL'} = scalar @{$search->{'issues'}};
    $ret{'metrics'}{'JIRA_AUTHORS'} = scalar keys %authors;
    $ret{'metrics'}{'JIRA_OPEN'} = scalar @open;
    $ret{'metrics'}{'JIRA_OPEN_PERCENT'} = sprintf( 
	"%.0f", 100 * (scalar @open) / (scalar @{$search->{'issues'}}) 
	);
    $ret{'metrics'}{'JIRA_LATE'} = scalar @late;
    $ret{'metrics'}{'JIRA_OPEN_UNASSIGNED'} = scalar @unassigned_open;
    $ret{'metrics'}{'JIRA_AUTHORS_1W'} = scalar keys %authors_1w;
    $ret{'metrics'}{'JIRA_AUTHORS_1M'} = scalar keys %authors_1m;
    $ret{'metrics'}{'JIRA_AUTHORS_1Y'} = scalar keys %authors_1y;
    $ret{'metrics'}{'JIRA_CREATED_1W'} = $jira_created_1w;
    $ret{'metrics'}{'JIRA_CREATED_1M'} = $jira_created_1m;
    $ret{'metrics'}{'JIRA_CREATED_1Y'} = $jira_created_1y;
    $ret{'metrics'}{'JIRA_UPDATED_1W'} = $jira_updated_1w;
    $ret{'metrics'}{'JIRA_UPDATED_1M'} = $jira_updated_1m;
    $ret{'metrics'}{'JIRA_UPDATED_1Y'} = $jira_updated_1y;

    # Set user information for profile
    push( @{$ret{'log'}}, "[Plugins::JiraIts] Writing user events file." );
    my $events = {};
    foreach my $u (sort keys %people) {
	$events->{$u} = $people{$u};
    }
    $repofs->write_users( "JiraIts", $project_id, $events );

    # Write jira metrics json file to disk.
    $repofs->write_output( $project_id, "metrics_jira.json", encode_json($ret{'metrics'}) );

    # Write jira metrics csv file
    my @metrics = sort map {$conf{'provides_metrics'}{$_}} keys %{$conf{'provides_metrics'}};
    my $csv_out = join( ',', sort keys %{$ret{'metrics'}}) . "\n";
    $csv_out .= join( ',', map { $ret{'metrics'}{$_} || '' } sort keys %{$ret{'metrics'}}) . "\n";
    $repofs->write_plugin( 'JiraIts', $project_id . "_jira.csv", $csv_out );
    $repofs->write_output( $project_id, "metrics_jira.csv", $csv_out );

    # Write commits history json file to disk.
    my %timeline = (%timeline_a, %timeline_c);
    my @timeline = map { $_ . "," . $timeline_c{$_} . "," . scalar(keys %{$timeline_a{$_}}) } sort keys %timeline;
    $csv_out = "date,issues_created,authors\n";
    $csv_out .= join( "\n", @timeline) . "\n";
    $repofs->write_plugin( 'JiraIts', $project_id . "_jira_evol.csv", $csv_out );
    $repofs->write_output( $project_id, "jira_evol.csv", $csv_out );

    # Now execute the main R script.
    push( @{$ret{'log'}}, "[Plugins::JiraIts] Executing R main file." );
    my $r = Alambic::Tools::R->new();
    @{$ret{'log'}} = ( @{$ret{'log'}}, @{$r->knit_rmarkdown_inc( 'JiraIts', $project_id, 'jira_its.Rmd' )} );

    # And execute the figures R scripts.
    @{$ret{'log'}} = ( @{$ret{'log'}}, 
		       @{$r->knit_rmarkdown_html( 'JiraIts', $project_id, 'jira_evol_authors.rmd',
						  [ 'jira_evol_authors.png', 'jira_evol_authors.svg' ] )} );
    @{$ret{'log'}} = ( @{$ret{'log'}}, 
		       @{$r->knit_rmarkdown_html( 'JiraIts', $project_id, 'jira_evol_created.rmd',
						  [ 'jira_evol_created.png', 'jira_evol_created.svg'] )} );
    @{$ret{'log'}} = ( @{$ret{'log'}}, 
		       @{$r->knit_rmarkdown_html( 'JiraIts', $project_id, 'jira_evol_summary.rmd',
						  [] )} );
    @{$ret{'log'}} = ( @{$ret{'log'}}, 
		       @{$r->knit_rmarkdown_html( 'JiraIts', $project_id, 'jira_summary.rmd',
						  [] )} );

    # Recommendation for late issues
    if (scalar @late) {
	push( @{$ret{'recs'}}, 
	      { 'rid' => 'JIRA_LATE_ISSUES', 
		'severity' => 2,
		'src' => 'JiraIts',
		'desc' => 'There are ' . scalar @late
		    . ' issues with a past due date. Either re-plan them or mark them done.' 
	      } 
	    );
    }
    
    return \%ret;
}



1;
