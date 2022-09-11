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

package Alambic::Tools::Scancode;

use strict;
use warnings;

use File::Path qw(make_path);
use Data::Dumper;

# Main configuration hash for the tool
my %conf = (
  "id"      => "scancode",
  "name"    => "Scancode Tool",
  "desc"    => "Scancode scans files and fetch information about licences and copyrights.",
  "ability" => [
    "methods",
  ],
  "type"   => "tool",
  "params" => {
    "path_scancode" => "The absolute path to the scancode binary.",
    "path_src" => "The path of the source tree to parse, relative to the root of the repository. Defaults to its root.",
    "proxy"    => "The URL of a proxy, if any.",
  },
  "provides_methods" => {
    "scancode_scan_csv" => "Starts a scan on a directory -- CSV output.",
    "scancode_scan_json" => "Starts a scan on a directory -- JSON output.",
  },
);

my $bin_path;
my $src;
my $project_id;
my $repofs;

# Constructor to build a new Scancode object.
#
# Params:
#   - $project_id: the id of the project analysed.
#   - $bin_path: the full path to the binary.
#   - $src: the relative path of src from the repo's root
sub new {
  my $class = shift;
  $project_id = shift;
  $bin_path = shift || 'scancode';
  $src = shift || '';

  return bless {}, $class;
}

# Get configuration for this Git plugin instance.
sub get_conf() {
  return \%conf;
}

# Automated setup procedure for the tool.
sub install() {
}

# Returns Scancode version as a string.
sub version() {

  my $bin_cmd = "$bin_path --version";
  my @out     = `$bin_cmd 2>&1`;
  chomp @out;

  for my $l (@out) {
    if ($l =~ m/^(ScanCode version .*)$/) {
      return $l;
    }
    else {
      return "Scancode version not found.";
    }
  }
  return "Scancode version not found.";
}

# Self-test method for the tool.
sub test() {

  my @log;

  my $l_bin_path;

  if ( -f "$bin_path" && -x _ ) {     
    push(@log, "OK: scancode exec found at [$bin_path].");
  }

  for my $path (split /:/, $ENV{PATH}) {
    if (-f "$path/scancode" && -x _ ) { $l_bin_path = "$path/scancode"; last; }
  }

  if (defined($l_bin_path)) {
    push(@log, "OK: scancode exec found in PATH at [$bin_path].");
  }
  else {
    push(@log, "ERROR: scancode exec NOT found in PATH.");
  }

  my $cmd = "scancode -clpeui t/resources/arch --json-pp t/resources/sample.json";
  my @out = `$cmd 2>&1`;
  push( @log, @out );

  return \@log;
}


# Function to execute scancode and output CSV.
# Execution parameters are:
#   -n2 --copyright --package --license --info
#   --summary --classify --generated 
#   --csv  
sub scancode_scan_csv() {
  my ($self) = @_;

  my @log;

  my $dir_src = 'projects/' . $project_id . '/src/';

  # Check if src directory exists
  if ( -d $dir_src ) {

    my $dir_out = 'projects/' . $project_id . '/input/';
    my $file_out_csv = $dir_out . '/' . $project_id . '_scancode.csv';

    my $cmd = "$bin_path -n2 --copyright --package --license --info ";
    $cmd .= "--summary --classify --generated ";
    $cmd .= "--csv $file_out_csv $dir_src";

    push(@log,
      "[Tools::Scancode] Executing command [$cmd].");

    my @out = `$cmd 2>&1`;
    push( @log, @out );
  } else {
    push( @log, ("Cannot find src dir [$dir_src]. Quitting.") );
  }

  return \@log;
}


# Function to execute scancode and output JSON .
# Execution parameters are:
#   -n2 --copyright --package --license --info
#   --summary --summary-key-files --classify --generated 
#   --json  
sub scancode_scan_json() {
  my ($self) = @_;

  my @log;
  my $dir_src = 'projects/' . $project_id . '/src/';

  # Check if src directory exists
  if ( -d $dir_src ) {

    my $dir_out = 'projects/' . $project_id . '/input/';
    my $file_out_json = $dir_out . '/' . $project_id . '_scancode.json';

    my $cmd = "$bin_path -n2 --copyright --package --license --info ";
    $cmd .= "--summary --summary-key-files --classify --generated ";
    $cmd .= "--json $file_out_json $dir_src";

    push(@log,
      "[Tools::Scancode] Executing command [$cmd].");

    my @out = `$cmd 2>&1`;
    push( @log, @out );
  } else {
    push( @log, ("Cannot find src dir [$dir_src]. Quitting.") );
  }

  return \@log;
}


1;


=encoding utf8

=head1 NAME

B<Alambic::Tools::Scancode> - A plugin to execute scancode on sources.

=head1 DESCRIPTION

B<Alambic::Tools::Scancode> provides an interface to the Scancode tool within Alambic. 
It specifically provides methods to scan a codebase and outputs results in CSV or JSON format.

This plugin needs to access the sources of the project. It is therefore mandatory to configure a Git Plugin 
on the project alongside this one, in order to fetch its repository and sources.

For the complete configuration see the user documentation on the web site: L<https://alambic.io/Plugins/Tools/Scancode.html>.

=head2 C<new()>

    my $tool = Alambic::Tools::Scancode->new(
    'test.project', 
    my $version = $tool->version();

Build a new Scancode object. 

=head2 C<get_conf()>

    my $conf = $tool->get_conf();

Get configuration for this Git plugin instance. Returns a hash 
reference.

    (
      "id"      => "scancode",
      "name"    => "Scancode Tool",
      "desc"    => "Scancode scans files and fetch information about licences and copyrights.",
      "ability" => [
        "methods",
      ],
      "type"   => "tool",
      "params" => {
        "path_scancode" => "The absolute path to the scancode binary.",
        "path_src" => "The path of the source tree to parse, relative to the root of the repository. Defaults to its root.",
        "proxy"    => "The URL of a proxy, if any.",
      },
      "provides_methods" => {
        "scancode_scan_csv" => "Starts a scan on a directory -- CSV output.",
        "scancode_scan_json" => "Starts a scan on a directory -- JSON output.",
      }
    )

=head2 C<version()>

    my $version = $tool->version();

Returns the version as a string.

=head2 C<test()>

    my $log = $tool->test();

Self-test method for the tool. Returns a log as an array reference.

    [
      'OK: Scancode exec found in PATH at [/usr/bin/scancode].'
    ]

=head2 C<scancode_scan_csv()>

    $log = $tool->scancode_scan_csv();

Function to execute scancode and output CSV.

Execution parameters for the scancode command are:
  -n2 --copyright --package --license --info
  --summary --classify --generated 
  --csv

=head2 C<scancode_scan_json()>

    $log = $tool->scancode_scan_json();

Function to execute scancode and output JSON.

Execution parameters for the scancode command are:
  -n2 --copyright --package --license --info
  --summary --classify --generated 
  --json  

=head1 SEE ALSO

L<https://alambic.io/Plugins/Tools/Git.html>, L<https://stackoverflow.com>,

L<Mojolicious>, L<http://alambic.io>, L<https://bitbucket.org/BorisBaldassari/alambic>


=cut


