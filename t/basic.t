use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

# Include application
use FindBin;
require "$FindBin::Bin/../script/alambic";

my $t = Test::Mojo->new('Alambic');

# Check that we have the right home page (contains PolarSys).
$t->get_ok('/')
        ->status_is(200)
        ->content_like(qr!PolarSys dashboard!i);

# Check that we have the right admin page (contains text from admin page > projects > polarsys.capella).
$t->get_ok('/admin/summary')
        ->status_is(200)
        ->content_like(qr!<p>Instance: <code>PolarSys Maturity Assessment</code><br />!i)
        ->content_like(qr!<li><a href="/projects/polarsys.capella.html">Capella</a></li>!i)
        ->content_like(qr!<li><a href="/projects/tools.cdt.html">tools.cdt</a></li>!i);

# Check that we have the right project page for capella (contains header).
$t->get_ok('/projects/polarsys.capella.html')
        ->status_is(200)
        ->content_like(qr!<h2>Project polarsys.capella</h2>!i);

done_testing(11);
