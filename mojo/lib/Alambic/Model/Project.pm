package Alambic::Model::Project;

use warnings;
use strict;

use Data::Dumper;

use Alambic::Model::Plugins;
#use Alambic::Model::Analysis;
#use Alambic::Model::Config;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw( 
                     get_id
                     get_name
                     add_plugin
                     run_plugin
                     run_plugins
                   );  

# Data associated with a project
my ($project_name, $project_id);
my %info;

my %plugins;
my $plugins_module;

# my %plugins = (
#     "plugin_id1" => {
# 	"param1" => "value1",
# 	"param2" => "value2",
#     },
#     );

my %attributes;
my %questions;
my %metrics;
my %recs;


# Constructor
sub new {
    my ($class, $id, $name) = @_;

    $project_id = $id;
    $project_name = $name;    
    
    $plugins_module = Alambic::Model::Plugins->new();
#    my $config = Alambic::Model::Config->new();
#    my $name = $config->get_name();

    return bless {}, $class;
}

sub get_id() {
    return $project_id;
}

sub get_name() {
    return $project_name;
}

sub get_metrics() {
    return \%metrics;
}

sub add_plugin($$) {
    my ($self, $plugin_id, $plugin_conf) = @_;

    $plugins{$plugin_id} = $plugin_conf;
}

sub run_plugin($) {
    my ($self, $plugin_id) = @_;

    my $ret = $plugins_module->get_plugin($plugin_id)->run_plugin($project_id, $plugins{$plugin_id});

    foreach my $metric (sort keys %{$ret->{'metrics'}} ) {
	$metrics{$metric} = $ret->{'metrics'}{$metric};
    }

    foreach my $rec (sort keys %{$ret->{'recs'}} ) {
	$recs{$rec} = $ret->{'recs'}{$rec};
    }
    
    return $ret->{'log'};
}

sub run_plugins() {
    my ($self) = @_;

    
}


1;
