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
                     get_plugins
                     active
                     metrics
                     indicators
                     attributes
                     recs
                     add_plugin
                     run_plugin
                     run_plugins
                     run_project
                   );  

######################################
# Data associated with a project
my ($project_name, $project_id, $project_desc, $project_active);

my %plugins;
# my %plugins = (
#     "plugin_id1" => {
# 	"param1" => "value1",
# 	"param2" => "value2",
#     },
#     );

my %indicators;
my %attributes;
my %metrics;
my %recs;
######################################

# A ref to the Plugins module.
my $plugins_module;

# Constructor
sub new {
    my ($class, $id, $name, $plugins, $data) = @_;

    $project_id = $id;
    $project_name = $name;    
    
    $plugins_module = Alambic::Model::Plugins->new();
    if (defined($plugins)) {
	foreach my $plugin_id (keys %{$plugins}) {
	    $plugins{$plugin_id} = $plugins->{$plugin_id};
	}
    }

    if ( defined($data) ) {
	%metrics = %{$data->{'metrics'} || {}};
	%indicators = %{$data->{'indicators'} || {}};
	%attributes = %{$data->{'attributes'} || {}};
	%recs = %{$data->{'recs'} || {}};
    }

    return bless {}, $class;
}

sub get_id() {
    return $project_id;
}

sub get_name() {
    return $project_name;
}

sub desc() {
    my ($self, $desc) = @_;

    if (scalar @_ > 1) {
	$project_desc = $desc;
    }
    
    return $project_desc;
}

sub active() {
    my ($self, $active) = @_;

    if (scalar @_ > 1) {
	$project_active = $active;
    }
    
    return $project_active;
}

sub get_plugins() {
    return \%plugins;
}

sub metrics() {
    my ($self, $metrics) = @_;

    if (scalar @_ > 1) {
	%metrics = %{$metrics};
    } 
	   
    return \%metrics;
}

sub indicators() {
    return \%metrics;
}

sub attributes() {
    return \%metrics;
}

sub recs() {
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

    my @log;

    foreach my $plugin_id (keys %plugins) {
	my $ret = $plugins_module->get_plugin($plugin_id)->run_plugin($project_id, $plugins{$plugin_id});

	foreach my $metric (sort keys %{$ret->{'metrics'}} ) {
	    $metrics{$metric} = $ret->{'metrics'}{$metric};
	}
	
	foreach my $rec (sort keys %{$ret->{'recs'}} ) {
	    $recs{$rec} = $ret->{'recs'}{$rec};
	}

	@log = (@log, @{$ret->{'log'}});
    }

    return { "metrics" => \%metrics, "recs" => \%recs, "log" => \@log };
}

sub run_qm() {

}

sub run_post() {

}

sub run_project() {
    my ($self) = @_;

    # Run plugins
    my $plugins_data = $self->run_plugins();
    
    # Run plugins
    my $qm_data = $self->run_qm();
    
    # Run post plugins
    my $post_data = $self->run_post();
    
    return $plugins_data;
}


1;
