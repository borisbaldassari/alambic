package Alambic::Model::Config;

use warnings;
use strict;

#use Scalar::Util 'weaken';
use Mojo::JSON qw( decode_json encode_json );
use Data::Dumper;


require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw( 
                     get_conf 
                     get_name
                     get_desc 
                     get_dir_projects 
                     get_pg_minion
                     get_pg_alambic
                   );  


# Default values for configuration. These can be overriden by the constructor or
# through the setters.
# TODO: add setters for config
my %config = (
    'name' => 'DefaultName',
    'desc' => 'Default Description',
    'dir_projects' => 'projects/',
    'conf_pg_minion' => '',
    'conf_pg_alambic' => '',
);

# Create a new config module with default values. Optional parameter $conf
# looks like %config
sub new { 
    my ($class, $conf) = @_;

    # If config is passed, use it.
    if (@_ == 2 and ref($conf) =~ m!HASH!) {
	foreach my $param (keys %$conf) {
	    $config{$param} = $conf->{$param};
	}
    }
    
    return bless {}, $class;
}

sub get_conf() {
    return \%config;
}

sub get_name() {    
    return $config{'name'};
}

sub get_desc() {    
    return $config{'desc'};
}

sub get_dir_projects() {    
    return $config{'dir_projects'};
}

sub get_pg_minion() {    
    return $config{'conf_pg_minion'};
}

sub get_pg_alambic() {    
    return $config{'conf_pg_alambic'};
}


1;
