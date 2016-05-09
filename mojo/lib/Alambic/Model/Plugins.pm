package Alambic::Model::Plugins;

use warnings;
use strict;

use Module::Load;
use Data::Dumper;


require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw( 
                     get_names_all
                     get_list_plugins_pre
                     get_list_plugins_cdata
                     get_list_plugins_post
                     get_list_plugins_global
                     get_list_ability_metrics
                     get_list_ability_figs
                     get_list_ability_info
                     get_list_ability_recs
                     get_list_ability_viz
                     get_plugin
                     run_plugin
                     test
                   );  


my %plugins;

# array of plugin ids ordered by type.
my %plugins_type;

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
	push( @{$plugins_type{ $conf->{'type'} }}, $conf->{'id'} );
    }
    
}


sub get_list_plugins_pre() {
    return $plugins_type{'pre'};
}


sub get_list_plugins_cdata() {
    return $plugins_type{'cdata'};
}


sub get_list_plugins_post() {
    return $plugins_type{'post'};
}


sub get_list_plugins_global() {
    return $plugins_type{'global'};
}


sub get_names_all() {
    my @list = keys %plugins;
    my %list;
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
