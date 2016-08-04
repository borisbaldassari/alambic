#! perl -I../../lib/

use strict;
use warnings;

use Test::More;

BEGIN { use_ok( 'Alambic::Model::Tools' ); }

my $tools = Alambic::Model::Tools->new();
isa_ok( $tools, 'Alambic::Model::Tools' );

my $list = $tools->get_list_all();
my $pv = 1;
ok( scalar @{$list} == $pv, "Tools list has $pv entries." ) or diag explain $list;

ok( grep( /^r_sessions/, @{$list} ), "List of tools contains r_sessions." ) or diag explain $list;

done_testing(4);