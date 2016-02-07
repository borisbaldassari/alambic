package Alambic::Plugins::EclipseIts;
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
    "id" => "eclipse_its",
    "name" => "Eclipse ITS",
    "desc" => "Retrieves bug tracking system data from the Eclipse dashboard repository. This plugin will look for a file named project-its-prj-static.json on http://dashboard.eclipse.org/data/json/. This plugin is redundant with the EclipseGrimoire plugin",
    "ability" => [ 'metrics', 'viz' ],
    "requires" => {
        "project_id" => "",
    },
    "provides_metrics" => {
        "CHANGED" => "ITS_CHANGED", 
        "CHANGERS" => "ITS_CHANGERS", 
        "CLOSED" => "ITS_CLOSED", 
        "CLOSED_30" => "ITS_CLOSED_30", 
        "CLOSED_365" => "ITS_CLOSED_365", 
        "CLOSED_7" => "ITS_CLOSED_7",
        "CLOSERS" => "ITS_CLOSERS", 
        "CLOSERS_30" => "ITS_CLOSERS_30", 
        "CLOSERS_365" => "ITS_CLOSERS_365", 
        "CLOSERS_7" => "ITS_CLOSERS_7", 
        "TRACKERS" => "ITS_TRACKERS", 
        "OPENED" => "ITS_OPENED", 
        "OPENERS" => "ITS_OPENERS", 
        "PERCENTAGE_CLOSED" => "ITS_PERCENTAGE_CLOSED", 
        "PERCENTAGE_CLOSED_30" => "ITS_PERCENTAGE_CLOSED_30", 
        "PERCENTAGE_CLOSED_365" => "ITS_PERCENTAGE_CLOSED_365",
        "PERCENTAGE_CLOSED_7" => "ITS_PERCENTAGE_CLOSED_7", 
    },
    "provides_files" => [
    ],
    "provides_viz" => [
        "eclipse_its",
    ],
    "provides_fig" => {
        'its_evol_summary.rmd' => "its_evol_summary.html",
        'its_evol_changed.rmd' => "its_evol_changed.html",
        'its_evol_opened.rmd' => "its_evol_opened.html",
        'its_evol_people.rmd' => "its_evol_people.html",
        'its_evol_ggplot.rmd' => "its_evol_ggplot.html",
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
            . $project_grim . "-its-prj-static.json";

    $app->log->info("[Plugins::EclipseIts] Starting retrieval of data for [$project_id] url [$url].");
    
    my $file_out = $app->config->{'dir_input'} . "/" . $project_id . "/" . $project_id . "_import_its.json";
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
            . $project_grim . "-its-prj-evolutionary.json";
    
    $file_out = $app->config->{'dir_input'} . "/" . $project_id . "/" . $project_id . "_import_its_evol.json";
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

    $app->log->info("[Plugins::EclipseIts] Starting compute data for [$project_id].");

    my $metrics_new;

    my $file_in = $app->config->{'dir_input'} . "/" . $project_id . "/" . $project_id . "_import_its.json";
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

    my $file_out = $app->config->{'dir_input'} . "/" . $project_id . "/" . $project_id . "_metrics_its.json";
    my $json_content = encode_json($metrics_new);
    do { 
        local $/;
        open my $fh, '>', $file_out or die "Could not open data file [$file_out].\n";
        print $fh $json_content;
        close $fh;
    };

    # Write static metrics file
    my @metrics = ( "ITS_CLOSED_30", "ITS_CLOSERS_7", "ITS_CLOSED_7", "ITS_CLOSED_365", "ITS_CHANGERS", "" 
	. "ITS_CLOSERS_365", "ITS_TRACKERS", "ITS_PERCENTAGE_CLOSED_7", "ITS_PERCENTAGE_CLOSED_30", ""
	. "ITS_PERCENTAGE_CLOSED_365", "ITS_CLOSED", "ITS_OPENERS", "ITS_OPENED", "ITS_CHANGED", ""
		    . "ITS_CLOSERS_30", "ITS_CLOSERS" );
    my $csv_out = join( ',', sort @metrics) . "\n";
    $csv_out .= join( ',', map { $metrics_new->{$_} } sort @metrics) . "\n";
    
    my $file_csv = $app->home->rel_dir('lib') . "/Alambic/Plugins/EclipseIts/" . $project_id . "_its.csv";
    open(my $fh, '>', $file_csv) or die "Could not open file '$file_csv' $!";
    print $fh $csv_out;
    close $fh;
    
    # Read evol metrics file
    $file_in = $app->config->{'dir_input'} . "/" . $project_id . "/" . $project_id . "_import_its_evol.json";
    do { 
        local $/;
        open my $fh, '<', $file_in or die "Could not open data file [$file_in].\n";
        $json = <$fh>;
        close $fh;
    };
    my $metrics_evol = decode_json($json);

    # Create csv data for evol
    $csv_out = "date,changed,changers,closed,closers,opened,openers,trackers,unixtime\n";
    foreach my $id ( 0 .. (scalar(@{$metrics_evol->{'date'}}) -1 ) ) {
	$csv_out .= $metrics_evol->{'date'}->[$id] . ',';
	$csv_out .= $metrics_evol->{'changed'}->[$id] . ',';
	$csv_out .= $metrics_evol->{'changers'}->[$id] . ',';
	$csv_out .= $metrics_evol->{'closed'}->[$id] . ',';
	$csv_out .= $metrics_evol->{'closers'}->[$id] . ',';
	$csv_out .= $metrics_evol->{'opened'}->[$id] . ',';
	$csv_out .= $metrics_evol->{'openers'}->[$id] . ',';
	$csv_out .= $metrics_evol->{'trackers'}->[$id] . ',';
	$csv_out .= $metrics_evol->{'unixtime'}->[$id] . "\n";
    }

    $file_csv = $app->home->rel_dir('lib') . "/Alambic/Plugins/EclipseIts/" . $project_id . "_its_evol.csv";
    open($fh, '>', $file_csv) or die "Could not open file '$file_csv' $!";
    print $fh $csv_out;
    close $fh;
    
    # Now execute the main R script.
    my $r_dir = $app->home->rel_dir('lib') . "/Alambic/Plugins/EclipseIts/";
    my $r_md = "EclipseIts.Rmd";
    my $r_md_out = "${project_id}_eclipse_its.inc";

    chdir $r_dir;
    $app->log->info( "Executing R script [$r_md] in [$r_dir] with [$project_id]." );
    $app->log->info( "Result to be stored in [$r_md_out]." );

    # to get r bin path.
    my $r_cmd = "Rscript -e \"library(rmarkdown); " 
        . "project.id <- '${project_id}'; plugin.id <- 'eclipse_its'; "
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
	$r_md_out = "figures/eclipse_its/" . $project_id . '/' . $conf{'provides_fig'}{$script};
	
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
    my $dir_in_fig = "figures/eclipse_its/". $project_id . '/';
    my $dir_out_fig = $app->config->{'dir_input'} . "/" . $project_id . "/figures/eclipse_its/";
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
    
    # Move lib files to data/project
    # my $dir_out_lib = $app->config->{'dir_input'} . "/" . $project_id . "/lib/";
    # if ( -e $dir_out_lib ) {
    #     print "Target directory [$dir_out_lib] exists. Removing it.\n";
    #     my $ret = remove_tree($dir_out_lib, {verbose => 1});
    # }
    # $ret = move('lib/' . $project_id . '/', $dir_out_lib);
    # $app->log->info( "Moved files from ${r_dir}/lib to $dir_out_lib. ret $ret." );
    

    return ["Copied " . scalar( keys %{$metrics_new} ) . " metrics."];
}


1;
