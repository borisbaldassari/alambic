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

BEGIN { use_ok('Alambic::Model::Tools'); }

my $tools = Alambic::Model::Tools->new();
isa_ok($tools, 'Alambic::Model::Tools');

my $list = $tools->get_list_all();
print Dumper($list);
my $pv = 2;
ok(scalar @{$list} == $pv, "Tools list has $pv entries.") or diag explain $list;

ok(grep(/^r_sessions/, @{$list}), "List of tools contains r_sessions.")
  or diag explain $list;
ok(grep(/^git/, @{$list}), "List of tools contains git.") or diag explain $list;

# Test one tool (say, R)
my $r      = $tools->get_tool('r_sessions');
my $r_conf = $r->get_conf();

#print Dumper($r_conf);
ok(grep(/^methods/, @{$r_conf->{'ability'}}), "Conf has ability: methods.") or diag explain $r_conf;
ok($r_conf->{'name'} =~ m!^R sessions!, "Conf has name.") or diag explain $r_conf;
ok($r_conf->{'type'} =~ m!^tool!, "Conf has type.") or diag explain $r_conf;
ok(exists($r_conf->{'provides_methods'}{'knit_rmarkdown_pdf'}), 
	"Conf has provides_methods: rmarkdown_pdf.") or diag explain $r_conf;

done_testing();
