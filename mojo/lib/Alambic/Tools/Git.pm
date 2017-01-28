package Alambic::Tools::Git;

use strict; 
use warnings;

use Alambic::Model::RepoFS;
use File::chdir;
use File::Copy;
use Try::Tiny;
use Git::Repository;
#use File::Path qw(remove_tree);
    
use Data::Dumper;

# Main configuration hash for the tool
my %conf = (
    "id" => "git",
    "name" => "Git Tool",
    "desc" => "Provides Git commands and features.",
    "ability" => [ 
#	"install", 
	"methods",
	"project" 
    ],
    "type" => "tool",
    "params" => {
	"path_git" => "The absolute path to the git binary.",
    },
    "provides_methods" => {
        "git_clone" => "Clone a project git repository locally.",
        "git_pull" => "Execute a pull from a git repository.",
        "git_log" => "Retrieves log from a local git repository.",
    },
);

my $git;
my $repofs;

# Constructor
sub new {
    my ($class) = @_;

    $git = Git::Repository->new();
    $repofs = Alambic::Model::RepoFS->new();
    
    return bless {}, $class;
}

sub get_conf() {
    return \%conf;
}

sub get_src_path($) {
    my ($self, $project) = @_;
    
    return "projects/" . $project . "/src";
}

sub install() {
}

sub version() {

    my $git_cmd = "git --version";
    my @out = `$git_cmd 2>&1`;
    chomp @out;

    for my $l ( @out ) {
	if ( $l =~ m/^(git version .*)$/ ) {
	    return $1;
	} else {
	    return "Git version not found.";
	}
    }
    return "Git version not found.";
}

sub test() {

    my @log;

    my $path_git;
    for my $path ( split /:/, $ENV{PATH} ) {
	if ( -f "$path/git" && -x _ ) { $path_git = "$path/git"; last; }
    }

    if ( defined($path_git) ) {
	push( @log, "OK: Git exec found in PATH at [$path_git]." );
    } else {
	push( @log, "ERROR: Git exec NOT found in PATH." );
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
#   - $url: the url of the git repository to clone
#   - %params: a ref to hash of parameters/values for the execution.
sub git_clone($$$$) {
    my ($self, $plugin_id, $project_id, $url, $params) = @_;

    my @log;

    my $dir = &get_src_path($self, $project_id);

    push( @log, "[Tools::Git] Cloning [$url] to [$dir]." );
    Git::Repository->run( clone => $url, $dir );

    # Set vars.


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
#   - $url: the url of the git repository to clone
#   - %params: a ref to hash of parameters/values for the execution.
sub git_log($$$$) {
    my ($self, $plugin_id, $project_id, $params) = @_;
    
    my @log;

    push( @log, "[Tools::Git] Getting Git log for [$project_id]." );
    my $output = $git->run( ( 'log' ) );
    $repofs->write_input( $project_id, "import_git.txt", $output );
    push( @log, "[Tools::Git] Created file in input." );

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
#   - $url: the url of the git repository to clone
#   - %params: a ref to hash of parameters/values for the execution.
sub git_update($$$$) {
    my ($self, $plugin_id, $project_id, $url, $params) = @_;
    
    my @log;

    my @output = $git->run( ( 'log' ) );
    my $dir = &get_src_path($self, $project_id);

    push( @log, "[Tools::Git] NOT IMPLEMENTED Updating [$url] to [$dir]." );
#    Git::Repository->run( clone => $url, $dir );

    # Set vars.


    return \@log;
}




1;
