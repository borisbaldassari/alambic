#! perl -I../../lib/
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


use strict;
use warnings;

use Test::More;

BEGIN { use_ok('Alambic::Model::RepoFS'); }

my $repofs = Alambic::Model::RepoFS->new();
isa_ok($repofs, 'Alambic::Model::RepoFS');

$repofs->write_input('test.project', 'test_file_in.json',
  "{'test' => 'value'}");
ok(-e 'projects/test.project/input/test.project_test_file_in.json',
  "Input file has been created.");

my $file_input = $repofs->read_input('test.project', 'test_file_in.json');
is($file_input, "{'test' => 'value'}", 'Input file can be read and is correct.')
  or diag explain $file_input;

$repofs->write_output('test.project', 'test_file_out.json',
  "{'test2' => 'value2'}");
ok(-e 'projects/test.project/output/test.project_test_file_out.json',
  "Output file has been created.");

my $file_output = $repofs->read_output('test.project', 'test_file_out.json');
is(
  $file_output,
  "{'test2' => 'value2'}",
  'Output file can be read and is correct.'
) or diag explain $file_output;

done_testing(6);
