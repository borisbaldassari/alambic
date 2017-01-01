#!/usr/bin/perl -w

use strict; 
use warnings; 

use TAP::Harness;

if (not -e 't') {
    print "This script should be run in the mojo directory. Dying.\n";
    die "Cannot find tests and libs.";
}

my $args = {
    "verbosity" => 1,
    "lib"     => [ 'lib' ],
    };
my $harness = TAP::Harness->new($args);

$harness->runtests(
    [ 't/unit/Model/Models.t', 'Testing Model::Models' ],
    [ 't/unit/Model/Plugins.t', 'Testing Model::Plugins' ],
    [ 't/unit/Model/RepoDB.t', 'Testing Model::RepoDB' ],
    [ 't/unit/Model/RepoFS.t', 'Testing Model::RepoFS' ],
    [ 't/unit/Model/Tools.t', 'Testing Model::Tools' ],
    );



