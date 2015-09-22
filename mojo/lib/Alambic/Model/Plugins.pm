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

    # Read plugins directory.
    my @plugins = <'lib/Alambic/Plugins'/*.pm>;
    foreach my $plugin (@plugins) {
        $plugin =~ m!.+/([^/\\]+).pm!;
        my $plugin_name = $1;
        $self->{app}->plugins->register_plugin('Alambic::Plugins::' . $plugin_name, $self->{app});
        my $al_plugin = $self->{app}->plugins->load_plugin('Alambic::Plugins::' . $plugin_name);
        my $conf = $al_plugin->get_conf();
        $plugins{ $conf->{'id'} } = $al_plugin;
    }


    # Read data sources definition if it exists
    # my $file_ds = $config->{'dir_conf'} . "/alambic_ds.json";
    # if (-e $file_ds) {
    #     $self->{app}->log->info( "[Model::DataSources] Reading data sources definition from [$file_ds]." );

    #     my $json;
    #     do { 
    #         local $/;
    #         open my $fh, '<', $file_ds or die "Could not open data file [$file_ds].\n";
    #         $json = <$fh>;
    #         close $fh;
    #     };
    #     my $ds_ref = decode_json($json);
    #     %ds = %{$ds_ref->{'children'}};
    # } else {
    #     %ds = (
    #         );
    # }

}

sub get_list_all() {
    my @list = keys %plugins;
    return \@list;
}

sub get_list_metrics() {
    my @list = map { return $plugins{'id'} if grep('metrics', $_{'ability'}) } keys %plugins;
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
