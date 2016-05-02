package Alambic::Model::Alambic;

use warnings;
use strict;

use Alambic::Model::Config;
use Alambic::Model::Project;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw( 
                     
                   );  

my $config;

# List of projects for this instance.
my %projects;

# Create a new Alambic object.
sub new { 
    my ($class, $args) = @_;

    $config = Alambic::Model::Config->new();
    
    return bless {}, $class;
}


sub create_project($$) {
    my ($self, $id, $name) = @_;

    my $project = Alambic::Model::Project->new($id, $name);

    $projects{$id} = $project;

    return $project;
}

sub get_project($) {
    my ($self, $id) = @_;

    return $projects{$id};
}

1;
