package Alambic::Tools::R;

use strict; 
use warnings;

use Alambic::Model::RepoFS;
use File::chdir;
use File::Copy;
#use File::Path qw(remove_tree);
    
use Data::Dumper;

# Main configuration hash for the plugin
my %conf = (
    "id" => "r_sessions",
    "name" => "R sessions",
    "desc" => "Runs R for plugins, computes data and generates files.",
    "provides_methods" => {
        "knit_rmarkdown_inc" => "",
        "knit_rmarkdown_pdf" => "",
        "knit_rmarkdown_html" => "",
        "knit_rmarkdown_svg" => "",
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

sub start() {
    return 1;
}

sub stop() {
    return 1;
}

sub test() {

    my @log;

    my $path_r;
    for my $path ( split /:/, $ENV{PATH} ) {
	if ( -f "$path/R" && -x _ ) { $path_r = "$path/R"; last; }
    }

    if ( defined($path_r) ) {
	push( @log, "OK: R exec found in PATH at [$path_r]." );
    } else {
	push( @log, "ERROR: R exec NOT found in PATH." );
    }
    
    my $path_rscript;
    for my $path ( split /:/, $ENV{PATH} ) {
	if ( -f "$path/Rscript" && -x _ ) { $path_rscript = "$path/Rscript"; last; }
    }

    if ( defined($path_rscript) ) {
	push( @log, "OK: Rscript exec found in PATH at [$path_rscript]." );
    } else {
	push( @log, "ERROR: Rscript exec NOT found in PATH." );
    }

    return \@log;
}


# Function to knit a rmarkdown document to a html snippet.
# It goes into the plugin's directory, 
# creates required directories (e.g. figures/) and executes Rscript.
#
# The plugin assumes that the input files needed are already present in the directory.
#
# Params:
#   - $plugin_id: the name/id of the calling plugin, e.g. EclipseIts.
#   - $project_id: the id of the project analysed.
#   - $r_file: the short name of the file to execute (e.g. EclipseIts.Rmd)
#   - %params: a ref to hash of parameters/values for the execution.
sub knit_rmarkdown_inc($$$$) {
    my ($self, $plugin_id, $project_id, $r_file, $params) = @_;

    my @log;
    
    # Set vars.
    my $r_dir = "lib/Alambic/Plugins/$plugin_id/";
    my $r_md = $r_file;
    $r_file =~ s/(.*)\..*+/$1/;
    my $r_md_out = "${r_file}.inc";

    # Change the current working directory localy only.
    {
	local $CWD = $r_dir;
	# Create dir for figures.
	if (! -d "figures/" ) {
	    push( @log, "[Tools::R] Creating directory [figures/]." );
	    mkdir "figures/";
	}
	
	# Now execute the main R script.
	my $r_cmd = "Rscript -e \"library(rmarkdown); ";
	$r_cmd .= "project.id <- '${project_id}'; plugin.id <- '$plugin_id'; ";
	foreach my $key (keys %{$params}) {
	    $r_cmd .= $key . " <- " . $params->{$key};
	}
	$r_cmd .= "rmarkdown::render('${r_md}', output_format='html_fragment', output_file='$r_md_out')\"";
	
	push( @log, "[Tools::R] Exec [$r_cmd] to [$r_md_out]." );
#	print "[Tools::R] Exec [$r_cmd].\n";
	my @out = `$r_cmd 2>&1`;
    }
    
    # Move the generated main file to project output dir
    my $file_in = $r_dir . "/" . $r_md_out;
    my $dir_in_fig = $r_dir . '/figures/';
    my $dir_out = "projects/" . $project_id . "/output/";
    my $dir_out_fig = $dir_out . '/figures/';
    move( $file_in, $dir_out );

    # Create dir for figures.
    if (! -d "${dir_out_fig}" ) {
        push( @log, "Creating directory [${dir_out_fig}]." );
        mkdir "${dir_out_fig}";
    }
    
    # Move the generated picture files to project output dir
    my $files = $dir_in_fig . "*";
    my @files = glob qq(${files});
    foreach my $file (@files) {
	my $ret = move($file, $dir_out_fig);
#	push( @log, "[Tools::R] Moved file from ${file} to $dir_out_fig. ret $ret." );
    }

    return \@log;
}


# Function to knit a rmarkdown document to a html snippet.
# It goes into the plugin's directory, 
# creates required directories (e.g. figures/) and executes Rscript.
#
# The plugin assumes that the input files needed are already present in the directory.
#
# Params:
#   - $plugin_id: the name/id of the calling plugin, e.g. EclipseIts.
#   - $project_id: the id of the project analysed.
#   - $r_file: the short name of the file to execute (e.g. EclipseIts.Rmd)
#   - %params: a ref to hash of parameters/values for the execution.
sub knit_rmarkdown_pdf($$$$) {
    my ($self, $plugin_id, $project_id, $r_file, $params) = @_;

    my @log;
    
    # Set vars.
    my $r_dir = "lib/Alambic/Plugins/$plugin_id/";
    my $r_md = $r_file;
    $r_file =~ s/(.*)\..*+/$1/;
    my $r_md_out = "${r_file}.pdf";
    push( @log, "[Tools::R] Executing [$r_md] output to [$r_md_out]." );

    # Change the current working directory localy only.
    {
	local $CWD = $r_dir;
	# Create dir for figures.
	if (! -d "figures/" ) {
#	    print "Creating directory [figures/].\n";
	    mkdir "figures/";
	}
	
	# Now execute the main R script.
	my $r_cmd = "Rscript -e \"library(rmarkdown); ";
	$r_cmd .= "project.id <- '${project_id}'; plugin.id <- '$plugin_id'; ";
	foreach my $key (keys %{$params}) {
	    $r_cmd .= $key . " <- " . $params->{$key};
	}
	$r_cmd .= "rmarkdown::render('${r_md}', output_file='$r_md_out')\"";
	
#	print "[Tools::R] Exec [$r_cmd].";
	push( @log, "[Tools::R] Exec [$r_cmd]." );
	my @out = `$r_cmd 2>&1`;
    }
    
    # Move the generated main file to project output dir
    my $file_in = $r_dir . "/" . $r_md_out;
    my $dir_in_fig = $r_dir . '/figures/';
    my $dir_out = "projects/" . $project_id . "/output/";
    my $file_out = $dir_out . $project_id . "_" . $r_md_out;
    my $dir_out_fig = $dir_out . '/figures/';
    move( $file_in, $file_out );

    # Create dir for figures.
    if (! -d "${dir_out_fig}" ) {
        push( @log, "Creating directory [${dir_out_fig}]." );
        mkdir "${dir_out_fig}";
    }
    
    # Move the generated picture files to project output dir
    my $files = $dir_in_fig . "*";
    my @files = glob qq(${files});
    foreach my $file (@files) {
	my $ret = move($file, $dir_out_fig);
#	push( @log, "[Tools::R] Moved file from ${file} to $dir_out_fig. ret $ret." );
    }

    return \@log;
}


# Function to knit a rmarkdown document to html.
# It goes into the plugin's directory, 
# creates required directories (e.g. figures/) and executes Rscript.
#
# The plugin assumes that the input files needed are already present in the directory.
#
# Params:
#   - $plugin_id: the name/id of the calling plugin, e.g. EclipseIts.
#   - $project_id: the id of the project analysed.
#   - $r_file: the short name of the file to execute (e.g. EclipseIts.Rmd)
#   - %params: a ref to hash of parameters/values for the execution.
sub knit_rmarkdown_html($$$$) {
    my ($self, $plugin_id, $project_id, $r_file, $params) = @_;

    my @log;
    
    # Set vars.
    my $r_dir = "lib/Alambic/Plugins/$plugin_id/";
    my $r_md = $r_file;
    $r_file =~ s/(.*)\..*+/$1/;
    my $r_md_out = "${r_file}.html";

    # Change the current working directory localy only.
    {
	local $CWD = $r_dir;
	# Create dir for figures.
	if (! -d "figures/" ) {
	    push( @log, "Creating directory [figures/]." );
	    mkdir "figures/";
	}
	
	# Now execute the main R script.
	my $r_cmd = "Rscript -e \"library(rmarkdown); ";
	$r_cmd .= "project.id <- '${project_id}'; plugin.id <- '$plugin_id'; ";
	foreach my $key (keys %{$params}) {
	    $r_cmd .= $key . " <- " . $params->{$key};
	}
	$r_cmd .= "rmarkdown::render('${r_md}', output_format='html_document', output_file='$r_md_out')\"";
	
	push( @log, "[Tools::R] Exec [$r_cmd] output to [$r_md_out]." );
	my @out = `$r_cmd 2>&1`;
    }
    
    # Move the generated main file to project output dir
    my $file_in = $r_dir . "/" . $r_md_out;
    my $dir_in_fig = $r_dir . '/figures/';
    my $dir_out = "projects/" . $project_id . "/output/";
    my $dir_out_fig = $dir_out . '/figures/';
    move( $file_in, $dir_out );

    # Create dir for figures.
    if (! -d "${dir_out_fig}" ) {
        push( @log, "Creating directory [${dir_out_fig}]." );
        mkdir "${dir_out_fig}";
    }
    
    # Move the generated picture files to project output dir
    my $files = $dir_in_fig . "*";
    my @files = glob qq(${files});
    foreach my $file (@files) {
	my $ret = move($file, $dir_out_fig);
#	push( @log, "[Tools::R] Moved file from ${file} to $dir_out_fig. ret $ret." );
    }

    return \@log;
}


# Function to knit a rmarkdown document to svg.
# It goes into the plugin's directory, 
# creates required directories (e.g. figures/) and executes Rscript.
#
# The plugin assumes that the input files needed are already present in the directory.
#
# Params:
#   - $plugin_id: the name/id of the calling plugin, e.g. EclipseIts.
#   - $project_id: the id of the project analysed.
#   - $r_file: the short name of the file to execute (e.g. EclipseIts.Rmd)
#   - %params: a ref to hash of parameters/values for the execution.
sub knit_rmarkdown_svg($$$$) {
    my ($self, $plugin_id, $project_id, $r_file, $params) = @_;

    my @log;
    
    # Set vars.
    my $r_dir = "lib/Alambic/Plugins/$plugin_id/";
    my $r_md = $r_file;
    $r_file =~ s/(.*)\..*+/$1/;
    my $r_md_out = "${r_file}.svg";

    # Change the current working directory localy only.
    {
	local $CWD = $r_dir;
	# Now execute the main R script.
	my $r_cmd = "Rscript '$r_md' ";
	# Passing arguments: 2 first args are project.id and plugin.id
	$r_cmd .= $project_id . " " . $plugin_id;
	foreach my $key (sort keys %{$params}) {
	    $r_cmd .= " " . $params->{$key};
	}
	
	push( @log, "[Tools::R] Exec [$r_cmd] output to [$r_md_out]." );
	my @out = `$r_cmd 2>&1`;
    }
    
    # Move the generated main file to project output dir
    my $file_in = $r_dir . "/" . $r_md_out;
    my $dir_out = "projects/" . $project_id . "/output/";
    move( $file_in, $dir_out );

    return \@log;
}

sub _start_session() {
    
}


1;
