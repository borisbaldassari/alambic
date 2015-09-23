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
        ->content_like(qr!<td><a href="/admin/project/polarsys.capella">Capella</a></td>!i, 
        'Admin summary page contains Cappela')
        ->content_like(qr!<td><a href="/admin/project/modeling.gendoc">modeling.gendoc</a></td>!i,
        'Admin summary page contains modeling.gendoc')
        ->content_like(qr!<td>Quality model</td><td>PolarSys Quality Model</td>!i,
        'Admin summary page contains quality model information')
        ->content_like(qr!<td>Attributes</td><td>PolarSys Attributes</td>!i,
        'Admin summary page contains attributes information')
        ->content_like(qr!<td>Metrics</td><td>PolarSys Metrics</td>!i,
        'Admin summary page contains metrics information')
        ->content_like(qr!<td>Questions</td><td>PolarSys Questions</td>!i,
        'Admin summary page contains questions information');

# Check that we have the right project page for capella (contains header).
$t->get_ok('/projects/polarsys.capella.html')
        ->status_is(200)
        ->content_like(qr!<h2>Project polarsys.capella</h2>!i, 
        'Dashboard page contains polarsys.capella')
        ->content_like(qr!Wiki <a href="https://polarsys.org/wiki/Capella">https://polarsys.org/wiki/Capella</a>!i, 
        'Dashboard page contains wiki info.');

done_testing(16);
