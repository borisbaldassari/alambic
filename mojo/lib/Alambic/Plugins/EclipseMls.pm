package Alambic::Plugins::EclipseMls;
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
    "id" => "eclipse_mls",
    "name" => "Eclipse MLS",
    "desc" => "Retrieves mailing list data from the Eclipse dashboard repository. This plugin will look for a file named project-mls-prj-static.json on http://dashboard.eclipse.org/data/json/. This plugin is redundant with the EclipseGrimoire plugin",
    "ability" => [ "metrics", "viz" ],
    "requires" => {
        "project_id" => "",
    },
    "provides_metrics" => {
        "REPOSITORIES" => "MLS_REPOSITORIES", 
        "SENDERS" => "MLS_SENDERS", 
        "SENDERS_30" => "MLS_SENDERS_30", 
        "SENDERS_365" => "MLS_SENDERS_365", 
        "SENDERS_7" => "MLS_SENDERS_7", 
        "SENDERS_RESPONSE" => "MLS_SENDERS_RESPONSE",
        "SENT" => "MLS_SENT", 
        "SENT_30" => "MLS_SENT_30", 
        "SENT_365" => "MLS_SENT_365", 
        "SENT_7" => "MLS_SENT_7", 
        "SENT_RESPONSE" => "MLS_SENT_RESPONSE", 
        "THREADS" => "MLS_THREADS",
    },
    "provides_files" => [
    ],
    "provides_viz" => [
        "eclipse_mls",
    ],
    "provides_fig" => {
        'mls_evol_summary.rmd' => "mls_evol_summary.html",
        'mls_evol_sent.rmd' => "mls_evol_sent.html",
        'mls_evol_people.rmd' => "mls_evol_people.html",
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

# Download json file from dashboard.eclipse.org
sub retrieve_data($) {
    my $self = shift;
    my $project_id = shift;
    
    my $project_conf = $app->projects->get_project_info($project_id)->{'ds'}->{$self->get_conf->{'id'}};
    my $project_grim = $project_conf->{'project_id'};
    
    my @log;

    my $url = "http://dashboard.eclipse.org/data/json/" 
            . $project_grim . "-mls-prj-static.json";

    my $file_out = $app->config->{'dir_input'} . "/" . $project_id . "/" . $project_id . "_import_mls.json";
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
            . $project_grim . "-mls-prj-evolutionary.json";
    
    $file_out = $app->config->{'dir_input'} . "/" . $project_id . "/" . $project_id . "_import_mls_evol.json";
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


# Basically read the imported files and make the mapping to the 
# new metric names.
sub compute_data($) {
    my $self = shift;
    my $project_id = shift;

    $app->log->info("[Plugins::EclipseMls] Starting compute data for [$project_id].");

    my $metrics_new;

    my $file_in = $app->config->{'dir_input'} . "/" . $project_id . "/" . $project_id . "_import_mls.json";
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

    my $file_out = $app->config->{'dir_input'} . "/" . $project_id . "/" . $project_id . "_metrics_mls.json";
    my $json_content = encode_json($metrics_new);
    do { 
        local $/;
        open my $fh, '>', $file_out or die "Could not open data file [$file_out].\n";
        print $fh $json_content;
        close $fh;
    };

    # Write static metrics file
    my @metrics = ( "MLS_SENDERS", "MLS_SENDERS_7", "MLS_SENDERS_30", "MLS_SENDERS_365", 
                    "MLS_SENT" , "MLS_SENT_7", "MLS_SENT_30", "MLS_SENT_365", 
                    "MLS_REPOSITORIES", "MLS_SENT_RESPONSE", "MLS_THREADS" );
    my $csv_out = join( ',', sort @metrics) . "\n";
    $csv_out .= join( ',', map { $metrics_new->{$_} } sort @metrics) . "\n";
    
    my $file_csv = $app->home->rel_dir('lib') . "/Alambic/Plugins/EclipseMls/" . $project_id . "_mls.csv";
    open(my $fh, '>', $file_csv) or die "Could not open file '$file_csv' $!";
    print $fh $csv_out;
    close $fh;
    
    # Read evol metrics file
    $file_in = $app->config->{'dir_input'} . "/" . $project_id . "/" . $project_id . "_import_mls_evol.json";
    do { 
        local $/;
        open my $fh, '<', $file_in or die "Could not open data file [$file_in].\n";
        $json = <$fh>;
        close $fh;
    };
    my $metrics_evol = decode_json($json);

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

    $file_csv = $app->home->rel_dir('lib') . "/Alambic/Plugins/EclipseMls/" . $project_id . "_mls_evol.csv";
    open($fh, '>', $file_csv) or die "Could not open file '$file_csv' $!";
    print $fh $csv_out;
    close $fh;
    
    # Now execute the main R script.
    my $r_dir = $app->home->rel_dir('lib') . "/Alambic/Plugins/EclipseMls/";
    my $r_md = "EclipseMls.Rmd";
    my $r_md_out = "${project_id}_eclipse_mls.inc";

    chdir $r_dir;
    $app->log->info( "Executing R script [$r_md] in [$r_dir] with [$project_id]." );
    $app->log->info( "Result to be stored in [$r_md_out]." );

    # to get r bin path.
    my $r_cmd = "Rscript -e \"library(rmarkdown); " 
        . "project.id <- '${project_id}'; plugin.id <- 'eclipse_mls'; "
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
    my $dir_local_out = "figures/eclipse_mls/" . $project_id . '/';
    print "DBG Checking dir_local_out $dir_local_out.\n";
    if (! -d $dir_local_out ) {
        print "Creating directory [${dir_local_out}].\n";
        mkdir "${dir_local_out}";
    }
    
    # Now execute R scripts for pictures.
    foreach my $script (keys %{$conf{'provides_fig'}}) {
	$r_md = $script;
	$r_md_out = "figures/eclipse_mls/" . $project_id . '/' . $conf{'provides_fig'}{$script};
	
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
    my $dir_in_fig = "figures/eclipse_mls/". $project_id . '/';
    my $dir_out_fig = $app->config->{'dir_input'} . "/" . $project_id . "/figures/eclipse_mls/";
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

    return ["Copied " . scalar( keys %{$metrics_new} ) . " metrics."];
}


1;
