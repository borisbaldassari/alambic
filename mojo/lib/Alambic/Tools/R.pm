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
        "knitr" => "",
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
sub knit_rmarkdown_inc($$) {
    my ($self, $plugin_id, $project_id, $r_file, $params) = @_;

    my @log;
    
    # Set vars.
    my $r_dir = "lib/Alambic/Plugins/$plugin_id/";
    my $r_md = $r_file;
    $r_file =~ s/(.*)\..*+/$1/;
    my $r_md_out = "${r_file}.inc";
    push( @log, "[$r_md] output to [$r_md_out]." );

    # Change the current working directory localy only.
    {
	local $CWD = $r_dir;
	# Create dir for figures.
	if (! -d "figures/" ) {
	    print "Creating directory [figures/].\n";
	    mkdir "figures/";
	}
	
	# Now execute the main R script.
	my $r_cmd = "Rscript -e \"library(rmarkdown); ";
	$r_cmd .= "project.id <- '${project_id}'; plugin.id <- '$plugin_id'; ";
	foreach my $key (keys %{$params}) {
	    $r_cmd .= $key . " <- " . $params->{$key};
	}
	$r_cmd .= "rmarkdown::render('${r_md}', output_format='html_fragment', output_file='$r_md_out')\"";
	
	push( @log, "[Tools::R] Exec [$r_cmd]." );
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
	push( @log, "[Tools::R] Moved file from ${file} to $dir_out_fig. ret $ret." );
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
sub knit_rmarkdown_html($$) {
    my ($self, $plugin_id, $project_id, $r_file, $params) = @_;

    my @log;
    
    # Set vars.
    my $r_dir = "lib/Alambic/Plugins/$plugin_id/";
    my $r_md = $r_file;
    $r_file =~ s/(.*)\..*+/$1/;
    my $r_md_out = "${r_file}.html";
    push( @log, "[$r_md] output to [$r_md_out]." );

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
	
	push( @log, "[Tools::R] Exec [$r_cmd]." );
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
	push( @log, "[Tools::R] Moved file from ${file} to $dir_out_fig. ret $ret." );
    }

    return \@log;
}

sub knit_rhtml($$) {
    
}

sub _start_session() {
    
}



# Run plugin: retrieves data + compute_data 
sub run_plugin($$) {
    my ($self, $project_id, $conf) = @_;

    print "CONF is " . Dumper($conf);
    
    my %ret = (
	'metrics' => {},
	'info' => {},
	'recs' => {},
	'log' => [],
	);

    my $repofs = Alambic::Model::RepoFS->new();

    my $project_pmi = $conf->{'project_pmi'};

    $ret{'log'} = &_retrieve_data( $project_id, $project_pmi, $repofs );
    
    my $tmp_ret = &_compute_data( $project_id, $project_pmi, $repofs );

    $ret{'metrics'} = $tmp_ret->{'metrics'};
    $ret{'info'} = $tmp_ret->{'info'};
    $ret{'recs'} = $tmp_ret->{'recs'};
    push( @{$ret{'log'}}, @{$tmp_ret->{'log'}} );
    
    return \%ret;
}


1;
