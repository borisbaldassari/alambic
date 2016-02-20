package Alambic::Plugins::Hudson;
use base 'Mojolicious::Plugin';

use strict; 
use warnings;

use Mojo::JSON qw( decode_json encode_json );
use Mojo::UserAgent;
use DateTime;
use Data::Dumper;
use File::Copy;
use File::Path qw(remove_tree);


# Main configuration hash for the plugin
my %conf = (
    "id" => "hudson",
    "name" => "Hudson CI",
    "desc" => "Retrieves information from the Hudson continuous integration engine.",
    "ability" => [ 'metrics', 'viz', 'fig' ],
    "requires" => {
        "project_id" => "",
        "hudson_url" => "",
    },
    "provides_metrics" => {
        "JOBS" => "JOBS", 
        "JOBS_GREEN" => "JOBS_GREEN", 
        "JOBS_YELLOW" => "JOBS_YELLOW", 
        "JOBS_RED" => "JOBS_RED", 
        "JOBS_FAILED_1W" => "JOBS_FAILED_1W", # last build is failed for more than 1W old
    },
    "provides_files" => [
    ],
    "provides_viz" => {
        "hudson" => "Hudson",
    },
    "provides_fig" => {
        'hudson_trend.rmd' => "hudson_trend.html",
    },
);

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

    return [];
}

sub retrieve_data($) {
    my $self = shift;
    my $project_id = shift;

    my $project_conf = $app->projects->get_project_info($project_id)->{'ds'}->{$self->get_conf->{'id'}};
    my $project_grim = $project_conf->{'project_id'};
    my $hudson_url = $project_conf->{'hudson_url'};
    
    my $hudson;
    my @log;

    my $url = $hudson_url . "/api/json?depth=2";
    
    print "[Plugins::Hudson] Starting retrieval of data for [$project_id] url [$url].\n";
    $app->log->info("[Plugins::Hudson] Starting retrieval of data for [$project_id] url [$url].");
    
    # Fetch json file from the dashboard.eclipse.org
    my $ua = Mojo::UserAgent->new;
    my $json = $ua->get($url)->res->body;
    if (length($json) < 10) {
	push( @log, "Cannot find [$url].\n" ) ;
    } else {
	$hudson = decode_json( $json );
    }
    
    my $file_out = $app->config->{'dir_input'} . "/" . $project_id . "/" . $project_id . "_import_hudson.json";
    push( @log, "Retrieving [$url] to [$file_out].\n" );
    open my $fh, ">", $file_out;
    print $fh encode_json( $hudson );
    close $fh;

    return \@log;
}

sub compute_data($) {
    my $self = shift;
    my $project_id = shift;

    $app->log->info("[Plugins::Hudson] Starting compute data for [$project_id].");

    my %metrics;

    my $file_in = $app->config->{'dir_input'} . "/" . $project_id . "/" . $project_id . "_import_hudson.json";
    my $json;
    do { 
        local $/;
        open my $fh, '<', $file_in or die "Could not open data file [$file_in].\n";
        $json = <$fh>;
        close $fh;
    };
    my $hudson = decode_json($json);

    $metrics{'JOBS'} = scalar @{$hudson->{'jobs'}};
    $metrics{'JOBS_GREEN'} = 0;
    $metrics{'JOBS_YELLOW'} = 0;
    $metrics{'JOBS_RED'} = 0;
    $metrics{'JOBS_FAILED_1W'} = 0;

    # Find the date for one week ago
    my $date = DateTime->now();
    $date->subtract(days => 7);
    foreach my $job (@{$hudson->{'jobs'}}) {
	if ($job->{'color'} =~ m!green!) { 
	    $metrics{'JOBS_GREEN'}++;
	} elsif ($job->{'color'} =~ m!yellow!) { 
	    $metrics{'JOBS_YELLOW'}++; 
	} elsif ($job->{'color'} =~ m!red!) { 
	    $metrics{'JOBS_RED'}++;
	}

	# If last successful build is more than 1W old, count it.
	if (exists($job->{'lastFailedBuild'}{'timestamp'}) 
	    && $job->{'lastFailedBuild'}{'timestamp'} < $date->epoch()) {
	    $metrics{'JOBS_FAILED_1W'}++;
	}
    }

    my $file_out = $app->config->{'dir_input'} . "/" . $project_id . "/" . $project_id . "_metrics_hudson.json";
    my $json_content = encode_json(\%metrics);
    do { 
        local $/;
        open my $fh, '>', $file_out or die "Could not open data file [$file_out].\n";
        print $fh $json_content;
        close $fh;
    };

    # Write csv file for main informaiton about hudson instance
    my @metrics_csv = sort map {$conf{'provides_metrics'}{$_}} keys %{$conf{'provides_metrics'}};
    my $csv_out = join( ',', sort @metrics_csv) . "\n";
    $csv_out .= join( ',', map { $metrics{$_} } sort @metrics_csv) . "\n";

    my $file_csv = $app->home->rel_dir('lib') . "/Alambic/Plugins/Hudson/" . $project_id . "_hudson_main.csv";
    print "Writing metrics to file [$file_csv].\n";
    open(my $fh, '>', $file_csv) or die "Could not open file '$file_csv' $!";
    print $fh $csv_out;
    close $fh;

    # Write csv file for jobs
    my @jobs_metrics = ('name', 'buildable', 'color', 
			'last_build', 'last_build_time', 'last_build_duration',
			'last_failed_build', 'last_failed_build_time', 'last_failed_build_duration', 
			'last_successful_build', 'last_successful_build_time', 'last_successful_build_duration', 
			'next_build_number', 'health_report', 'url');
    $csv_out = join( ',', @jobs_metrics) . "\n";
    my $sep = ',';
    print "Building jobs csv file.\n";
#    print Dumper(map {$_->{'name'}} @{$hudson->{'jobs'}});
    foreach my $job (@{$hudson->{'jobs'}}) {
	my $name = $job->{'name'};
	print "Building jobs csv file: $name.\n";
	my $lb_id = $job->{'lastBuild'}->{'number'} || 0;
	my $lb_time = $job->{'lastBuild'}->{'timestamp'} || 0;
	my $lb_duration = $job->{'lastBuild'}->{'duration'} || 0;
	my $lfb_id = $job->{'lastFailedBuild'}->{'number'} || 0;
	my $lfb_time = $job->{'lastFailedBuild'}->{'timestamp'} || 0;
	my $lfb_duration = $job->{'lastFailedBuild'}->{'duration'} || 0;
	my $lsb_id = $job->{'lastSuccessfulBuild'}->{'number'} || 0;
	my $lsb_time = $job->{'lastSuccessfulBuild'}->{'timestamp'} || 0;
	my $lsb_duration = $job->{'lastSuccessfulBuild'}->{'duration'} || 0;
	my $hr_score = $job->{'healthReport'}[0]{'score'};
	$csv_out .= $name . $sep
	    . $job->{'buildable'} . $sep
	    . $job->{'color'} . $sep
	    . $lb_id . $sep
	    . $lb_time . $sep
	    . $lb_duration . $sep
	    . $lfb_id . $sep
	    . $lfb_time . $sep
	    . $lfb_duration . $sep
	    . $lsb_id . $sep
	    . $lsb_time . $sep
	    . $lsb_duration . $sep
	    . $job->{'nextBuildNumber'} . $sep
	    . $hr_score . $sep
	    . $job->{'url'} . "\n";
    }
    
    $file_csv = $app->home->rel_dir('lib') . "/Alambic/Plugins/Hudson/" . $project_id . "_hudson_jobs.csv";
    open($fh, '>', $file_csv) or die "Could not open file '$file_csv' $!";
    print $fh $csv_out;
    close $fh;
    
    # Now execute the main R script.
    my $r_dir = $app->home->rel_dir('lib') . "/Alambic/Plugins/Hudson/";
    my $r_md = "Hudson.Rmd";
    my $r_md_out = "${project_id}_hudson.inc";

    chdir $r_dir;
    # Create dir for figures.
    if (! -d "figures/" ) {
        print "Creating directory [figures/].\n";
        mkdir "figures/";
    }
    # Create dir for figures/hudson.
    if (! -d "figures/hudson" ) {
        print "Creating directory [figures/hudson].\n";
        mkdir "figures/hudson";
    }
    # Create dir for figures/hudson/project_id.
    if (! -d "figures/hudson/${project_id}" ) {
        print "Creating directory [figures/hudson/${project_id}].\n";
        mkdir "figures/hudson/${project_id}";
    }

    $app->log->info( "Executing R script [$r_md] in [$r_dir] with [$project_id]." );
    $app->log->info( "Result to be stored in [$r_md_out]." );

    # to get r bin path.
    my $r_cmd = "Rscript -e \"library(rmarkdown); " 
        . "project.id <- '${project_id}'; plugin.id <- 'hudson'; "
        . "rmarkdown::render('${r_md}', output_format='html_fragment', output_file='$r_md_out')\"";

    $app->log->info( "Exec [$r_cmd]." );
    my @out = `$r_cmd`;
    print @out;

    # Now move files to data/project
    my $dir_out = $app->config->{'dir_input'} . "/" . $project_id . "/";
    move( "${r_md_out}", $dir_out );

    # Create dir for figures.
    if (! -d "${dir_out}/figures/" ) {
        print "Creating directory [${dir_out}/figures/].\n";
        mkdir "${dir_out}/figures/";
    }
    
    # Now execute R scripts for pictures.
    foreach my $script (keys %{$conf{'provides_fig'}}) {
	$r_md = $script;
	$r_md_out = "figures/hudson/" . $project_id . '/' . $conf{'provides_fig'}{$script};
	
	$app->log->info( "Executing R fig script [$r_md] in [$r_dir] with [$project_id]." );
	$app->log->info( "Result to be stored in [$r_md_out]." );
	
	# to get r bin path.
	my $r_cmd = "Rscript -e \"library(rmarkdown); " 
	    . "project.id <- '${project_id}'; "
	    . "rmarkdown::render('${r_md}', output_format='html_document', output_file='$r_md_out')\"";
	
	$app->log->info( "Exec [$r_cmd]." );
	my @out = `$r_cmd`;
	#print @out;
    }


    # Move figures to data/project
    my $dir_in_fig = "figures/hudson/". $project_id . '/';
    my $dir_out_fig = $app->config->{'dir_input'} . "/" . $project_id . "/figures/hudson/";
    if ( -e $dir_out_fig ) {
        print "Target directory [$dir_out_fig] exists. Removing it.\n";
        my $ret = remove_tree($dir_out_fig, {verbose => 1});
    }
    print "Creating directory [${dir_out_fig}].\n";
    mkdir "${dir_out_fig}";
    
    my $files = ${dir_in_fig} . "*";
    my @files = glob qq(${files});
    foreach my $file (@files) {
	my $ret = move($file, $dir_out_fig);
	$app->log->info( "Moved files from ${file} to $dir_out_fig. ret $ret." );
    }
    
    return ["Copied " . scalar( keys %metrics ) . " metrics."];
}


1;
