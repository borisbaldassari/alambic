package Alambic::Plugins::GitLabProject;

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
    "id" => "GitLabProject",
    "name" => "GitLab Project",
    "desc" => [
	'This plugin retrieves information about a project from a GitLab server',
    ],
    "type" => "pre",
    "ability" => [ 'data' ],
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
	"import_repository.json" => "Original JSON file as retrieved from the GitLab server (JSON).",
    },
    "provides_metrics" => {
        "ITS_CHANGED_1W" => "ITS_CHANGED_1W", 
        "ITS_CHANGED_1M" => "ITS_CHANGED_1M", 
        "ITS_CHANGED_1Y" => "ITS_CHANGED_1Y", 
    },
    "provides_figs" => {
    },
    "provides_recs" => [
    ],
    "provides_viz" => {
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

    # Time::Piece object. Will be used for the date calculations.
    my $t_now = localtime;
    my $t_1w = $t_now - ONE_WEEK;
    my $t_1m = $t_now - ONE_MONTH;
    my $t_1y = $t_now - ONE_YEAR;

    my $gl_url = $conf->{'gitlab_url'};
    my $gl_id = $conf->{'gitlab_id'};
    my $gl_token = $conf->{'gitlab_token'};
    
    push( @{$ret{'log'}}, "[Plugins::GitLabIts] Retrieving data from [$gl_url] for project [$gl_id]." ); 

    # Create GitLab API object for all rest operations.
    my $api = GitLab::API::v3->new(
        url   => $gl_url . "/api/v3",
        token => $gl_token,
	);
    print "############ $gl_id.\n";
    # Request information about contributors for this specific project.
    my $contributors_p = $api->paginator( 'contributors', $gl_id );
    my $contributors = [];
    while (my $contributor = $contributors_p->next()) {
        push( @$contributors, $contributor );
    }

    # Write the original file to disk.
    my $project_json = encode_json($contributors);
    $repofs->write_output( $project_id, "import_its.json", $project_json );

    # Request general information about this project
    my $project = $api->project($project_id);
    $ret{'metrics'}{'PROJECT_NAME_SPACE'} = $project->{'name_with_namespace'};
    $ret{'metrics'}{'PROJECT_AVATAR'} = $project->{'avatar_url'};
    $ret{'metrics'}{'PROJECT_FORKS'} = $project->{'forks_count'};
    $ret{'metrics'}{'PROJECT_STARS'} = $project->{'stars_count'};
    $ret{'metrics'}{'PROJECT_WEB'} = $project->{'web_url'};
    $ret{'metrics'}{'PROJECT_OWNER_ID'} = $project->{'owner'}{'id'};
    $ret{'metrics'}{'PROJECT_OWNER_NAME'} = $project->{'owner'}{'name'};
    $ret{'metrics'}{'PROJECT_ISSUES_ENABLED'} = $project->{'open_issues_count'};
    $ret{'metrics'}{'PROJECT_ISSUES_COUNT'} = $project->{'open_issues_enabled'};
    $ret{'metrics'}{'PROJECT_BUILDS_ENABLED'} = $project->{'builds_enabled'};
    $ret{'metrics'}{'PROJECT_WIKI_ENABLED'} = $project->{'wiki_enabled'};
    $ret{'metrics'}{'PROJECT_MERGE_ENABLED'} = $project->{'merge_requests_enabled'};
    $ret{'metrics'}{'PROJECT_SNIPPETS_ENABLED'} = $project->{'snippets_enabled'};
    $ret{'metrics'}{'PROJECT_CREATED_AT'} = $project->{'created_at'};
    $ret{'metrics'}{'PROJECT_LAST_ACTIVITY_AT'} = $project->{'last_activity_at'};
    print "Project: " . Dumper($project);
    
    # Request information about notes (comments) for this specific project.
    # my $notes_p = $api->paginator( 'notes', $gl_id );
    # my $notes = [];
    # while (my $note = $notes_p->next()) {
    #     push( @$notes, $note );
    # }
    
    # Request information about milestones (comments) for this specific project.
    my $milestones_p = $api->paginator( 'milestones', $gl_id );
    my $milestones = [];
    while (my $milestone = $milestones_p->next()) {
        push( @$milestones, $milestone );
    }

    my ($m_active);
    my @m_names;
    my @m_desc;
    my @m_is_late;
    foreach my $m (@$milestones) {
	if ( defined($m->{'due_date'}) and $m->{'due_date'} < $t_now->epoch ){
	    # Add rec
	    push( @m_is_late, $m );
	}
	$m_active++ if ( $m->{'state'} eq 'active' );
	push( @m_names, $m->{'title'} );
	push( @m_desc, $m->{'description'} );
    }
    $ret{'metrics'}{'MILESTONES_TOTAL'} = scalar @m_names;;
    $ret{'metrics'}{'MILESTONES_LATE'} = scalar @m_is_late;;
    $ret{'metrics'}{'MILESTONES_ACTIVE'} = $m_active;;
        

    
    return \%ret;    
}


1;
