package Alambic::Model::DataSources;

use warnings;
use strict;

use Scalar::Util 'weaken';
use List::MoreUtils qw(uniq);
use Mojo::JSON qw( decode_json encode_json );
use Data::Dumper;


require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw( read_all_files
                 get_rules_sources );  


my %ds;



# Constructor
sub new {
    my $class = shift;
    my $app = shift;
    
    my $hash = {app => $app};
    weaken $hash->{app};

    return bless $hash, $class;
}


sub read_all_files() { 
    my $self = shift;

    $self->{app}->log->debug("[Model::DataSources] read_all_files.");
    my $config = $self->{app}->config;

    # Read data sources definition if it exists
    my $file_ds = $config->{'dir_conf'} . "/alambic_ds.json";
    if (-e $file_ds) {
        $self->{app}->log->info( "[Model::DataSources] Reading data sources definition from [$file_ds]." );

        my $json;
        do { 
            local $/;
            open my $fh, '<', $file_ds or die "Could not open data file [$file_ds].\n";
            $json = <$fh>;
            close $fh;
        };
        my $ds_ref = decode_json($json);
        %ds = %{$ds_ref->{'children'}};
    } else {
        %ds = (
            );
    }

}

sub get_list() {
    my @list = keys %ds;
    return \@list;
}

sub get_all_ds() {
    return \%ds;
}

sub add_ds() {

}

1;
