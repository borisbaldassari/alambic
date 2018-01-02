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
use Data::Dumper;

BEGIN { use_ok('Alambic::Model::Wizards'); }

my $wizards = Alambic::Model::Wizards->new();
isa_ok($wizards, 'Alambic::Model::Wizards');

my $ret = $wizards->get_names_all();
ok(exists($ret->{'EclipsePmi'}), "Get names all contains EclipsePmi")
  or diag explain $ret;
ok($ret->{'EclipsePmi'} =~ m!^Eclipse PMI Wizard!,
  "Get names returns EclipsePmi name")
  or diag explain $ret;

$ret = $wizards->get_conf_all();
ok(exists($ret->{'EclipsePmi'}), "Get conf_all contains EclipsePmi")
  or diag explain $ret;
ok($ret->{'EclipsePmi'}{'name'} =~ m!^Eclipse PMI Wizard!,
  "Get conf all returns EclipsePmi name.")
  or diag explain $ret;
ok(
  $ret->{'EclipsePmi'}{'id'} =~ m!^EclipsePmi!,
  "Get conf all returns EclipsePmi id."
) or diag explain $ret;
is_deeply($ret->{'EclipsePmi'}{'params'},
  {}, "Get conf all returns EclipsePmi empty params.")
  or diag explain $ret;

my $wiz = $wizards->get_wizard('EclipsePmi');
isa_ok($wiz, 'Alambic::Wizards::EclipsePmi');

$ret = $wiz->get_conf();
ok(
  $ret->{'name'} =~ m!^Eclipse PMI Wizard!,
  "Get conf all returns EclipsePmi name."
) or diag explain $ret;
ok($ret->{'id'} =~ m!^EclipsePmi!, "Get conf all returns EclipsePmi id.")
  or diag explain $ret;
is_deeply($ret->{'params'}, {}, "Get conf all returns EclipsePmi empty params.")
  or diag explain $ret;

$ret = $wiz->run_wizard('modeling.sirius');
isa_ok($ret->{'project'}, 'Alambic::Model::Project',
  "Run wizard returns Alambic::Model::Project");
ok($ret->{'log'}[0] =~ m!^\[Plugins::EclipsePmi\] Using !,
  "Run wizard returns correct log.")
  or diag explain $ret;


done_testing();


