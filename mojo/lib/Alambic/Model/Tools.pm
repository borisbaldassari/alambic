package Alambic::Model::Tools;

use warnings;
use strict;

use Module::Load;
use Data::Dumper;


require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw( 
                     get_tool
                     get_list_all
                   );  


my %tools;


# Constructor
sub new {
    my ($class) = @_;

    &_read_tools();
    
    return bless {}, $class;
}


sub _read_tools() { 

    # Read tools directory.
    my @tools_list = <lib/Alambic/Tools/*.pm>;
    foreach my $tool_path (@tools_list) {
        $tool_path =~ m!lib/(.+).pm!;
        my $tool = $1;
	$tool =~ s!/!::!g;

        $tool_path =~ m!.+/([^/\\]+).pm!;
        my $tool_name = $1;

	autoload $tool;

        my $conf = $tool->get_conf();
        $tools{ $conf->{'id'} } = $tool;
    }
    
}


sub get_list_all() {
    my @list = sort keys %tools;
    
    return \@list;
}


sub get_tool($) {
    my ($self, $tool_id) = @_;    
    return $tools{$tool_id};
}

1;
