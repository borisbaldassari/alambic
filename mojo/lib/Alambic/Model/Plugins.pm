package Alambic::Model::Plugins;

use warnings;
use strict;

use Scalar::Util 'weaken';
use Mojo::JSON qw( decode_json encode_json );
use Data::Dumper;


require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw( read_all_files
                 get_list_all
                 get_list_pis
                 get_list_cds 
                 get_list_metrics get_list_viz
                 get_plugin );  


my %plugins;

my @plugins_metrics;
my @plugins_files;
my @plugins_viz;

my %customdata;

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

    $self->{app}->log->debug("[Model::Plugins] read_all_files.");
    my $config = $self->{app}->config;

    # Read plugins directory.
    my @plugins_list = <lib/Alambic/Plugins/*.pm>;
    foreach my $plugin (@plugins_list) {
        $plugin =~ m!.+/([^/\\]+).pm!;
        my $plugin_name = $1;
        $self->{app}->plugins->register_plugin('Alambic::Plugins::' . $plugin_name, $self->{app});
        my $al_plugin = $self->{app}->plugins->load_plugin('Alambic::Plugins::' . $plugin_name);
        my $conf = $al_plugin->get_conf();
        $plugins{ $conf->{'id'} } = $al_plugin;
    }

    my @customdata_list = <lib/Alambic/CustomData/*.pm>;
    foreach my $plugin (@customdata_list) {
        $plugin =~ m!.+/([^/\\]+).pm!;
        my $plugin_name = $1;
        $self->{app}->plugins->register_plugin('Alambic::CustomData::' . $plugin_name, $self->{app});
        my $al_plugin = $self->{app}->plugins->load_plugin('Alambic::CustomData::' . $plugin_name);
        my $conf = $al_plugin->get_conf();
        $customdata{ $conf->{'id'} } = $al_plugin;
    }
    
}

sub get_list_all() {
    my @list = keys %plugins;
    push @list, keys %customdata;
    @list = sort @list;
    
    return \@list;
}

sub get_list_pis() {
    my @list = keys %plugins;
    
    return \@list;
}

sub get_list_cds() {
    my @list = keys %customdata;
    
    return \@list;
}

sub get_list_metrics() {
    my @list = map { $plugins{$_}{'id'} if grep('metrics', $plugins{$_}{'ability'}) } keys %plugins;
    return \@list;
}

sub get_list_viz() {    

    my @viz;
    foreach my $plugin (keys %plugins) {
        if ( grep( /^viz$/, @{$plugins{$plugin}->get_conf()->{'ability'}} ) ) {
            push( @viz, $plugin );
        }
    }
#    my @list = grep { 
#        'viz' ~~ @{$plugins{$_}->get_conf()->{'ability'}}
#    } keys %plugins;

    return \@viz;
}

sub get_plugin($) {
    my $self = shift;
    my $plug_id = shift;

    if ( exists($plugins{$plug_id}) ) {
        return $plugins{$plug_id};
    } elsif ( exists($customdata{$plug_id}) ) {
        return $customdata{$plug_id};
    } else {
        $self->{app}->log->error("[Model::Plugins] Could not find Custom data plugin [$plug_id].");        
        return undef;
    }
}

1;
