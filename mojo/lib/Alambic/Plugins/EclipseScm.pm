package Alambic::Plugins::EclipseScm;
use base 'Mojolicious::Plugin';

use strict; 
use warnings;

use Mojo::JSON qw( decode_json encode_json );
use Mojo::UserAgent;
use Data::Dumper;

# Main configuration hash for the plugin
my %conf = (
    "id" => "eclipse_scm",
    "name" => "Eclipse SCM",
    "desc" => "Retrieves configuration management data from the Eclipse dashboard repository. This plugin will look for a file named project-scm-prj-static.json on http://dashboard.eclipse.org/data/json/. This plugin is redundant with the EclipseGrimoire plugin",
    "ability" => [ "metrics", "viz" ],
    "requires" => {
        "project_id" => "",
    },
    "provides_metrics" => {
        "AUTHORS" => "SCM_AUTHORS", 
        "AUTHORS_30" => "SCM_AUTHORS_30", 
        "AUTHORS_365" => "SCM_AUTHORS_365", 
        "AUTHORS_7" => "SCM_AUTHORS_7",
        "COMMITS" => "SCM_COMMITS", 
        "COMMITS_30" => "SCM_COMMITS_30",
        "COMMITS_365" => "SCM_COMMITS_365",
        "COMMITS_7" => "SCM_COMMITS_7", 
        "COMMITTERS" => "SCM_COMMITTERS",
        "FILES" => "SCM_FILES", 
        "REPOSITORIES" => "SCM_REPOSITORIES",
    },
    "provides_files" => [
    ],
    "provides_viz" => [
        "eclipse_scm",
    ],
    "provides_fig" => {
        'scm_evol_summary.rmd' => "scm_evol_summary.html",
        'scm_evol_sent.rmd' => "scm_evol_sent.html",
        'scm_evol_people.rmd' => "scm_evol_people.html",
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
    
    my @log;

    my $url = "http://dashboard.eclipse.org/data/json/" 
            . $project_grim . "-scm-prj-static.json";

    my $file_out = $app->config->{'dir_input'} . "/" . $project_id . "/" . $project_id . "_import_scm.json";
    push( @log, "Retrieving [$url] to [$file_out].\n" );
    
    # Fetch json file from the dashboard.eclipse.org
    my $ua = Mojo::UserAgent->new;
    my $content = $ua->get($url)->res->body;
    if (length($content) < 10) { 
	push( @log, "Cannot find [$url].\n" ) ;
    } else {
	open my $fh, ">", $file_out;
	print $fh $content;
	close $fh;
    }
    
    $url = "http://dashboard.eclipse.org/data/json/" 
            . $project_grim . "-scm-prj-evolutionary.json";
    
    $file_out = $app->config->{'dir_input'} . "/" . $project_id . "/" . $project_id . "_import_scm_evol.json";
    push( @log, "Retrieving [$url] to [$file_out].\n" );
    
    # Fetch json file from the dashboard.eclipse.org
    $ua = Mojo::UserAgent->new;
    $content = $ua->get($url)->res->body;
    if (length($content) < 10) {
	push( @log, "Cannot find [$url].\n" ) ;
    } else {
	open my $fh, ">", $file_out;
	print $fh $content;
	close $fh;
    }

    return \@log;
}


sub compute_data($) {
    my $self = shift;
    my $project_id = shift;

    $app->log->info("[Plugins::EclipseScm] Starting compute data for [$project_id].");

    my $metrics_new;

    my $file_in = $app->config->{'dir_input'} . "/" . $project_id . "/" . $project_id . "_import_scm.json";
    my $json;
    do { 
        local $/;
        open my $fh, '<', $file_in or die "Could not open data file [$file_in].\n";
        $json = <$fh>;
        close $fh;
    };
    my $metrics_old = decode_json($json);

    foreach my $metric (keys %{$metrics_old}) {
        if ( exists( $conf{'provides_metrics'}{uc($metric)} ) ) {
            $metrics_new->{ $conf{'provides_metrics'}{uc($metric)} } = $metrics_old->{$metric};
        }
    }

    my $file_out = $app->config->{'dir_input'} . "/" . $project_id . "/" . $project_id . "_metrics_scm.json";
    my $json_content = encode_json($metrics_new);
    do { 
        local $/;
        open my $fh, '>', $file_out or die "Could not open data file [$file_out].\n";
        print $fh $json_content;
        close $fh;
    };

    print "DBG Writing csv..\n";

    # Write static metrics file
    my @metrics = ( "SCM_SENDERS", "SCM_SENDERS_7", "SCM_SENDERS_30", "SCM_SENDERS_365", 
                    "SCM_SENT" , "SCM_SENT_7", "SCM_SENT_30", "SCM_SENT_365", 
                    "SCM_REPOSITORIES", "SCM_SENT_RESPONSE", "SCM_THREADS" );
    my $csv_out = join( ',', sort @metrics) . "\n";
    $csv_out .= join( ',', map { $metrics_new->{$_} } sort @metrics) . "\n";
    
    my $file_csv = $app->home->rel_dir('lib') . "/Alambic/Plugins/EclipseScm/" . $project_id . "_scm.csv";
    open(my $fh, '>', $file_csv) or die "Could not open file '$file_csv' $!";
    print $fh $csv_out;
    close $fh;
    
    # Read evol metrics file
    $file_in = $app->config->{'dir_input'} . "/" . $project_id . "/" . $project_id . "_import_scm_evol.json";
    print "Reading file $file_in.\n";
    do { 
        local $/;
        open my $fh, '<', $file_in or die "Could not open data file [$file_in].\n";
        $json = <$fh>;
        close $fh;
    };
    my $metrics_evol = decode_json($json);
    print Dumper($metrics_evol);

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

    $file_csv = $app->home->rel_dir('lib') . "/Alambic/Plugins/EclipseScm/" . $project_id . "_scm_evol.csv";
    open($fh, '>', $file_csv) or die "Could not open file '$file_csv' $!";
    print $fh $csv_out;
    close $fh;
    
    # Now execute the main R script.
    my $r_dir = $app->home->rel_dir('lib') . "/Alambic/Plugins/EclipseScm/";
    my $r_md = "EclipseScm.Rmd";
    my $r_md_out = "${project_id}_eclipse_scm.inc";

    chdir $r_dir;
    $app->log->info( "Executing R script [$r_md] in [$r_dir] with [$project_id]." );
    $app->log->info( "Result to be stored in [$r_md_out]." );

    # to get r bin path.
    my $r_cmd = "Rscript -e \"library(rmarkdown); " 
        . "project.id <- '${project_id}'; plugin.id <- 'eclipse_scm'; "
        . "rmarkdown::render('${r_md}', output_format='html_fragment', output_file='$r_md_out')\"";

    $app->log->info( "Exec [$r_cmd]." );
    my @out = `$r_cmd`;
    print @out;

    # Now move files to data/project
    my $dir_out = $app->config->{'dir_input'} . "/" . $project_id . "/";

    # Create dir for figures.
    if (! -d "${dir_out}/figures/" ) {
        print "Creating directory [${dir_out}/figures/].\n";
        mkdir "${dir_out}/figures/";
    }

    move( "${r_md_out}", $dir_out );

    # Create dir for figures.
    my $dir_local_out = "figures/eclipse_scm/" . $project_id . '/';
    print "DBG Checking dir_local_out $dir_local_out.\n";
    if (! -d $dir_local_out ) {
        print "Creating directory [${dir_local_out}].\n";
        mkdir "${dir_local_out}";
    }
    
    # Now execute R scripts for pictures.
    foreach my $script (keys %{$conf{'provides_fig'}}) {
	$r_md = $script;
	$r_md_out = "figures/eclipse_scm/" . $project_id . '/' . $conf{'provides_fig'}{$script};
	
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
    my $dir_in_fig = "figures/eclipse_scm/". $project_id . '/';
    my $dir_out_fig = $app->config->{'dir_input'} . "/" . $project_id . "/figures/eclipse_scm/";
    if ( -e $dir_out_fig ) {
        print "Target directory [$dir_out_fig] exists. Removing it.\n";
        my $ret = remove_tree($dir_out_fig, {verbose => 1});
    }
    print "Creating directory [${dir_out_fig}].\n";
    mkdir "${dir_out_fig}";
    
    my $files = ${dir_in_fig} . "*";
    my @files = glob qq(${files});
#    print "DBG Looking for files in [$files]: " . join(', ', @files) . "\n";
    foreach my $file (@files) {
	my $ret = move($file, $dir_out_fig);
#	print "DBG Moved file from ${file} to $dir_out_fig. ret $ret.\n";
	$app->log->info( "Moved files from ${file} to $dir_out_fig. ret $ret." );
    }


    return ["Copied " . scalar ( keys %{$metrics_new} ) . " metrics."];
}


1;
