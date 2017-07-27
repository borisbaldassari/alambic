use Mojo::Base -strict;

use strict;
use warnings;

use Test::More;
use Test::Mojo;

use Data::Dumper;

my $t;

# If no database is defined, skip all tests.
eval { $t = Test::Mojo->new('Alambic'); };

if ($@) {
  plan skip_all => 'Test irrelevant when no database is defined.';
}

# Enable redirects (used e.g. for login)
$t->ua->max_redirects(5);
print "# 1 \n";

# Check that we have the right home page.
$a
  = $t->get_ok('/')->status_is(200)
    ->content_like(qr!<h1 class="al-h1"><small>Welcome to the</small> Alambic Dashboard</h1>!i,
		   'Main page contains the Alambic Dashboard text.')
    ->content_like(qr!<i class="fa fa-user fa-fw fa-lg">!i,
    'Main page contains the login icon.')
    ->content_like(qr!<li><a href="/"><i class="fa fa-home fa-fw" style="color: orange;"></i> Home</a></li>!i,
  'Main page contains the Home menu entry.')
    ->content_like(qr!<a href="/admin/summary"><i class="fa fa-wrench fa-fw" style="color: orange;"></i> Admin panel</a></li>!i,
  'Main page contains the Admin menu entry.'
  )->content_like(
  qr!<blockquote>.*esc.*</blockquote>!i,
  'Main page contains the description blockquote.'
  )->content_like(qr!Projects</div>!i, 'Main page contains projects panel.')
  ->content_like(qr!Documentation</a>!i,
  'Main page contains documentation panel.')
  ->content_like(qr!Administration tools</a>!i,
  'Main page contains administration tools panel.');
print "# 1 \n";


# Login
$t->get_ok('/login')->element_exists('input[name=username][type=text]')
  ->element_exists('input[name=password][type=password]');

# Check Documentation main page.
$a = $t->get_ok('/documentation/main.html')->status_is(200)->content_like(
  qr!<h1 class="al-h1"><small>Documentation</small> main page</h1>!i,
  'Documentation main page contains the correct title.'
  )->content_like(qr!<h3>About Alambic</h3>!i,
  'Documentation page contains the About Alambic section.')
  ->content_like(qr!<h3>Local resources</h3>!i,
  'Documentation main page contains local resources section.')
  ->content_like(qr!<h3>Online resources</h3>!i,
  'Documentation main page contains online resources section.')
  ->content_like(qr!<h3>Retrieval and analysis process</h3>!i,
  'Documentation main page contains retrieval and analysis process section.')
  ->content_like(
  qr!<h3>Metrics, indicators, attributes, confidence</h3>!i,
  'Documentation main page contains metrics, indicators.. section.'
  )->content_like(
  qr!<h3 id="mainfeatures">Main features</h3>!i,
  'Documentation page contains the Main features section.'
  )->content_like(qr!<h3 id="yourproject">What about !i,
  'Documentation page contains the About your project section.');


# Check Models downloads.
$a = $t->get_ok('/models/metrics.json')->status_is(200);
my $json = $t->tx->res->json;
ok(ref($json) eq 'HASH', 'Metrics def returns hash.');

$a    = $t->get_ok('/models/attributes.json')->status_is(200);
$json = $t->tx->res->json;
ok(ref($json) eq 'HASH', 'Attributes def returns hash.');

$a    = $t->get_ok('/models/quality_model.json')->status_is(200);
$json = $t->tx->res->json;
ok(ref($json) eq 'ARRAY', 'Quality model def returns hash.');

$a    = $t->get_ok('/models/quality_model_full.json')->status_is(200);
$json = $t->tx->res->json;
ok(ref($json) eq 'HASH', 'Quality model full def returns hash.');


# Check that we have the right about page.
$a
  = $t->get_ok('/about.html')->status_is(200)
  ->content_like(qr!<h1 class="al-h1"><small>About</small> This web site</h1>!i,
  'About page contains the correct title.')->content_like(
  qr!<p><b>Name</b> <br />!i,
  'About page contains instance name.'
  )
  ->content_like(
  qr!<p><b>Description</b> <br />!i,
  'About page contains instance description.')->content_like(
  qr!<strong>Send message to administrator!i,
  'About main page contains contact form.'
  )->element_exists('input[name=name][type=text]')
  ->element_exists('input[name=email][type=text]')
  ->element_exists('textarea[name=message]');

done_testing();
