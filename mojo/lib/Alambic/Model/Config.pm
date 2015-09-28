package Alambic::Model::Config;

use warnings;
use strict;

use Scalar::Util 'weaken';
use Mojo::JSON qw( decode_json encode_json );
use Data::Dumper;


require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw( read_files
                 write_files
                 get_title
                 get_name
                 get_desc );  


my %config;

sub new { 
    my $class = shift;
    my $app = shift;
    
    &_read_files($app->config);

    my $hash = {app => $app};
    weaken $hash->{app};

    return bless $hash, $class;
}

sub read_files() {
    my $self = shift;
    
    &_read_files($self->{app}->config);
}

sub _read_files() {
    my $config = shift;

    my $file_conf = $config->{'file_conf'};
    my $conf_str;
    open my $fh, '<', $file_conf or die "Could not open conf file [$file_conf].\n";
    while (<$fh>) { chomp; $conf_str .= $_; }
    close $fh;

    my $conf = decode_json( $conf_str );
    %config = %{$conf};
    
    return 1;
}

sub write_files() {
    my $self = shift;

    my $file_conf = $self->{app}->config->{'file_conf'};
    my $json_content = encode_json(\%config);
    do { 
        local $/;
        open my $fh, '>', $file_conf or die "Could not open conf file [$file_conf].\n";
        print $fh $json_content;
        close $fh;
    };
    
    return 1;
}

sub get_title() {
    return $config{'title'};
}

sub get_name() {
    return $config{'name'};
}

sub get_desc() {
    return $config{'desc'};
}

sub get_colours() {
    return $config{'colours'};
}

sub set_conf($$$) {
    my $self = shift;
    my $title = shift;
    my $name = shift;
    my $desc = shift;

    $config{'title'} = $title;
    $config{'name'} = $name;
    $config{'desc'} = $desc;

    # Write new values to file.
    &write_files($self);
}

sub set_title($) {
    my $self = shift;
    my $title = shift;

    $config{'title'} = $title;

    # Write new values to file.
    &write_files($self);

    return 1;
}

sub set_name($) {
    my $self = shift;
    my $name = shift;

    $config{'name'} = $name;

    # Write new values to file.
    &write_files($self);

    return 1;
}

sub set_desc($) {
    my $self = shift;
    my $desc = shift;

    $config{'desc'} = $desc;

    # Write new values to file.
    &write_files($self);

    return 1;
}


1;
