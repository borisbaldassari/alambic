package Alambic::Model::Plugins;

use warnings;
use strict;

use Module::Load;
use Data::Dumper;


require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw( 
                     get_list_all
                     get_names_all
                     get_list_metrics
                     get_list_figs
                     get_list_info
                     get_list_recs
                     get_list_viz
                     get_list_post
                     get_list_global
                     get_plugin
                     run_plugin
                     test
                   );  


my %plugins;

my @plugins_metrics;
my @plugins_info;
my @plugins_figs;
my @plugins_recs;
my @plugins_post;
my @plugins_global;

my %customdata;


# Constructor
sub new {
    my ($class) = @_;

    &_read_plugins();
    
    return bless {}, $class;
}


sub _read_plugins() { 

    # Read plugins directory.
    my @plugins_list = <lib/Alambic/Plugins/*.pm>;
    foreach my $plugin_path (@plugins_list) {
        $plugin_path =~ m!lib/(.+).pm!;
        my $plugin = $1;
	$plugin =~ s!/!::!g;

        $plugin_path =~ m!.+/([^/\\]+).pm!;
        my $plugin_name = $1;

	autoload $plugin;

        my $conf = $plugin->get_conf();
        $plugins{ $conf->{'id'} } = $plugin;
    }
    
}


sub get_list_all() {
    my @list = keys %plugins;
#    push @list, keys %customdata;
    @list = sort @list;
    
    return \@list;
}


sub get_names_all() {
    my @list = keys %plugins;
    my %list;
#    print Dumper(%plugins);
    foreach my $p (@list) {
	$list{$p} = $plugins{$p}->get_conf()->{'name'};
    }
    
    return \%list;
}


sub get_list_metrics() {
    my @list = map { $plugins{$_}{'id'} if grep('metrics', $plugins{$_}{'ability'}) } keys %plugins;
    return \@list;
}


sub get_list_figs() {    
    my @list = map { $plugins{$_}{'id'} if grep('figs', $plugins{$_}{'ability'}) } keys %plugins;
    return \@list;
}


sub get_list_info() {    
    my @list = map { $plugins{$_}{'id'} if grep('info', $plugins{$_}{'ability'}) } keys %plugins;
    return \@list;
}


sub get_list_recs() {    
    my @list = map { $plugins{$_}{'id'} if grep('recs', $plugins{$_}{'ability'}) } keys %plugins;
    return \@list;
}


# FIXME
sub get_list_viz() {    
    my @list = map { $plugins{$_}{'id'} if grep('recs', $plugins{$_}{'ability'}) } keys %plugins;
    return \@list;
}


# FIXME
sub get_list_post() {    
    my @list = map { $plugins{$_}{'id'} if grep('recs', $plugins{$_}{'ability'}) } keys %plugins;
    return \@list;
}

# FIXME
sub get_list_global() {     
    my @list = map { $plugins{$_}{'id'} if grep('recs', $plugins{$_}{'ability'}) } keys %plugins;
    return \@list;
}


sub get_plugin($) {
    my ($self, $plugin_id) = @_;    
    return $plugins{$plugin_id};
}

sub run_plugin($$$) {
    my ($self, $project_id, $plugin_id, $conf) = @_;    
    return $plugins{$plugin_id}->run_plugin($project_id, $conf);
}

1;
