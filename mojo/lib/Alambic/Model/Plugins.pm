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
                     get_list_plugins_data
                     get_list_plugins_metrics
                     get_list_plugins_figs
                     get_list_plugins_info
                     get_list_plugins_recs
                     get_list_plugins_viz
                     get_plugin
                     run_plugin
                     test
                   );  
                     # get_list_data
                     # get_list_metrics
                     # get_list_figs
                     # get_list_info
                     # get_list_recs
                     # get_list_viz


my %plugins;

# array of plugin ids ordered by type.
my %plugins_type;
my %plugins_ability;

# Constructor
sub new {
    my ($class) = @_;

    &_read_plugins();
    
    return bless {}, $class;
}


sub _read_plugins() { 

    # Clean hashes before reading files.
    %plugins = ();
    %plugins_type = ();
    %plugins_ability = ();

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
	foreach my $a ( @{$conf->{'ability'}} ) {
	    push( @{$plugins_ability{ $a }}, $conf->{'id'} );
	}
    }
#    print Dumper(%plugins_type);
#    print Dumper(%plugins_ability);
    
}


sub get_list_plugins_pre() {
    return $plugins_type{'pre'} || [];
}


sub get_list_plugins_cdata() {
    return $plugins_type{'cdata'} || [];
}


sub get_list_plugins_post() {
    return $plugins_type{'post'} || [];
}


sub get_list_plugins_global() {
    return $plugins_type{'global'} || [];
}


sub get_names_all() {
    my @list = keys %plugins;
    my %list;
    foreach my $p (@list) {
	$list{$p} = $plugins{$p}->get_conf()->{'name'};
    }
    
    return \%list;
}


sub get_list_plugins_data() {
    return $plugins_ability{'data'} || [];
}


sub get_list_plugins_metrics() {
    return $plugins_ability{'metrics'} || [];
}


sub get_list_plugins_figs() {    
    return $plugins_ability{'figs'} || [];
}


sub get_list_plugins_info() {    
    return $plugins_ability{'info'} || [];
}


sub get_list_plugins_recs() {    
    return $plugins_ability{'recs'} || [];
}


sub get_list_plugins_viz() {    
    return $plugins_ability{'viz'} || [];
}



# sub get_list_data() {
#     return $plugins_ability{'data'} || [];
# }


# sub get_list_metrics() {
#     return $plugins_ability{'metrics'} || [];
# }


# sub get_list_figs() {    
#     return $plugins_ability{'figs'} || [];
# }


# sub get_list_info() {    
#     return $plugins_ability{'info'} || [];
# }


# sub get_list_recs() {    
#     return $plugins_ability{'recs'} || [];
# }


# sub get_list_viz() {    
#     return $plugins_ability{'viz'} || [];
# }

sub get_plugin($) {
    my ($self, $plugin_id) = @_;    
    return $plugins{$plugin_id};
}

sub run_plugin($$$) {
    my ($self, $project_id, $plugin_id, $conf) = @_;    
    return $plugins{$plugin_id}->run_plugin($project_id, $conf);
}

1;
