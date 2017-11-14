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

package Alambic::Model::Tools;

use warnings;
use strict;

use Module::Load;
use Data::Dumper;


require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(
  get_list_all
  get_tool
);


my %tools;


# Constructor to build a new Tools object.
sub new {
  my ($class) = @_;

  &_read_tools();

  return bless {}, $class;
}


# Private method to read the Tools directory.
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
    $tools{$conf->{'id'}} = $tool;
  }

}


# Get a list of all tools.
# Returns an array ref of tool IDs.
sub get_list_all() {
  my @list = sort keys %tools;

  return \@list;
}


# Get a Perl object representing the tool.
sub get_tool($) {
  my ($self, $tool_id) = @_;
  return $tools{$tool_id};
}

1;


=encoding utf8

=head1 NAME

B<Alambic::Model::Tools> - A class to manage, install and execute external 
tools in Alambic. Provides a common interface to all tools plugins.

=head1 SYNOPSIS

    my $tools = Alambic::Model::Tools->new();    
    my $list = $tools->get_list_all();


=head1 DESCRIPTION

B<Alambic::Model::Tools> provides a common interface to a series of 
tools used in Alambic. Tool plugins can provide the following methods:

=over

=item * install provides an automatic install of the tool.

=item * version returns the version of the tool.

=item * test is a self-diagnostic method for tools auto-test.

=item * specific methods can be provided as listed in the 
plugin's configuration hash.

=back

=head1 METHODS

=head2 C<new()>

    my $tools = Alambic::Model::Tools->new();    

Creates a new L<Alambic::Model::Tools> object to interact with the 
various tools used within Alambic.

=head2 C<get_list_all()>

    my $list = $tools->get_list_all();

Get the list of tools recognised by Alambic, as an array ref of 
tool plugin ids (strings).

    [
      'git',
      'r_sessions'
    ];

=head2 C<get_tool()>

    my $git = $tools->get_tool('git');
    my $r = $tools->get_tool('r_sessions');

Get a reference to the tool object (e.g. L<Alambic::Tools::Git>).

=head1 SEE ALSO

L<Mojolicious>, L<http://alambic.io>, L<https://bitbucket.org/BorisBaldassari/alambic>

=cut

