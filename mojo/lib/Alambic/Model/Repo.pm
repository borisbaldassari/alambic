package Alambic::Model::Repo;

use warnings;
use strict;

use Scalar::Util 'weaken';

use Mojo::JSON qw( decode_json encode_json );
use Git::Wrapper;

use Data::Dumper;


require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw( read_all_files
                 get_list );  

my %repo;

sub new { 
    my $class = shift;
    my $app = shift;
    
    my $hash = {app => $app};
    weaken $hash->{app};

    return bless $hash, $class;
}

sub init($) {
    my $self = shift;
    my $url = shift;
    
    print "[Model::Repo] init.\n";

    # Detect if the hierarchy is under git version control.
    if (-d $self->{app}->home->rel_dir('/') . '/.git') {
        $self->{app}->log->info("[Model::Repo] .git exists in project. Switching to production mode.");
        $self->{app} = $self->{app}->mode('production');
    } else {
        $self->{app}->log->info("[Model::Repo] .git does not exist. Switching to development mode.");
        $self->{app} = $self->{app}->mode('development');
    }

    $repo{'url'} = $url;

    my $g = Git::Wrapper->new( $self->{app}->home->rel_dir('/') );

    return 1;
}

sub get_repo_url() {
    return $repo{'url'};
}

1;
