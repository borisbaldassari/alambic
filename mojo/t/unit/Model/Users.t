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

BEGIN { use_ok('Alambic::Model::Users'); }

my $users = Alambic::Model::Users->new();
isa_ok($users, 'Alambic::Model::Users');

my $hash = $users->generate_passwd('password');
ok( $hash =~ m!^\{X-PBKDF2\}HMACSHA1:!, "Generated password is a HMACSHA1." )
    or diag explain $hash;

my $u = {
    'administrator' => {
	'notifs' => {},
	'name' => 'Administrator',
	'roles' => ['Admin'],
	'email' => 'alambic@castalia.solutions',
	'passwd' => '{X-PBKDF2}HMACSHA1:AAAD6A:5R2HIw==:3c7E0POr1PCmC7XQdahjgr/PDus=',
	'projects' => {},
	'id' => 'administrator'
    }
};

my $users2 = Alambic::Model::Users->new($u);
isa_ok($users2, 'Alambic::Model::Users');

my $ret = $users2->validate_user('administrator', 'password');
ok( $ret =~ m!^administrator!, "Validate user returns administrator." )
    or diag explain $ret;

$ret = $users->get_roles();
#print "ROLES " . Dumper($ret);
ok( grep(/^Admin/, @{$ret}), "List of roles contains Admin" )
    or diag explain $ret;
ok( grep(/^est/, @{$ret}), "List of roles contains Guest" )
    or diag explain $ret;
ok( grep(/^Projects/, @{$ret}), "List of roles contains Projects" )
    or diag explain $ret;

$users->get_projects_for_user('administrator');
is_deeply( $ret, {}, "Get projects returns empty hash.");
done_testing();


