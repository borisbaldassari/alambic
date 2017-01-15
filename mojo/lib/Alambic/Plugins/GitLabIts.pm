package Alambic::Plugins::GitLabIts;

use strict; 
use warnings;

use Alambic::Model::RepoFS;

use GitLab::API::v3;
use Mojo::JSON qw( decode_json encode_json );
use Date::Parse;
use Time::Piece;
use Time::Seconds;
use Data::Dumper;

# Main configuration hash for the plugin
my %conf = (
    "id" => "GitLabIts",
    "name" => "GitLab ITS",
    "desc" => [
	'This plugin retrieves Issue Tracking Information from a GitLab server',
	'qsf',
    ],
    "type" => "pre",
    "ability" => [ 'metrics', 'data', 'recs', 'figs', 'viz' ],
    "params" => {
        "gitlab_url" => "The URL of the GitLab instance, e.g. http://mygitlab.mycompany.com.",
        "gitlab_id" => "The ID used to identify the project in the GitLab forge.",
        "gitlab_token" => "The private token used to access the gitlab instance. The private token must be generated by a user who has global rights on all analysed projects. It is generated, downlaoded and reset from the user's account page (/profile/account).",
    },
    "provides_cdata" => [
    ],
    "provides_info" => [
    ],
    "provides_data" => {
	"import_its.json" => "Original JSON file as retrieved from the GitLab server (JSON).",
	"its_issues.json" => "Restricted set of issues extracted from the server for metrics calculation (JSON).",
    },
    "provides_metrics" => {
        "ITS_CHANGED_1W" => "ITS_CHANGED_1W", 
        "ITS_CHANGED_1M" => "ITS_CHANGED_1M", 
        "ITS_CHANGED_1Y" => "ITS_CHANGED_1Y", 
        "ITS_CREATED_1W" => "ITS_CREATED_1W", 
        "ITS_CREATED_1M" => "ITS_CREATED_1M", 
        "ITS_CREATED_1Y" => "ITS_CREATED_1Y", 
	"ITS_ISSUES_OPEN" => "ITS_ISSUES_OPEN",
	"ITS_ISSUES_CLOSED" => "ITS_ISSUES_CLOSED",
	"ITS_ISSUES_ALL" => "ITS_ISSUES_ALL",
	"ITS_ISSUES_LATE" => "ITS_ISSUES_LATE",
	"ITS_ISSUES_UNASSIGNED" => "ITS_ISSUES_UNASSIGNED",
	"ITS_TOTAL_DOWNVOTES" => "ITS_TOTAL_DOWNVOTES",
	"ITS_TOTAL_UPVOTES" => "ITS_TOTAL_UPVOTES",
	"ITS_AUTHORS" => "ITS_AUTHORS",
	"ITS_PEOPLE" => "ITS_PEOPLE",
    },
    "provides_figs" => {
#        'its_evol_summary.rmd' => "its_evol_summary.html",
    },
    "provides_recs" => [
        "ITS_LONG_STANDING_OPEN",
    ],
    "provides_viz" => {
#        "gitlab_its.html" => "GitLab ITS",
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

    my $gl_url = $conf->{'gitlab_url'};
    my $gl_id = $conf->{'gitlab_id'};
    my $gl_token = $conf->{'gitlab_token'};
    
    push( @{$ret{'log'}}, "[Plugins::GitLabIts] Retrieving data from [$gl_url] for project [$gl_id]." ); 

    # Create GitLab API object for all rest operations.
    my $api = GitLab::API::v3->new(
        url   => $gl_url . "/api/v3",
        token => $gl_token,
	);
    # Request information about issues for this specific project.
    my $issues_p = $api->paginator( 'issues', $gl_id );
    my $issues;
    while (my $issue = $issues_p->next()) {
        push( @$issues, $issue );
    }
    
    # Write the original file to disk.
    my $project_json = encode_json($issues);
    $repofs->write_output( $project_id, "import_its.json", $project_json );
    my $issues_vol = scalar @$issues;

    # Store all issues in our own array
    my @issues_f;
    
    # Will contain metrics and aggregated information.
    my ($issues_closed, $issues_open, 
	$issues_created_1w, $issues_created_1m, $issues_created_1y,
	$issues_changed_1w, $issues_changed_1m, $issues_changed_1y,
	$total_upvotes, $total_downvotes) = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
    my (@issues_unassigned, @issues_late);
    my (%milestones, %authors, %people);

    # Time::Piece object. Will be used for the date calculations.
    my $t_now = localtime;
    my $t_1w = $t_now - ONE_WEEK;
    my $t_1m = $t_now - ONE_MONTH;
    my $t_1y = $t_now - ONE_YEAR;
    
    foreach my $issue (@$issues) {

	my %issues_l;
	$issues_l{'id'} = $issue->{'iid'};
	$issues_l{'title'} = $issue->{'title'};
	$issues_l{'web_url'} = $issue->{'web_url'};
	$issues_l{'state'} = $issue->{'state'};
	$issues_l{'upvotes'} = $issue->{'upvotes'};
	$issues_l{'downvotes'} = $issue->{'downvotes'};
	$issues_l{'created_at'} = $issue->{'created_at'};
	$issues_l{'updated_at'} = $issue->{'updated_at'};
	$issues_l{'due_date'} = $issue->{'due_date'};
	$issues_l{'user_notes_count'} = $issue->{'user_notes_count'};

	# Convert string dates to epoch seconds
	my $date_created = str2time($issue->{'created_at'});
	my $date_changed = str2time($issue->{'updated_at'});
	my $date_due = str2time($issue->{'due_date'});

	# Compute/set metrics
	$total_upvotes += $issue->{'upvotes'};
	$total_downvotes += $issue->{'downvotes'};

	# Check if issue's due date has past
	if ( defined($date_due) and $date_due < $t_now->epoch ) { 
	    push( @issues_late, $issue->{'iid'} ); 
	}

	$issues_created_1w++ if ( $date_created > $t_1w->epoch );
	$issues_created_1m++ if ( $date_created > $t_1m->epoch );
	$issues_created_1y++ if ( $date_created > $t_1y->epoch );

	$issues_changed_1w++ if ( $date_changed > $t_1w->epoch );
	$issues_changed_1m++ if ( $date_changed > $t_1m->epoch );
	$issues_changed_1y++ if ( $date_changed > $t_1y->epoch );

	
	
	# Track milestones information
	if ( defined( $issue->{'milestone'}{'id'} ) ) {
	    $milestones{$issue->{'milestone'}{'id'}} = $issue->{'milestone'};
	}

	# Gather people (i.e. all people who interact with the its) 
	# and authors (number of times each person has submitted an issue).
	if ( defined( $issue->{'author'} ) ) {
	    $people{$issue->{'author'}{'username'}} =  $issue->{'author'};
	    $authors{$issue->{'author'}{'username'}}++;
	}
	if ( defined($issue->{'assignee'}) ) {
	    $people{$issue->{'assignee'}{'username'}} =  $issue->{'assignee'};
	} else {
	    push( @issues_unassigned, $issue->{'iid'} ) 
		if ($issue->{'state'} eq 'open'); 
	}
	print "working with issue " . $issues_l{'iid'} . ".\n";
	push( @issues_f, \%issues_l );

	# Recommendations    
	if ( ($issue->{'state'} eq 'open') && ($date_changed < $t_1y->epoch) ) {
	    push( @{$ret{'recs'}}, { 'rid' => 'ITS_LONG_STANDING_OPEN', 
			   'severity' => 1,
			   'src' => 'GitLabIts',
			   'desc' => 'Issue ' . $issue->{'iid'} . ' has not been updated during the last year, '
			       . 'and is still open. Long-standing bugs have a negative impact on people\'s '
			       . 'perception. You should either close the bug or add some more information.' 
		  } 
		);
	}
	
    }

    # Write our own list of issues.
    $repofs->write_output( $project_id, "its_issues.json", encode_json(\@issues_f) );
    print "Keys are " . Dumper($issues_f[0]);
    
    # Analyse retrieved data, generate info, metrics, plots and visualisation.
    $ret{'metrics'}{'ITS_ISSUES_OPEN'} = $issues_open;
    $ret{'metrics'}{'ITS_ISSUES_CLOSED'} = $issues_closed;
    $ret{'metrics'}{'ITS_ISSUES_ALL'} = $issues_vol;
    $ret{'metrics'}{'ITS_ISSUES_LATE'} = scalar @issues_late;
    $ret{'metrics'}{'ITS_ISSUES_UNASSIGNED_OPEN'} = scalar @issues_unassigned;
    $ret{'metrics'}{'ITS_TOTAL_DOWNVOTES'} = $total_downvotes;
    $ret{'metrics'}{'ITS_TOTAL_UPVOTES'} = $total_upvotes;
    # time series
    $ret{'metrics'}{'ITS_CREATED_1W'} = $issues_created_1w;
    $ret{'metrics'}{'ITS_CREATED_1M'} = $issues_created_1m;
    $ret{'metrics'}{'ITS_CREATED_1Y'} = $issues_created_1y;
    $ret{'metrics'}{'ITS_CHANGED_1W'} = $issues_changed_1w;
    $ret{'metrics'}{'ITS_CHANGED_1M'} = $issues_changed_1m;
    $ret{'metrics'}{'ITS_CHANGED_1Y'} = $issues_changed_1y;
    $ret{'metrics'}{'ITS_AUTHORS'} = scalar keys %authors;
    $ret{'metrics'}{'ITS_PEOPLE'} = scalar keys %people;
    
    return \%ret;    
}


1;
