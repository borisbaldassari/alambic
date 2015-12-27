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
        ->content_like(qr!<h1 class="al-h1"><small>Welcome to the</small> Alambic Dashboard</h1>!i, 
          'Main page contains the Alambic Dashboard text.')
        ->content_like(qr!<i class="fa fa-user fa-fw fa-lg">!i, 
          'Main page contains the login icon.');

# Check that we have the right project page for cdt (contains header).
$t->get_ok('/projects/tools.cdt.html')
        ->status_is(200)
        ->content_like(qr!<h1 class="al-h1"><small>tools.cdt</small> Summary</h1>!i, 
          'Dashboard page contains tools.cdt title')
        ->content_like(qr!Wiki <a href="http://wiki.eclipse.org/index.php/CDT">!i, 
          'Dashboard page contains wiki info.');

# Check that we have the right admin page (contains text from admin page > projects > polarsys.capella).
$t->get_ok('/admin/summary')
        ->status_is(200)
        ->content_like(qr!<p><b>Instance</b> <br />\s*Official Alambic dashboard</p>!i, 
          'Admin summary page contains instance')
        ->content_like(qr!<td><a href="/admin/project/tools.cdt">CDT</a></td>!i, 
          'Admin summary page contains CDT')
        ->content_like(qr!<td>Quality model</td><td>Alambic Quality Model</td><td>0.1</td>!i,
          'Admin summary page contains quality model information')
        ->content_like(qr!<td>Attributes</td><td>Alambic Attributes</td><td>0.1</td>!i,
          'Admin summary page contains attributes information')
        ->content_like(qr!<td>Metrics</td><td>Alambic Metrics</td><td>0.1</td>!i,
          'Admin summary page contains metrics information')
        ->content_like(qr!<td>Questions</td><td>Alambic Questions</td>!i,
          'Admin summary page contains questions information');

done_testing(16);
