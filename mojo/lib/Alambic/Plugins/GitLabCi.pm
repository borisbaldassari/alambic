package Alambic::Plugins::GitLabCi;

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
    "id" => "GitLabCi",
    "name" => "GitLab CI",
    "desc" => [
	'Retrieves and analyses Continuous Integration data from a GitLab server. This plugin requires a token access that can be generated in the user settings.',
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
	"import_ci_jobs.json" => "Original build file from GitLab server (JSON).",
	"ci_jobs.csv" => "List of builds (CSV).",
	"ci_jobs.json" => "List of builds (JSON).",
	"ci_pipelines.json" => "List of pipelines (JSON).",
    },
    "provides_metrics" => {
        "CI_BUILDS" => "CI_BUILDS",
	"CI_PIPELINES_VOL" => "CI_PIPELINES_VOL",
        "CI_BUILDS_SUCCESS" => "CI_BUILDS_SUCCESS", 
        "CI_BUILDS_SUCCESS_1W" => "CI_BUILDS_SUCCESS_1W", 
        "CI_BUILDS_SUCCESS_1M" => "CI_BUILDS_SUCCESS_1M", 
        "CI_BUILDS_FAILED" => "CI_BUILDS_FAILED", 
        "CI_BUILDS_FAILED_1W" => "CI_BUILDS_FAILED_1W", 
        "CI_BUILDS_FAILED_1M" => "CI_BUILDS_FAILED_1M", 
    },
    "provides_figs" => {
        'gitlabci_pie.rmd' => "gitlab_ci_pie.html",
    },
    "provides_recs" => [
        "CI_BUILDS_REC",
    ],
    "provides_viz" => {
        "gitlabci.html" => "GitLab CI",
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

    my @builds_ret;
    my %pipelines_ret;
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

    # Create GitLab API object for all rest operations.
    my $api = GitLab::API::v3->new(
        url   => $gl_url . "/api/v3",
        token => $gl_token,
	);

    # Time::Piece object. Will be used for the date calculations.
    my $t_now = localtime;
    my $t_1w = $t_now - ONE_WEEK;
    my $t_1m = $t_now - ONE_MONTH;
    
    # Retrieve information about all builds. Returns an array
    # of builds, see GitLab::API::v3 doc:
    # http://search.cpan.org/~bluefeet/GitLab-API-v3-1.00/lib/GitLab/API/v3.pm#BUILD_METHODS. 
    my $builds_p = $api->paginator( 'builds', $gl_id );
    my $builds;
    while (my $build = $builds_p->next()) {
        push( @$builds, $build );
    }
    
    if ( ref($builds) eq "ARRAY" ) {
	push( @{$ret{'logs'}}, "[[Plugins::GitLabCi]] Retrieved build info from [$gl_url].");
	# Store all build info in a hash for the
	# csv and json extract.
	foreach my $build (@$builds) {
	    my %build_ret;
	    $build_ret{'id'} = $build->{'id'};
	    $build_ret{'ref_branch'} = $build->{'ref'};
	    $build_ret{'started_at'} = $build->{'started_at'};
	    $build_ret{'finished_at'} = $build->{'finished_at'};
	    $build_ret{'status'} = $build->{'status'};
	    $build_ret{'stage'} = $build->{'stage'};
	    $build_ret{'commit_id'} = $build->{'commit'}->{'id'};
	    $build_ret{'commit_committer_name'} = $build->{'commit'}->{'committer_name'};
	    $build_ret{'pipeline_id'} = $build->{'pipeline'}->{'id'};
	    $pipelines_ret{ $build->{'pipeline'}{'id'} } = $build->{'pipeline'};
	    $pipelines_ret{ $build->{'pipeline'}{'id'} }->{'builds'}++;
	    $pipelines_ret{ $build->{'pipeline'}{'id'} }->{'builds_success'}++ 
		if ( $build->{'status'} eq 'success' );

	    my $date_started = str2time($build->{'started_at'});
	    
	    if ( $date_started > $t_1w->epoch ) {
		if ( $build->{'status'} eq 'success' ) {
		    $ret{'metrics'}{'CI_BUILDS_SUCCESS_1W'}++;
		} elsif ( $build->{'status'} eq 'failed' ) {
		    $ret{'metrics'}{'CI_BUILDS_FAILED_1W'}++;
		}
	    }

	    if ( $date_started > $t_1m->epoch ) {
		if ( $build->{'status'} eq 'success' ) {
		    $ret{'metrics'}{'CI_BUILDS_SUCCESS_1M'}++;
		} elsif ( $build->{'status'} eq 'failed' ) {
		    $ret{'metrics'}{'CI_BUILDS_FAILED_1M'}++;
		}
	    }
	    
	    push( @builds_ret, \%build_ret );

	}

	# Extract successful and failed builds.
	my @builds_success = grep $_->{'status'} eq 'success', @$builds;
	my @builds_failed = grep $_->{'status'} eq 'failed', @$builds;
#	print "Build failed: " . scalar(@$builds) . "\n";
#	print "Build success: " . scalar(@builds_success) . "\n";

	# Set metrics
	$ret{'metrics'}{'CI_BUILDS_VOL'} = scalar(@$builds);
	$ret{'metrics'}{'CI_PIPELINES_VOL'} = scalar(keys %pipelines_ret);
	$ret{'metrics'}{'CI_BUILDS_FAILED'} = scalar(@builds_failed);
	$ret{'metrics'}{'CI_BUILDS_SUCCESS'} = scalar(@builds_success);
    } else {
	# Happens when no CI is defined on the project.
	push( @{$ret{'logs'}}, "Error builds is not an array. No CI defined on the project.");
	return \%ret;
    }
    
    # Write ci builds json file to disk.
    $repofs->write_output( $project_id, "import_ci_jobs.json", encode_json($builds) );
    $repofs->write_output( $project_id, "ci_jobs.json", encode_json(\@builds_ret) );

    # Write ci pipelines json file to disk.
    $repofs->write_output( $project_id, "import_ci_pipelines.json", encode_json(\%pipelines_ret) );

    # Write CI metrics to CSV files.
    my @ci_metrics_csv;
    push( @ci_metrics_csv, "CI_BUILDS_VOL,CI_PIPELINES_VOL,CI_BUILDS_SUCCESS,"
	  . "CI_BUILDS_SUCCESS_1W,CI_BUILDS_SUCCESS_1M,CI_BUILDS_FAILED," 
	  . "CI_BUILDS_FAILED_1W,CI_BUILDS_FAILED_1M\n" );
    push( @ci_metrics_csv, "" . ($ret{'metrics'}{'CI_BUILDS_VOL'} || 0) . ","
	  . ($ret{'metrics'}{'CI_PIPELINES_VOL'} || 0) . ","
	  . ($ret{'metrics'}{'CI_BUILDS_SUCCESS'} || 0) . ","
	  . ($ret{'metrics'}{'CI_BUILDS_SUCCESS_1W'} || 0) . ","
	  . ($ret{'metrics'}{'CI_BUILDS_SUCCESS_1M'} || 0) . ","
	  . ($ret{'metrics'}{'CI_BUILDS_FAILED'} || 0) . ","
	  . ($ret{'metrics'}{'CI_BUILDS_FAILED_1W'} || 0) . ","
	  . ($ret{'metrics'}{'CI_BUILDS_FAILED_1M'} || 0) . "\n" );
    $repofs->write_plugin( 'GitLabCi', $project_id . "_ci_metrics.csv", join("", @ci_metrics_csv) );
    $repofs->write_output( $project_id, "ci_metrics.csv", join("", @ci_metrics_csv) );
				       
    # Convert builds info to csv
    my @jobs_csv;
    push( @jobs_csv, "id,status,ref_branch,started_at,finished_at,stage,commit_id,"
	  . "commit_committer_name,pipeline_id\n" );
    foreach my $build (@builds_ret) {
	my $csv_out = $build->{'id'} . ',' . $build->{'status'} . ',' 
	    . $build->{'ref_branch'} . ',' . $build->{'started_at'} . ',' 
	    . $build->{'finished_at'} . ',' . $build->{'stage'} . ',' 
	    . $build->{'commit_id'} . ',' . $build->{'commit_committer_name'} . ',' 
	    . $build->{'pipeline_id'} . "\n";
	push( @jobs_csv, $csv_out );
    }
    $repofs->write_plugin( 'GitLabCi', $project_id . "_ci_jobs.csv", join("", @jobs_csv) );
    $repofs->write_output( $project_id, "ci_jobs.csv", join("", @jobs_csv) );

    # Convert pipelines info to csv
    my @pipelines_csv;
    push( @pipelines_csv, "id,sha,ref,status,builds,builds_success\n" );
    foreach my $pipeline (keys %pipelines_ret) {
	my $csv_out = $pipelines_ret{$pipeline}->{'id'} . ',' 
	    . ($pipelines_ret{$pipeline}->{'sha'} || "") . ',' 
	    . ($pipelines_ret{$pipeline}->{'ref'} || "") . ',' 
	    . ($pipelines_ret{$pipeline}->{'status'} || "") . ',' 
	    . ($pipelines_ret{$pipeline}->{'builds'} || "") . ',' 
	    . ($pipelines_ret{$pipeline}->{'builds_succes'} || "") . "\n";
	push( @pipelines_csv, $csv_out );
    }
    $repofs->write_plugin( 'GitLabCi', $project_id . "_ci_pipelines.csv", join("", @pipelines_csv) );
    $repofs->write_output( $project_id, "ci_pipelines.csv", join("", @pipelines_csv) );


    # Recommendations    
    # if ( ($issue->{'state'} eq 'open') && ($date_changed < $t_1y->epoch) ) {
    # 	push( 
    # 	    @{$ret{'recs'}}, 
    # 	    { 'rid' => 'CI_BUILDS_', 
    # 	      'severity' => 1,
    # 	      'src' => 'GitLabIts',
    # 	      'desc' => 'Issue ' . $issue->{'iid'} . ' has not been updated during the last year, '
    # 		  . 'and is still open. Long-standing bugs have a negative impact on people\'s '
    # 		  . 'perception. You should either close the bug or add some more information.' 
    # 	    } 
    # 	    );
    # }
    
    # Generate R report

    # Now execute the main R script.
    push( @{$ret{'log'}}, "[Plugins::GitLabCi] Executing R main file." );
    my $r = Alambic::Tools::R->new();
    @{$ret{'log'}} = ( @{$ret{'log'}}, @{$r->knit_rmarkdown_inc( 
					     'GitLabCi', $project_id, 'gitlabci.Rmd',
					     { "gitlab.url" => $gl_url, 
					       "gitlab.id" => $gl_id}
					     )} );
    
    # And execute the figures R scripts.
    my @figs = grep( /.*\.rmd$/i, keys %{$conf{'provides_figs'}} );
    foreach my $fig (sort @figs) {
	push( @{$ret{'log'}}, "[Plugins::GitLabCi] Executing R fig file [$fig]." );
	@{$ret{'log'}} = ( @{$ret{'log'}}, @{$r->knit_rmarkdown_html( 'GitLabCi', $project_id, $fig )} );
    }
    
    return \%ret;
}

1;
