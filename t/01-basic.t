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
        ->content_like(qr!PolarSys dashboard!i, 'Main page contains PolarSys dashboard.');

# Check that we have the right admin page (contains text from admin page > projects > polarsys.capella).
$t->get_ok('/admin/summary')
        ->status_is(200)
        ->content_like(qr!<p>Instance: <code>PolarSys Maturity Assessment</code><br />!i, 
        'Admin summary page contains instance')
        ->content_like(qr!<li><a href="/projects/polarsys.capella.html">Capella</a></li>!i, 
        'Admin summary page contains Cappela')
        ->content_like(qr!<li><a href="/projects/tools.cdt.html">tools.cdt</a></li>!i,
        'Admin summary page contains tools.cdt')
        ->content_like(qr!<p>Quality model: <code>PolarSys Quality Model</code><br />!i,
        'Admin summary page contains quality model information')
        ->content_like(qr!<p>Attributes: <code>PolarSys Attributes</code><br />!i,
        'Admin summary page contains attributes information')
        ->content_like(qr!<p>Metrics: <code>PolarSys Metrics</code><br />!i,
        'Admin summary page contains metrics information')
        ->content_like(qr!<p>Questions: <code>PolarSys Questions</code><br />!i,
        'Admin summary page contains questions information');

# Check that we have the right project page for capella (contains header).
$t->get_ok('/projects/polarsys.capella.html')
        ->status_is(200)
        ->content_like(qr!<h2>Project polarsys.capella</h2>!i, 
        'Dashboard page contains polarsys.capella')
        ->content_like(qr!Wiki <a href="https://polarsys.org/wiki/Capella">https://polarsys.org/wiki/Capella</a>!i, 
        'Dashboard page contains wiki info.');

done_testing(16);
