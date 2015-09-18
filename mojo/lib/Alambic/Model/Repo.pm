package Alambic::Model::Repo;

use warnings;
use strict;

use Scalar::Util 'weaken';

use Mojo::JSON qw( decode_json encode_json );
use Git::Wrapper;
use File::Copy qw( move );
use File::Path qw( remove_tree );

use Data::Dumper;


require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw( read_all_files
                 get_list );  

my %repo;
my $git;

my @files_push = (
    'conf/', 
    'data/', 
    'lib/',
    'log/.keepme', 
    'public/',
    'script/',
    't/',
    'templates',
    'alambic.conf',
    );



sub new { 
    my $class = shift;
    my $app = shift;
    
    my $hash = {app => $app};
    weaken $hash->{app};

    $git = Git::Wrapper->new( $app->home->rel_dir('/') );

    return bless $hash, $class;
}

sub read_status($) {
    my $self = shift;
    
    # Detect if the hierarchy is under git version control.
    if (-d $self->{app}->home->rel_dir('/') . '/.git') {
        # If so, get the origins (fetch/push) of repo.
        $self->{app}->log->info("[Model::Repo] .git exists in project.");
        my @out = $git->remote( { "verbose" => 1 } );
        $out[0] =~ m!origin\s(.+)\s\(fetch\)!i;
        $repo{'url_fetch'} = $1;
        $out[1] =~ m!origin\s(\S+)\s\(push\)!;
        $repo{'url_push'} = $1;
    } else {
        $self->{app}->log->info("[Model::Repo] .git does not exist.");
    }

    return 1;
}

sub init {
    my $self = shift;
    my $url = shift;

    my $home = $self->{app}->home->rel_dir('/');

    # Detect if .git already exists, and make a backup of it if so.
    if (-d $home . '/.git') {
        if (-d $home . '/.git_old') {
            $self->{app}->log->info("[Model::Repo] Delete .git_old.");
            remove_tree($home . '/.git_old');
        } 
        $self->{app}->log->info("[Model::Repo] rename .git to .git_old.");
        move($home . '/.git', $home . '/.git_old');
    }

    
    $self->{app}->log->info("[Model::Repo] About to re-init.");
    $git->init();
    $git->RUN( 'remote', 'add', 'origin', $url);
    
    # Add needed files to commit.
    foreach my $path (@files_push) {
        $git->add($path);
    }

    # Commit all added files.
    $git->commit( { 'message' => "[Alambic] Initial push." });
    $git->RUN( 'push', 'origin', 'master', { 'set-upstream' => 1, 'force' => 1 } );

    return 1;
}

sub push {
    my $self = shift;
  
    # Add needed files to commit.
    foreach my $path (@files_push) {
        $git->add($path);
    }

    # Commit all added files.
    $git->commit( { 'message' => "[Alambic] Another push." });
    $git->push();

    return 1;
}

sub get_updates {
    my $self = shift;
    
    # Commit all added files.
    my @logs = $git->log();
    my @commits = map { $_->{'message'} } @logs;

    return \@logs;
}

sub get_file_last($) {
    my $self = shift;
    my $file = shift;
    
    # Commit all added files.
    my @content_json = $git->show( "HEAD~1:$file" );
    my $content_json = join(' ', @content_json);
    my $content = decode_json( $content_json );

    return $content;
}

sub get_repo_url_fetch() {
    return $repo{'url_fetch'};
}

sub get_repo_url_push() {
    return $repo{'url_push'};
}

1;
