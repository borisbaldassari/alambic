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

use Data::Dumper;

use File::Path qw(make_path remove_tree);
use Test::More;
use File::Copy;

BEGIN { use_ok('Alambic::Tools::Scancode'); }

my $tool = Alambic::Tools::Scancode->new();
isa_ok($tool, 'Alambic::Tools::Scancode');

note("Executing module self-test.");
my $log = $tool->test(); print Dumper($log);
ok(grep(!/^ERROR/, @{$log}), "Tool test() returns no ERROR")
  or diag explain $log;

note("Ask for version.");
my $version = $tool->version(); print Dumper($version);
ok(grep(!/^Scancode version not found/, $version), "Tool version() returns a version.")
    or diag explain $version;

note("Executing Scancode on Alambic itself..");
my $version = $tool->scancode_scan_csv(); print Dumper($version);
ok(grep(!/^Scancode version not found/, $version), "Tool version() returns a version.")
  or diag explain $version;

    
done_testing();
