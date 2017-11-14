#########################################################
#
# Copyright (c) 2015-2017 Castalia Solutions and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
#
# Contributors:
#   Boris Baldassari - Castalia Solutions
#
#########################################################

package Alambic::Model::Wizards;

use warnings;
use strict;

use Module::Load;
use Data::Dumper;


require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(
  get_names_all
  get_conf_all
  get_plugin
  run_plugin
  test
);


my %wizards;


# Constructor to build a new Wizards object.
sub new {
  my ($class) = @_;

  &_read_wizards();

  return bless {}, $class;
}

# Read the Wizard plugins from the file system.
sub _read_wizards() {

  # Clean hashes before reading files.
  %wizards = ();

  # Read wizards directory.
  my @wizards_list = <lib/Alambic/Wizards/*.pm>;
  foreach my $wizard_path (@wizards_list) {
    $wizard_path =~ m!lib/(.+).pm!;
    my $wizard = $1;
    $wizard =~ s!/!::!g;

    $wizard_path =~ m!.+/([^/\\]+).pm!;
    my $wizard_name = $1;

    autoload $wizard;

    my $conf = $wizard->get_conf();
    $wizards{$conf->{'id'}} = $wizard;
  }
}


# Get a hash of wizards IDs and Names.
sub get_names_all() {
  my @list = keys %wizards;
  my %list;
  foreach my $p (@list) {
    $list{$p} = $wizards{$p}->get_conf()->{'name'};
  }

  return \%list;
}


# Get a hash of configuration hashes for all wizard plugins.
sub get_conf_all() {
  my @list = keys %wizards;
  my %list;
  foreach my $p (@list) {
    $list{$p} = $wizards{$p}->get_conf();
  }

  return \%list;
}


# Get the class object of a specific wizard.
sub get_wizard($) {
  my ($self, $wizard_id) = @_;
  return $wizards{$wizard_id};
}


1;


=encoding utf8

=head1 NAME

B<Alambic::Model::Wizards> - Interface to all wizards plugins in Alambic.

=head1 SYNOPSIS

    my $wizards = Alambic::Model::Wizards->new();
    my $ret = $wizards->get_names_all();

=head1 DESCRIPTION

B<Alambic::Model::Wizards> provides a complete interface to the Wizards 
used the Alambic. 

=head1 METHODS

=head2 C<new()>

    my $wizards = Alambic::Model::Wizards->new();

Create a new L<Alambic::Model::Wizards> object.

=head2 C<get_names_all()>

    my $ret = $wizards->get_names_all();

Get a hash of wizards IDs and Names. Returns a hash reference with IDs and names.

    {
      'EclipsePmi' => 'Eclipse PMI Wizard'
    }

=head2 C<get_conf_all()>

    my $ret = $wizards->get_conf_all();

Get a hash of configuration hashes for all wizard plugins.

    {
      'EclipsePmi' => {
        'name' => 'Eclipse PMI Wizard',
        'params' => {},
        'id' => 'EclipsePmi',
        'plugins' => [
          'EclipsePmi',
          'Hudson'
        ],
	'desc' => [
          'This wizard only creates ...SNIP...'
        ]
      }
    }

=head2 C<get_wizard()>

    my $wiz = $wizards->get_wizard('EclipsePmi');

Get the class object of a specific wizard. Return the Project 
object and log of execution.

    {
      'project' => bless( {}, 'Alambic::Model::Project' ),
      'log' => [
        '[Plugins::EclipsePmi] Using Eclipse ...SNIP....'
      ]
    }

=head1 SEE ALSO

L<Mojolicious>, L<http://alambic.io>, L<https://bitbucket.org/BorisBaldassari/alambic>

=cut
