package Alambic::Plugins::GitLabProject;

use strict; 
use warnings;

use Alambic::Model::RepoFS;
use Alambic::Tools::R;

use GitLab::API::v3;
use Mojo::JSON qw( decode_json encode_json );
use Mojo::Util qw( url_escape );
use Date::Parse;
use Time::Piece;
use Time::Seconds;
use Text::CSV;
use Data::Dumper;

# Main configuration hash for the plugin
my %conf = (
    "id" => "GitLabProject",
    "name" => "GitLab Project",
    "desc" => [
	'This plugin retrieves information about a project from a GitLab server',
    ],
    "type" => "pre",
    "ability" => [ 'data', 'info', 'metrics', 'viz', 'users' ],
    "params" => {
        "gitlab_url" => "The URL of the GitLab instance, e.g. http://mygitlab.mycompany.com.",
        "gitlab_id" => "The ID used to identify the project in the GitLab forge.",
        "gitlab_token" => "The private token used to access the gitlab instance. The private token must be generated by a user who has global rights on all analysed projects. It is generated, downlaoded and reset from the user's account page (/profile/account).",
    },
    "provides_cdata" => [
    ],
    "provides_info" => [
      "PROJECT_COMMITS_URL",
      "PROJECT_URL",
      "PROJECT_NAME_SPACE",
      "PROJECT_AVATAR",
      "PROJECT_WEB",
      "PROJECT_OWNER_ID",
      "PROJECT_OWNER_NAME",
      "PROJECT_ISSUES_ENABLED",
      "PROJECT_ISSUES_URL",
      "PROJECT_CI_ENABLED",
      "PROJECT_CI_URL",
      "PROJECT_WIKI_ENABLED",
      "PROJECT_WIKI_URL",
      "PROJECT_MRS_ENABLED",
      "PROJECT_MRS_URL",
      "PROJECT_SNIPPETS_ENABLED",
      "PROJECT_CREATED_AT",
      "PROJECT_VISIBILITY",
      "PROJECT_REPO_SSH",
      "PROJECT_REPO_HTTP",
    ],
    "provides_data" => {
	"import_gitlab_project_contributors.json" => "Original JSON file listing contributors, as retrieved from the GitLab server (JSON).",
	"import_gitlab_project_events.json" => "Original JSON file listing events on the project, as retrieved from the GitLab server (JSON).",
	"import_gitlab_project_branches.json" => "Original JSON file describing branches, as retrieved from the GitLab server (JSON).",
	"import_gitlab_project_commits.json" => "Original build file from GitLab server (JSON).",
	"import_gitlab_project_merge_requests.json" => "Original build file from GitLab server (JSON).",

	"metrics_gitlab_project.csv" => "All metrics computed by the GitLab Project plugin (CSV).",
	"metrics_gitlab_project.json" => "All metrics computed by the GitLab Project plugin (JSON).",
	"info_gitlab_project.csv" => "All information computed by the GitLab Project plugin (CSV).",

	"gitlab_project_branches.csv" => "CSV file describing branches in the repository of the project (CSV).",
	"gitlab_project_milestones.csv" => "CSV file describing milestones of the project (CSV).",
	"gitlab_git_merge_requests.csv" => "List of merge requests (CSV).",
	"gitlab_git_merge_requests.json" => "List of merge requests (JSON).",
	"gitlab_git_commits.csv" => "List of commits (CSV).",
	"gitlab_git_commits.json" => "List of commits (JSON).",
	"gitlab_git_commits_hist.csv" => "Evolution of commits, sorted by date (CSV).",
    },
    "provides_metrics" => {
        "PROJECT_ISSUES_OPEN" => "PROJECT_ISSUES_OPEN", 
        "PROJECT_FORKS"       => "PROJECT_FORKS", 
        "PROJECT_STARS"       => "PROJECT_STARS", 
        "PROJECT_LAST_ACTIVITY_AT" => "PROJECT_LAST_ACTIVITY_AT",
	"PROJECT_AUTHORS"       => "PROJECT_AUTHORS",
	"PROJECT_AUTHORS_1W"    => "PROJECT_AUTHORS_1W",
	"PROJECT_AUTHORS_1M"    => "PROJECT_AUTHORS_1M",
	"PROJECT_AUTHORS_1Y"    => "PROJECT_AUTHORS_1Y",
	"PROJECT_COMMITS"       => "PROJECT_COMMITS",
	"PROJECT_COMMITS_1W"    => "PROJECT_COMMITS_1W",
	"PROJECT_COMMITS_1M"    => "PROJECT_COMMITS_1M",
	"PROJECT_COMMITS_1Y"    => "PROJECT_COMMITS_1Y",
	"PROJECT_COMMITTERS"    => "PROJECT_COMMITTERS",
	"PROJECT_COMMITTERS_1W" => "PROJECT_COMMITTERS_1W",
	"PROJECT_COMMITTERS_1M" => "PROJECT_COMMITTERS_1M",
	"PROJECT_COMMITTERS_1Y" => "PROJECT_COMMITTERS_1Y",
	"PROJECT_MRS"           => "SCM_PRS",
	"PROJECT_MRS_OPENED"    => "SCM_PRS_OPENED",
	"PROJECT_MRS_OPENED_1W"    => "SCM_PRS_OPENED_1W",
	"PROJECT_MRS_OPENED_1M"    => "SCM_PRS_OPENED_1M",
	"PROJECT_MRS_OPENED_1Y"    => "SCM_PRS_OPENED_1Y",
	"PROJECT_MRS_OPENED_STILL_1W"    => "SCM_PRS_OPENED_STILL_1W",
	"PROJECT_MRS_OPENED_STILL_1M"    => "SCM_PRS_OPENED_STILL_1M",
	"PROJECT_MRS_OPENED_STILL_1Y"    => "SCM_PRS_OPENED_STILL_1Y",
	"PROJECT_MRS_OPENED_STALED_1M" => "SCM_PRS_OPENED_STALED_1M",
	"PROJECT_MRS_CLOSED"    => "SCM_PRS_CLOSED",
	"PROJECT_MRS_MERGED"    => "SCM_PRS_MERGED",
    },
    "provides_figs" => {
    },
    "provides_recs" => [
#        "SCM_MRS_STALED_1W",
#        "SCM_LOW_ACTIVITY",
#        "SCM_ZERO_ACTIVITY",
#        "SCM_LOW_DIVERSITY",
    ],
    "provides_viz" => {
        "gitlab_project.html" => "GitLab Project",
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

    push( @{$ret{'log'}}, "[Plugins::GitLabProject] Retrieving data from [$gl_url] for project [$gl_id]." ); 

    # Create GitLab API object for all rest operations.
    my $api = GitLab::API::v3->new(
        url   => $gl_url . "/api/v3",
        token => $gl_token,
	);

    # Time::Piece object. Will be used for the date calculations.
    my $t_now = localtime;
    my $t_1w = $t_now - ONE_WEEK;
    my $t_1m = $t_now - ONE_MONTH;
    my $t_1y = $t_now - ONE_YEAR;


    # Project ###############################################

    # Request general information about this project
    push( @{$ret{'log'}}, "[Plugins::GitLabProject] Retrieving project." );
    my $project = $api->project( $gl_id );

    # Get the metrics (mainly numbers, that usually evolve)
    $ret{'metrics'}{'PROJECT_FORKS'} = $project->{'forks_count'} || 0;
    $ret{'metrics'}{'PROJECT_STARS'} = $project->{'star_count'} || 0;
    $ret{'metrics'}{'PROJECT_ISSUES_OPEN'} = $project->{'open_issues_count'} || 0;
    $ret{'metrics'}{'PROJECT_LAST_ACTIVITY_AT'} = $project->{'last_activity_at'};

    # Get the info (data that should not evolve too much across builds)
    $ret{'info'}{'PROJECT_NAME_SPACE'} = $project->{'name_with_namespace'};
    $ret{'info'}{'PROJECT_AVATAR'} = $project->{'avatar_url'};
    $ret{'info'}{'PROJECT_WEB'} = $project->{'web_url'};
    $ret{'info'}{'PROJECT_OWNER_ID'} = $project->{'owner'}{'id'};
    $ret{'info'}{'PROJECT_OWNER_NAME'} = $project->{'owner'}{'name'};
    $ret{'info'}{'PROJECT_ISSUES_ENABLED'} = $project->{'issues_enabled'};
    $ret{'info'}{'PROJECT_CI_ENABLED'} = $project->{'builds_enabled'};
    $ret{'info'}{'PROJECT_WIKI_ENABLED'} = $project->{'wiki_enabled'};
    $ret{'info'}{'PROJECT_MRS_ENABLED'} = $project->{'merge_requests_enabled'};
    $ret{'info'}{'PROJECT_SNIPPETS_ENABLED'} = $project->{'snippets_enabled'};
    $ret{'info'}{'PROJECT_CREATED_AT'} = $project->{'created_at'};
    $ret{'info'}{'PROJECT_REPO_SSH'} = $project->{'ssh_url_to_repo'};
    $ret{'info'}{'PROJECT_REPO_HTTP'} = $project->{'http_url_to_repo'};

    # Use constants for visibility
    my $v = 'na';
    if ($project->{'visibility_level'} == 20) { 
        $v = 'public';
    } elsif ($project->{'visibility_level'} == 10) {
        $v = 'internal';
    } elsif ($project->{'visibility_level'} == 0) {
        $v = 'private';
    }
    $ret{'info'}{'PROJECT_VISIBILITY'} = $v;
    

    $ret{'info'}{'PROJECT_URL'} = $gl_url . '/' . $gl_id;
    $ret{'info'}{'PROJECT_MRS_URL'} = $gl_url . '/' . $gl_id . '/merge_requests';
    $ret{'info'}{'PROJECT_COMMITS_URL'} = $gl_url . '/' . $gl_id . '/commits/master';
    $ret{'info'}{'PROJECT_ISSUES_URL'} = $gl_url . '/' . $gl_id . '/issues';
    $ret{'info'}{'PROJECT_CI_URL'} = $gl_url . '/' . $gl_id . '/pipelines';
    $ret{'info'}{'PROJECT_WIKI_URL'} = $gl_url . '/' . $gl_id . '/wikis/home';

    # Request information about events for this specific project.
    my $events = $api->project_events( $gl_id );

    # Write the original events file to disk.
    my $events_json = encode_json($events);
    $repofs->write_input( $project_id, "import_gitlab_project_events.json", $events_json );


    # Request information about branches for this specific project.
    my $branches = $api->branches( $gl_id );
    $ret{'metrics'}{'PROJECT_REPO_BRANCHES'} = scalar(@$branches) || 0;

    # Write the original branches file to disk.
    my $branches_json = encode_json($branches);
    $repofs->write_input( $project_id, "import_gitlab_project_branches.json", $branches_json );    

    # Write CSV file about branches
    my $csv = Text::CSV->new({binary => 1, eol => "\n"});
    my @cols = ('name', 'commit_hash', 'commit_title', 'commit_date', 
                'commit_committer_name', 'commit_author_name');
    my $csv_out = join(',', @cols) . "\n";
    foreach my $c (@$branches) {
        my @cs = (
            $c->{'name'},
            $c->{'commit'}{'id'}, $c->{'commit'}{'title'}, $c->{'commit'}{'committed_date'}, 
            $c->{'commit'}{'committer_name'}, $c->{'commit'}{'author_name'},
            );

        $csv->combine(@cs);
        $csv_out .= $csv->string();
    }    
    $repofs->write_output($project_id, "gitlab_project_branches.csv", $csv_out);
    
    # Commits ###############################################

    # Retrieve information about all merge requests. Returns an array
    # of mrs, see GitLab::API::v3 doc:
    # https://metacpan.org/pod/GitLab::API::v3#MERGE-REQUEST-METHODS
    my $commits_p = $api->paginator( 'commits', $gl_id );
    my $commits;
    while (my $commit = $commits_p->next()) {
        push( @$commits, $commit );
    }
    
    my @commits_ret;
    my (%authors, %authors_1w, %authors_1m, %authors_1y);
    my %users;
    my (%committers, %committers_1w, %committers_1m, %committers_1y);
    my %timeline_c;
    my %timeline_a;
    
    # Initialise some zero values for some metrics -- others are set to zero anyway.
    $ret{'metrics'}{'PROJECT_COMMITS'}    = 0;
    $ret{'metrics'}{'PROJECT_COMMITS_1W'} = 0;
    $ret{'metrics'}{'PROJECT_COMMITS_1M'} = 0;
    $ret{'metrics'}{'PROJECT_COMMITS_1Y'} = 0;

    # The API returns an array of merge requests.
    if ( ref($commits) eq "ARRAY" ) {
 	push(@{$ret{'log'}}, "[Plugins::GitLabProject] Retrieved Commits info from [$gl_url].");
 	# Store all merge request info in a hash for the
 	# csv and json extract.
 	foreach my $commit (@$commits) {

	    # Store information we need about commits
 	    my %mycommit; 
 	    $mycommit{'id'} = $commit->{'id'};
 	    $mycommit{'title'} = $commit->{'title'};
 	    $mycommit{'message'} = $commit->{'message'};
 	    $mycommit{'author_email'} = $commit->{'author_email'};
 	    $mycommit{'author_name'} = $commit->{'author_name'};
 	    $mycommit{'committer_email'} = $commit->{'committer_email'};
 	    $mycommit{'committer_name'} = $commit->{'committer_name'};
 	    $mycommit{'committed_date'} = str2time( $commit->{'committed_date'} );
 	    $mycommit{'authored_date'} = str2time( $commit->{'authored_date'} );

	    # Build timeline (commits sorted by date)
	    my $date = Time::Piece->strptime($mycommit{'committed_date'} || 0, "%s");
	    my $date_m = $date->strftime("%Y-%m-%d");
	    $timeline_c{$date_m}++;

	    # Build users file, populate authors data
	    if (defined($commit->{'author_email'})) {
		$authors{$commit->{'author_email'}}++;
		my $event = {
		    "type" => "commit",
		    "id"   => $commit->{'id'},
		    "time" => $commit->{'committed_date'},
		    "msg"  => $commit->{'message'}
		};
		push(@{$users{$commit->{'author_email'}}}, $event);
		$timeline_a{$date_m}{$commit->{'author_email'}}++;
	    }
	    # Populate committers data
	    if (defined($commit->{'committer_email'})) {
		$committers{$commit->{'committer_email'}}++;
	    }
	    
	    # Is the commit recent (<1W)?
	    if ($date > $t_1w->epoch) {
		$ret{'metrics'}{'PROJECT_COMMITS_1W'}++;
		if (defined($commit->{'author_email'})) {
		    $authors_1w{$commit->{'author_email'}}++;
		}
		if (defined($commit->{'committer_email'})) {
		    $committers_1w{$commit->{'committer_email'}}++;
		}
	    }
	    
	    # Is the commit recent (<1M)?
	    if ($date > $t_1m->epoch) {
		$ret{'metrics'}{'PROJECT_COMMITS_1M'}++;
		if (defined($commit->{'author_email'})) {
		    $authors_1m{$commit->{'author_email'}}++;
		}
		if (defined($commit->{'committer_email'})) {
		    $committers_1m{$commit->{'committer_email'}}++;
		}
	    }
	    
	    # Is the commit recent (<1Y)?
	    if ($date > $t_1y->epoch) {
		$ret{'metrics'}{'PROJECT_COMMITS_1Y'}++;
		if (defined($commit->{'author_email'})) {
		    $authors_1y{$commit->{'author_email'}}++;
		}
		if (defined($commit->{'committer_email'})) {
		    $committers_1y{$commit->{'committer_email'}}++;
		}
	    }
	    
	    push( @commits_ret, \%mycommit );
 	}
	
     	# Set metrics
     	$ret{'metrics'}{'PROJECT_COMMITS'} = scalar(@commits_ret) || 0;

     	$ret{'metrics'}{'PROJECT_AUTHORS'} = scalar(keys %authors) || 0;
     	$ret{'metrics'}{'PROJECT_AUTHORS_1W'} = scalar(keys %authors_1w) || 0;
     	$ret{'metrics'}{'PROJECT_AUTHORS_1M'} = scalar(keys %authors_1m) || 0;
     	$ret{'metrics'}{'PROJECT_AUTHORS_1Y'} = scalar(keys %authors_1y) || 0;
	
     	$ret{'metrics'}{'PROJECT_COMMITTERS'} = scalar(keys %committers) || 0;
     	$ret{'metrics'}{'PROJECT_COMMITTERS_1W'} = scalar(keys %committers_1w) || 0;
     	$ret{'metrics'}{'PROJECT_COMMITTERS_1M'} = scalar(keys %committers_1m) || 0;
     	$ret{'metrics'}{'PROJECT_COMMITTERS_1Y'} = scalar(keys %committers_1y) || 0;
     } else {
     	# Happens when no git repo is defined on the project.
     	push( @{$ret{'log'}}, "Error: merge_requests is not an array.");
     	return \%ret;
     }    
    
    # Write commits json files to disk.
    $repofs->write_input( $project_id, "import_gitlab_git_commits.json", encode_json($commits) );
    $repofs->write_output( $project_id, "gitlab_git_commits.json", encode_json(\@commits_ret) );

    # Write list of commits to the disk, csv.
    $csv = Text::CSV->new({binary => 1, eol => "\n"});
    @cols = ('id', 'title', 'message', 'committed_date', 'authored_date', 
		'author_email', 'author_name', 'committer_email', 'committer_name');
    $csv_out = join(',', @cols) . "\n";
    foreach my $c (@commits_ret) {
        my @cs = map { $c->{$_} } @cols;
        $csv->combine(@cs);
        $csv_out .= $csv->string();
    }    
    $repofs->write_output($project_id, "gitlab_git_commits.csv", $csv_out);

    
    # Write commits history csv file to disk.
    my %timelines = (%timeline_a, %timeline_c);
    my @timeline
	= map { $_ . "," . $timeline_c{$_} . "," . scalar(keys %{$timeline_a{$_}}) }
    sort keys %timelines;
    $csv_out = "date,commits,authors\n";
    $csv_out .= join("\n", @timeline) . "\n";
    $repofs->write_output($project_id, "gitlab_git_commits_hist.csv", $csv_out);


    # Merge requests ###############################################

    # Retrieve information about all merge requests. Returns an array
    # of mrs, see GitLab::API::v3 doc:
    # https://metacpan.org/pod/GitLab::API::v3#MERGE-REQUEST-METHODS
    my $mrs_p = $api->paginator( 'merge_requests', $gl_id );
    my $mrs;
    while (my $mr = $mrs_p->next()) {
        push( @$mrs, $mr );
    }
    
    my @mrs_ret;
    
    # The API returns an array of merge requests.
    if ( ref($mrs) eq "ARRAY" ) {
 	push( @{$ret{'log'}}, "[Plugins::GitLabProject] Retrieved Merge requests info from [$gl_url].");
 	# Store all merge request info in a hash for the
 	# csv and json extract.
 	foreach my $mr (@$mrs) {
 	    my %mymr;
 	    $mymr{'id'} = $mr->{'iid'};
 	    $mymr{'title'} = $mr->{'title'};
 	    $mymr{'state'} = $mr->{'state'};
 	    $mymr{'description'} = $mr->{'description'}; 
 	    $mymr{'assignee'} = $mr->{'assignee'}{'name'} || '';
 	    $mymr{'web_url'} = $mr->{'web_url'};
 	    $mymr{'labels'} = join( ', ', @{$mr->{'labels'}} );
 	    $mymr{'merge_status'} = $mr->{'merge_status'};
 	    $mymr{'source_project_id'} = $mr->{'source_project_id'};
 	    $mymr{'source_branch'} = $mr->{'source_branch'};
 	    $mymr{'target_project_id'} = $mr->{'target_project_id'};
 	    $mymr{'target_branch'} = $mr->{'target_branch'};
 	    $mymr{'upvotes'} = $mr->{'upvotes'};
 	    $mymr{'downvotes'} = $mr->{'downvotes'};
 	    $mymr{'user_notes_count'} = $mr->{'user_notes_count'};
 	    $mymr{'milestone'} = $mr->{'milestone'}{'title'} || undef;
 	    $mymr{'author'} = $mr->{'author'}{'username'} || undef; # could be 'name', too.
 	    $mymr{'created_at'} = str2time( $mr->{'created_at'} );
 	    $mymr{'updated_at'} = str2time( $mr->{'updated_at'} );

	    push( @mrs_ret, \%mymr );
 	}

	# Extract successful and failed builds.
	my @mrs_opened = grep $_->{'state'} =~ m'opened', @$mrs;
     	my @mrs_merged = grep $_->{'state'} =~ m'merged', @$mrs;
     	my @mrs_closed = grep $_->{'state'} =~ m'closed', @$mrs;
	
     	my @mrs_opened_1w = grep $_->{'created_at'} > $t_1w, @$mrs;
     	my @mrs_opened_1m = grep $_->{'created_at'} > $t_1m, @$mrs;
     	my @mrs_opened_1y = grep $_->{'created_at'} > $t_1y, @$mrs;
     	my @mrs_opened_still_1w = grep $_->{'state'} =~ m'opened' && $_->{'created_at'} > $t_1w, @$mrs;
     	my @mrs_opened_still_1m = grep $_->{'state'} =~ m'opened' && $_->{'created_at'} > $t_1m, @$mrs;
     	my @mrs_opened_still_1y = grep $_->{'state'} =~ m'opened' && $_->{'created_at'} > $t_1y, @$mrs;
     	my @mrs_opened_staled_1m = grep $_->{'state'} =~ m'opened' && $_->{'updated_at'} > $t_1m, @$mrs;
	
     	# Set metrics
     	$ret{'metrics'}{'SCM_PRS'} = scalar(@$mrs);
     	$ret{'metrics'}{'SCM_PRS_OPENED'} = scalar(@mrs_opened);
     	$ret{'metrics'}{'SCM_PRS_OPENED_1W'} = scalar(@mrs_opened_1w);
     	$ret{'metrics'}{'SCM_PRS_OPENED_1M'} = scalar(@mrs_opened_1m);
     	$ret{'metrics'}{'SCM_PRS_OPENED_1Y'} = scalar(@mrs_opened_1y);
     	$ret{'metrics'}{'SCM_PRS_OPENED_STILL_1W'} = scalar(@mrs_opened_still_1w);
     	$ret{'metrics'}{'SCM_PRS_OPENED_STILL_1M'} = scalar(@mrs_opened_still_1m);
     	$ret{'metrics'}{'SCM_PRS_OPENED_STILL_1Y'} = scalar(@mrs_opened_still_1y);
     	$ret{'metrics'}{'SCM_PRS_OPENED_STALED_1M'} = scalar(@mrs_opened_staled_1m);
     	$ret{'metrics'}{'SCM_PRS_MERGED'} = scalar(@mrs_merged);
     	$ret{'metrics'}{'SCM_PRS_CLOSED'} = scalar(@mrs_closed);

     } else {
     	# Happens when no git repo is defined on the project.
     	push( @{$ret{'log'}}, "Error: merge_requests is not an array.");
     	return \%ret;
     }
    
    # Write merge requests json file to disk.
    $repofs->write_input( $project_id, "import_gitlab_git_merge_requests.json", encode_json($mrs) );
    $repofs->write_output( $project_id, "gitlab_git_merge_requests.json", encode_json(\@mrs_ret) );

    # Write list of merge requests to the disk, csv.
    $csv = Text::CSV->new({binary => 1, eol => "\n"});
    @cols = ('id', 'title', 'state', 'description', 'assignee', 'web_url', 'labels',
             'merge_status', 'source_project_id', 'source_branch', 'target_project_id', 
             'target_branch', 'upvotes', 'downvotes', 'user_notes_count', 'milestone', 
             'author', 'created_at', 'updated_at');
    $csv_out = join(',', @cols) . "\n";
    foreach my $mr (@mrs_ret) {
        my @mrs = map { $mr->{$_} } @cols;
        $csv->combine(@mrs);
        $csv_out .= $csv->string();
    }    
    $repofs->write_output($project_id, "gitlab_git_merge_requests.csv", $csv_out);


    # Contributors ###############################################

    # Request information about contributors for this specific project.
    push( @{$ret{'log'}}, "[Plugins::GitLabProject] Retrieving contributors." );
    my $contributors = $api->contributors( $gl_id );

    # Write the original file to disk.
    my $project_json = encode_json($contributors);
    $repofs->write_input( $project_id, "import_gitlab_project_contributors.json", $project_json );

    # Milestones ###############################################

    # Request information about milestones for this specific project.
    my $milestones_p = $api->paginator( 'milestones', $gl_id );
    my $milestones = [];
    while (my $milestone = $milestones_p->next()) {
        push( @$milestones, $milestone );
    }

    my ($m_active, $m_late, $m_total) = (0, 0, 0);
    my %ms_issues;
    foreach my $m (@$milestones) {
        $m_total++;
	if ( defined($m->{'due_date'}) and $m->{'due_date'} < $t_now->epoch ){
	    # TODO Add rec
	    $m_late++;
	}
	if ( $m->{'state'} eq 'active' ) { $m_active++ }
        
        # Get issues for milestone
        my $m_issues_all = $api->milestone_issues($gl_id, $m->{'id'}); 
        my @m_issues_closed = grep { $_->{'state'} eq 'closed' } @$m_issues_all;
        $ms_issues{ $m->{'id'} }{'total'} = scalar(@$m_issues_all);
        $ms_issues{ $m->{'id'} }{'closed'} = scalar(@m_issues_closed);
    }
    $ret{'metrics'}{'MILESTONES_TOTAL'} = $m_total;
    $ret{'metrics'}{'MILESTONES_LATE'} = $m_late;
    $ret{'metrics'}{'MILESTONES_ACTIVE'} = $m_active;

    # Write the original file to disk.
    my $milestones_json = encode_json($milestones);
    $repofs->write_input( $project_id, "import_gitlab_project_milestones.json", $milestones_json );
        
    # Write list of milestones to the disk, csv.
    $csv = Text::CSV->new({binary => 1, eol => "\n"});
    @cols = ('id', 'iid', 'title', 'state', 'description', 'due_date', 'start_date', 
             'created_at', 'updated_at', 'issues_total', 'issues_opened', 'issues_closed');
    $csv_out = join(',', @cols) . "\n";
    foreach my $m (@$milestones) {
        my @ms = map { $m->{$_} || '' } @cols;
        $ms[-3] = $ms_issues{ $m->{'id'} }{'total'};
        $ms[-2] = ($ms_issues{ $m->{'id'} }{'total'} - $ms_issues{ $m->{'id'} }{'closed'});
        $ms[-1] = $ms_issues{ $m->{'id'} }{'closed'};
        $csv->combine(@ms);
        $csv_out .= $csv->string();
    }    
    $repofs->write_output($project_id, "gitlab_project_milestones.csv", $csv_out);
    
    # Users ###############################################

    # Set user information for profile
    push(@{$ret{'log'}}, "[Plugins::GitLabProject] Writing user events file.");
    $events = {};
    foreach my $u (sort keys %users) {
	$events->{$u} = $users{$u};
    }
    $repofs->write_users("GitLabProject", $project_id, $events);

    # Metrics/Info  ###############################################

    # Write static metrics json file to disk.
    $repofs->write_output($project_id, "metrics_gitlab_project.json",
			  encode_json($ret{'metrics'}));

    # Write static metrics csv file to disk.
    my @metrics_def = sort map { $conf{'provides_metrics'}{$_} } keys %{$conf{'provides_metrics'}};
    $csv_out = join(',', @metrics_def) . "\n";
    my @values = map { $ret{'metrics'}{$_} || '' } @metrics_def; 
    $csv_out .= join(',', @values) . "\n";
    $repofs->write_output($project_id, "metrics_gitlab_project.csv", $csv_out);
    
    # Write info csv file to disk.
    my @info_def = sort @{$conf{'provides_info'}};
    $csv_out = join(',', @info_def) . "\n";
    my @info_values = map { $ret{'info'}{$_} || '' } @info_def; 
    $csv_out .= join(',', @info_values) . "\n";
    $repofs->write_output($project_id, "info_gitlab_project.csv", $csv_out);
    
    # Generate R report ###############################################

    # Now execute the main R script.
    push( @{$ret{'log'}}, "[Plugins::GitLabProject] Executing R main file." );
    my $r = Alambic::Tools::R->new();
    @{$ret{'log'}} = ( @{$ret{'log'}}, @{$r->knit_rmarkdown_inc( 
					     'GitLabProject', $project_id, 'gitlab_project.Rmd',
					     { "gitlab.url" => $gl_url, 
					       "gitlab.id" => $gl_id}
					     )} );
    
    # And execute the figures R scripts.
    my @figs = grep( /.*\.rmd$/i, keys %{$conf{'provides_figs'}} );
    foreach my $fig (sort @figs) {
	push( @{$ret{'log'}}, "[Plugins::GitLabProject] Executing R fig file [$fig]." );
	@{$ret{'log'}} = ( @{$ret{'log'}}, @{$r->knit_rmarkdown_html( 'GitLabProject', $project_id, $fig )} );
    }
    
    
    return \%ret;    
}


1;

=encoding utf8

=head1 NAME

B<Alambic::Plugins::GitLabProject> - Retrieves a summary of data for a GitLab project, along with
SCM information (merge requests, commits, etc.).

=head1 DESCRIPTION

B<Alambic::Plugins::GitLabProject> - Retrieves a summary of data for a GitLab project, along with
SCM information (merge requests, commits, etc.).

Parameters: 

=over

=item * gitlab_url The URL of the remote GitLab instance, e.g. https://www.gitlab.com.

=item * gitlab_id The ID used to identify the project in the GitLab forge, 
e.g. bbaldassari/Alambic.

=item * gitlab_token The private token used to access the gitlab instance. 
The private token must be generated by a user who has global rights on all 
analysed projects. It is generated, downloaded and reset from the user's 
account page (/profile/account).

=back

For the complete description of the plugin see the user documentation on the web site: L<https://alambic.io/Plugins/Pre/GitLabProject.html>.

=head1 SEE ALSO

L<https://alambic.io/Plugins/Pre/GitLabProject.html>,
L<https://gitlab.com>,
L<Mojolicious>, L<http://alambic.io>, L<https://bitbucket.org/BorisBaldassari/alambic>


=cut
