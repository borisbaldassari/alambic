use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

# Include application
use FindBin;
require "$FindBin::Bin/../../script/alambic";

my $t = Test::Mojo->new('Alambic');

# Check that we have the right home page (contains PolarSys).
$t->get_ok('/')
        ->status_is(200)
        ->content_like(qr!<h1 class="al-h1"><small>Welcome to the</small> Alambic Dashboard</h1>!i, 
          'Main page contains the Alambic Dashboard text.')
        ->content_like(qr!<i class="fa fa-user fa-fw fa-lg">!i, 
          'Main page contains the login icon.')
        ->content_like(qr!<li><a href="/"><i class="fa fa-home fa-fw" style="color: orange;"></i> Home</a></li>!i, 
          'Main page contains the Home menu entry.')
        ->content_like(qr!<a href="/admin/summary"><i class="fa fa-wrench fa-fw" style="color: orange;"></i> Admin panel</a></li>!i, 
          'Main page contains the Admin menu entry.');

# Check that we have the right admin page (contains text from admin page > projects > polarsys.capella).
$t->get_ok('/admin/summary')
        ->status_is(200)
        ->content_like(qr!<h1 class="al-h1"><small>Administration</small> Summary</h1>!i, 
          'Main admin page contains title.')
        ->content_like(qr!<p><b>Instance</b></p>\s*<p>DefaultName</p>!i, 
          'Admin summary page contains instance name.')
        ->content_like(qr!<p>Default Description</p>!i, 
          'Admin summary page contains instance desc.');

done_testing();
