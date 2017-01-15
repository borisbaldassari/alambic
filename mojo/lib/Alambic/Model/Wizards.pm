package Alambic::Model::Wizards;

use warnings;
use strict;

use Module::Load;
use Data::Dumper;


require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw( 
                     get_names_all
                     get_conf_all
                     get_plugin
                     run_plugin
                     test
                   );  


my %wizards;


# Constructor
sub new {
    my ($class) = @_;

    &_read_wizards();
    
    return bless {}, $class;
}


sub _read_wizards() { 

    # Clean hashes before reading files.
    %wizards = ();

    # Read wizards directory.
    my @wizards_list = <lib/Alambic/Wizards/*.pm>;
    foreach my $wizard_path (@wizards_list) {
        $wizard_path =~ m!lib/(.+).pm!;
        my $wizard = $1;
	$wizard =~ s!/!::!g;

	autoload $wizard;
        my $conf = $wizard->get_conf();
        $wizards{ $conf->{'id'} } = $wizard;
    }

}


sub get_names_all() {
    my @list = keys %wizards;
    my %list;
    foreach my $p (@list) {
	$list{$p} = $wizards{$p}->get_conf()->{'name'};
    }
    
    return \%list;
}


sub get_conf_all() {
    my @list = keys %wizards;
    my %list;
    foreach my $p (@list) {
	$list{$p} = $wizards{$p}->get_conf();
    }
    
    return \%list;
}


sub get_wizard($) {
    my ($self, $wizard_id) = @_;
    return $wizards{$wizard_id};
}


1;
