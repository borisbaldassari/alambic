package Alambic::Plugins::EclipseScm;
use base 'Mojolicious::Plugin';

use strict; 
use warnings;

use Mojo::JSON qw( decode_json encode_json );
use Mojo::UserAgent;
use Data::Dumper;
use File::Copy;
use File::Path qw(remove_tree);

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
    "provides_files" => [
    ],
    "provides_viz" => [
        "eclipse_scm",
    ],
    "provides_fig" => {
        'scm_evol_summary.rmd' => "scm_evol_summary.html",
        'scm_evol_lines.rmd' => "scm_evol_lines.html",
        'scm_evol_people.rmd' => "scm_evol_people.html",
        'scm_evol_commits.rmd' => "scm_evol_commits.html",
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

    # Write static metrics file
    my @metrics = sort keys %{$conf{'provides_metrics'}};
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
#    print Dumper($metrics_evol);

    # Create csv data for evol
    $csv_out = "date,id,authors,added_lines,removed_lines,commits,committers,repositories,unixtime\n";
    foreach my $id ( 0 .. (scalar(@{$metrics_evol->{'date'}}) -1 ) ) {
	$csv_out .= $metrics_evol->{'date'}->[$id] . ',';
	$csv_out .= $metrics_evol->{'id'}->[$id] . ',';
	$csv_out .= $metrics_evol->{'authors'}->[$id] . ',';
	$csv_out .= $metrics_evol->{'added_lines'}->[$id] . ',';
	$csv_out .= $metrics_evol->{'removed_lines'}->[$id] . ',';
	$csv_out .= $metrics_evol->{'commits'}->[$id] . ',';
	$csv_out .= $metrics_evol->{'committers'}->[$id] . ',';
	$csv_out .= $metrics_evol->{'repositories'}->[$id] . ',';
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
    # Create dir for figures.
    if (! -d "figures/" ) {
        print "Creating directory [figures/].\n";
        mkdir "figures/";
    }
    # Create dir for figures/eclipse_scm.
    if (! -d "figures/eclipse_scm" ) {
        print "Creating directory [figures/eclipse_scm].\n";
        mkdir "figures/eclipse_scm";
    }
    # Create dir for figures/eclipse_scm/project_id.
    if (! -d "figures/eclipse_scm/${project_id}" ) {
        print "Creating directory [figures/eclipse_scm/${project_id}].\n";
        mkdir "figures/eclipse_scm/${project_id}";
    }
    
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
