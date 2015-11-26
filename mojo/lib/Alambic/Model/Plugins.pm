package Alambic::Model::Plugins;

use warnings;
use strict;

use Scalar::Util 'weaken';
use Mojo::JSON qw( decode_json encode_json );
use Data::Dumper;


require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw( read_all_files
                 get_list_all get_list_metrics get_list_info 
                 get_rules_sources );  


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
    my @plugins = <lib/Alambic/Plugins/*.pm>;
    foreach my $plugin (@plugins) {
        $plugin =~ m!.+/([^/\\]+).pm!;
        my $plugin_name = $1;
        $self->{app}->plugins->register_plugin('Alambic::Plugins::' . $plugin_name, $self->{app});
        my $al_plugin = $self->{app}->plugins->load_plugin('Alambic::Plugins::' . $plugin_name);
        my $conf = $al_plugin->get_conf();
        $plugins{ $conf->{'id'} } = $al_plugin;
    }

    my @customdata = <lib/Alambic/ManualData/*.pm>;
    foreach my $plugin (@customdata) {
        $plugin =~ m!.+/([^/\\]+).pm!;
        my $plugin_name = $1;
        $self->{app}->plugins->register_plugin('Alambic::Plugins::' . $plugin_name, $self->{app});
        my $al_plugin = $self->{app}->plugins->load_plugin('Alambic::Plugins::' . $plugin_name);
        my $conf = $al_plugin->get_conf();
        $customdata{ $conf->{'id'} } = $al_plugin;
    }
    
    
}

sub get_list_all() {
    my @list = keys %plugins;
    
    return \@list;
}

sub get_list_metrics() {
    my @list = map { return $plugins{$_}{'id'} if grep('metrics', $plugins{$_}{'ability'}) } keys %plugins;
    return \@list;
}

sub get_list_info() {

}

sub get_list_viz() {

}

sub get_plugin($) {
    my $self = shift;
    my $plug_id = shift;

    return $plugins{$plug_id};
}

1;
