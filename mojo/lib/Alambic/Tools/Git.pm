package Alambic::Tools::Git;

use strict; 
use warnings;

use Alambic::Model::RepoFS;
use Git::Repository;
use Date::Parse;

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
my $git_url;
my $repofs;

# Constructor
sub new {
    my $class = shift;
    $git_url = shift;

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

sub url() {
    my ($self, $url) = @_;

    my $ret;
    if (scalar @_ > 1) {
	$git_url = $url;
    } else {
	$url = $git_url;
    }
    
    return $url;
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


# Function to get an pulld git repository locally, not even
# knowing if it's already there or not. If it exists, it will be pulld.
# If it doesn't, it is cloned.
#
# Params:
#   - $plugin_id: the name/id of the calling plugin, e.g. EclipseIts.
#   - $project_id: the id of the project analysed.
#   - $url: the url of the git repository to clone
sub git_clone_or_pull($$$$) {
    my ($self, $plugin_id, $project_id, $url) = @_;

    my @log;

    $url = $git_url if (not defined($url));
    my $dir = &get_src_path($self, $project_id);

    if (-e $dir) {
	# start from an existing working copy    
	push( @log, "[Tools::Git] Directory [$dir] exists." );
	eval {
	    my $r = Git::Repository->new( work_tree => $dir );
	    push( @log, "[Tools::Git] Version is " . $r->version );
	    @log = ( @log, @{&git_pull($self, $plugin_id, $project_id)} );
	};
    } else {
	# repository doesn't exist, clone src from git server.
	push( @log, "[Tools::Git] Directory [$dir] doesn't exist. Cloning." );
	@log = ( @log, @{&git_clone($self, $plugin_id, $project_id, $url)} );
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
    my ($self, $plugin_id, $project_id) = @_;
    
    my @log;

    push( @log, "[Tools::Git] Getting Git log for [$project_id]." );
    my $output = $git->run( ( 'log' ) );
    $repofs->write_input( $project_id, "import_git.txt", $output );
    push( @log, "[Tools::Git] Created file [${project_id}_import_git.txt] in input." );

    return \@log;
}

# Returns an array of commits
sub git_commits() {
    my ($self, $plugin_id, $project_id) = @_;
    

    my @log = $git->run( ('log', '--format=%H %at %s%n author [%aE]%n committer [%cE]', '--stat') );
    my $log_ = _parse_git_log( @log);
    
    return $log_;
}


# Utility to parse git log
# http://preaction.me/talks/Perl/Scripting-Git.html
sub _parse_git_log {
    my @lines = @_;
    
    my @commits;
    my %commit;
    my $id;
    for my $line ( @lines ) {
        if ( $line =~ /^(\w+) (\d+) (.*)$/ ) {
	    $id = $1;
	    $commit{'id'} = $1;
	    $commit{'time'} = $2;
	    $commit{'msg'} = $3;
	} elsif ( $line =~ /^\s+author\s\[([^]]+)\]/ ) {
	    $commit{'auth'} = $1;
	} elsif ( $line =~ /^\s+committer \[([^]]+)\]/ ) {
	    $commit{'cmtr'} = $1;
	} elsif ( $line =~ /^\s+(\d+) files? changed(, (\d+) insert[^,]+)?(, (\d+) del[^,]+)?.*$/ ) {
	    $commit{'mod'} = $1;
	    $commit{'add'} = $3 if defined($3);
	    $commit{'del'} = $5 if defined($5);
	    my %commit_ = %commit;
	    push( @commits, \%commit_ );
	    undef %commit;
	} elsif ( $line =~ /^\s*$/ ) {
	} else { 
	    print "Failed [$line].\n" unless ($line =~ m!\|!);
	}
    }

    return \@commits;
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
sub git_pull($$$$) {
    my ($self, $plugin_id, $project_id) = @_;
    
    my @log;
    push( @log, "[Tools::Git] Pulling from origin." );
    my @output = $git->run( ( 'pull' ) );
    if (scalar @output == 1 && $output[0] =~ m!Already up-to-date!) {
	push( @log, "[Tools::Git] Already up-to-date." );
    } else {
	push( @log, "[Tools::Git] Pull output: " . @output . "." );
    }
    
    return \@log;
}




1;
