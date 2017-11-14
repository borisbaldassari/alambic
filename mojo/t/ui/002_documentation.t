use Mojo::Base -strict;

use strict;
use warnings;

use Test::More;
use Test::Mojo;
use FindBin;
use Data::Dumper;

my $t;

# If no database is defined, skip all tests.
eval { $t = Test::Mojo->new('Alambic'); };

if ($@) {
  plan skip_all => 'Test irrelevant when no database is defined.';
}

# Enable redirects (used e.g. for login)
$t->ua->max_redirects(5);

# Check that we have the right home page.
$a
  = $t->get_ok('/')->status_is(200)
  ->content_like(
  qr!<h1 class="al-h1"><small>Welcome to the</small> Alambic Dashboard</h1>!i,
  'Main page contains the Alambic Dashboard text.')->content_like(
  qr!<i class="fa fa-user fa-fw fa-lg">!i,
  'Main page contains the login icon.'
  )->content_like(
  qr!<li><a href="/"><i class="fa fa-home fa-fw" style="color: orange;"></i> Home</a></li>!i,
  'Main page contains the Home menu entry.'
  )->content_like(
  qr!<a href="/admin/summary"><i class="fa fa-wrench fa-fw" style="color: orange;"></i> Admin panel</a></li>!i,
  'Main page contains the Admin menu entry.'
  )->content_like(
  qr!<blockquote>.*esc.*</blockquote>!i,
  'Main page contains the description blockquote.'
  )->content_like(qr!Projects</div>!i, 'Main page contains projects panel.')
  ->content_like(qr!Documentation</a>!i,
  'Main page contains documentation panel.')
  ->content_like(qr!Administration tools</a>!i,
  'Main page contains administration tools panel.');

# Check Documentation main page.
$a = $t->get_ok('/documentation/main.html')->status_is(200)->content_like(
  qr!<h1 class="al-h1"><small>Documentation</small> main page</h1>!i,
  'Documentation main page contains the correct title.'
  )->content_like(qr!<h3>Local resources</h3>!i,
  'Documentation main page contains local resources section.')
  ->content_like(qr!<h3>Online resources</h3>!i,
  'Documentation main page contains online resources section.')
  ->content_like(qr!<h3>Retrieval and analysis process</h3>!i,
  'Documentation main page contains retrieval and analysis process section.')
  ->content_like(
  qr!<h3>Metrics, indicators, attributes, confidence</h3>!i,
  'Documentation main page contains metrics, indicators.. section.'
  )->content_like(qr!<h3>About Alambic</h3>!i,
  'Documentation page contains the About Alambic section.')->content_like(
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


# Check Documentation data page.
$a = $t->get_ok('/documentation/data.html')->status_is(200)->content_like(
  qr!<h1 class="al-h1"><small>Documentation</small> Data</h1>!i,
  'Documentation data page contains the correct title.'
  )->content_like(qr!<h3 id="info">Generic information</h3>!i,
  'Documentation data page contains generic information section.')
  ->content_like(qr!<h3 id="api">API scheme</h3>!i,
  'Documentation data page contains api scheme section.')
  ->content_like(qr!<h3 id="figs">Exporting figures</h3>!i,
  'Documentation data page contains exporting figures section.')
  ->content_like(qr!<h3 id="data">Project data</h3>!i,
  'Documentation data page contains project data section.');


# Check Documentation plugins page.
$a = $t->get_ok('/documentation/plugins.html')->status_is(200)->content_like(
  qr!<h1 class="al-h1"><small>Documentation</small> Plugins</h1>!i,
  'Documentation plugins page contains the correct title.'
  )->content_like(qr!<a href="plugins\?type=pre">Data sources!i,
  'Documentation plugins page contains data sources section.')
  ->content_like(qr!<a href="plugins\?type=post">Post!i,
  'Documentation plugins page contains post plugins section.')
  ->content_like(qr!<a href="plugins\?type=global">Global!i,
  'Documentation plugins page contains global plugins section.')->content_like(
  qr!<a href="plugins\?type=cdata">Custom data!i,
  'Documentation plugins page contains custom data section.'
  )->content_like(qr!<a href="plugins\?type=wiz">Wizards!i,
  'Documentation plugins page contains exporting figures section.');

# Check Documentation plugins > pre page.
$a
  = $t->get_ok('/documentation/plugins?type=pre')->status_is(200)
  ->content_like(
  qr!<h1 class="al-h1"><small>Documentation</small> Plugins</h1>!i,
  'Documentation plugins pre page contains the correct title.'
  )->content_like(qr!<a href="plugins\?type=pre">Data sources!i,
  'Documentation plugins pre page contains data sources section.')
  ->content_like(qr!<a href="plugins\?type=post">Post!i,
  'Documentation plugins pre page contains post plugins section.')
  ->content_like(qr!<a href="plugins\?type=global">Global!i,
  'Documentation plugins pre page contains global plugins section.')
  ->content_like(qr!<a href="plugins\?type=cdata">Custom data!i,
  'Documentation plugins pre page contains custom data section.')
  ->content_like(qr!<a href="plugins\?type=wiz">Wizards!i,
  'Documentation plugins pre page contains exporting figures section.')
  ->content_like(qr!<h3>Data source plugins</h3>!i,
  'Documentation plugins pre page contains data source plugins section.')
  ->content_like(qr!<h4 id="Hudson">Hudson CI</h4>!i,
  'Documentation plugins pre page contains Hudson plugin.');

# Check Documentation plugins > post page.
$a
  = $t->get_ok('/documentation/plugins?type=post')->status_is(200)
  ->content_like(
  qr!<h1 class="al-h1"><small>Documentation</small> Plugins</h1>!i,
  'Documentation plugins post page contains the correct title.'
  )->content_like(qr!<a href="plugins\?type=pre">Data sources!i,
  'Documentation plugins post page contains data sources section.')
  ->content_like(qr!<a href="plugins\?type=post">Post!i,
  'Documentation plugins post page contains post plugins section.')
  ->content_like(qr!<a href="plugins\?type=global">Global!i,
  'Documentation plugins post page contains global plugins section.')
  ->content_like(qr!<a href="plugins\?type=cdata">Custom data!i,
  'Documentation plugins post page contains custom data section.')
  ->content_like(qr!<a href="plugins\?type=wiz">Wizards!i,
  'Documentation plugins post page contains exporting figures section.')
  ->content_like(qr!<h3>Post plugins</h3>!i,
  'Documentation plugins post page contains post plugins section.')
  ->content_like(qr!<h4 id="ProjectSummary">Project summary</h4>!i,
  'Documentation plugins post page contains Project Summary plugin.');

# Check Documentation plugins > global page.
$a
  = $t->get_ok('/documentation/plugins?type=global')->status_is(200)
  ->content_like(
  qr!<h1 class="al-h1"><small>Documentation</small> Plugins</h1>!i,
  'Documentation plugins global page contains the correct title.'
  )->content_like(qr!<a href="plugins\?type=pre">Data sources!i,
  'Documentation plugins global page contains data sources section.')
  ->content_like(qr!<a href="plugins\?type=post">Post!i,
  'Documentation plugins global page contains post plugins section.')
  ->content_like(qr!<a href="plugins\?type=global">Global!i,
  'Documentation plugins global page contains global plugins section.')
  ->content_like(qr!<a href="plugins\?type=cdata">Custom data!i,
  'Documentation plugins global page contains custom data section.')
  ->content_like(qr!<a href="plugins\?type=wiz">Wizards!i,
  'Documentation plugins global page contains exporting figures section.')
  ->content_like(qr!<h3>Global plugins</h3>!i,
  'Documentation plugins global page contains global plugins section.');

# Check Documentation plugins > wizards page.
$a
  = $t->get_ok('/documentation/plugins?type=wiz')->status_is(200)
  ->content_like(
  qr!<h1 class="al-h1"><small>Documentation</small> Plugins</h1>!i,
  'Documentation plugins wizards page contains the correct title.'
  )->content_like(qr!<a href="plugins\?type=pre">Data sources!i,
  'Documentation plugins wizards page contains data sources section.')
  ->content_like(qr!<a href="plugins\?type=post">Post!i,
  'Documentation plugins wizards page contains post plugins section.')
  ->content_like(qr!<a href="plugins\?type=global">Global!i,
  'Documentation plugins wizards page contains global plugins section.')
  ->content_like(qr!<a href="plugins\?type=cdata">Custom data!i,
  'Documentation plugins wizards page contains custom data section.')
  ->content_like(qr!<a href="plugins\?type=wiz">Wizards!i,
  'Documentation plugins wizards page contains exporting figures section.')
  ->content_like(qr!<h3>Wizards</h3>!i,
  'Documentation plugins wizards page contains wizards plugins section.');

# Check Metrics page.
$a = $t->get_ok('/documentation/metrics')->status_is(200)->content_like(
  qr!<h1 class="al-h1"><small>Documentation</small> Metrics</h1>!i,
  'Documentation metrics page contains the correct title.'
  )->content_like(
  qr!<a href="metrics.html">All&nbsp; <span!i,
  'Documentation metrics page contains all section.'
  );


done_testing();
