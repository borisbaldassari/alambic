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
  qr!<blockquote>Default CLI Init description</blockquote>!i,
  'Main page contains the description blockquote.'
  )->content_like(qr!Projects</div>!i, 'Main page contains projects panel.')
  ->content_like(qr!Documentation</a>!i,
  'Main page contains documentation panel.')
  ->content_like(qr!Administration tools</a>!i,
  'Main page contains administration tools panel.');

# Check Admin page without auth
$a = $t->get_ok('/admin/summary')->status_is(403);
$a = $t->get_ok('/admin/repo')->status_is(403);
$a = $t->get_ok('/admin/models')->status_is(403);
$a = $t->get_ok('/admin/jobs')->status_is(403);
$a = $t->get_ok('/admin/projects')->status_is(403);
$a = $t->get_ok('/admin/users')->status_is(403);
$a = $t->get_ok('/admin/tools')->status_is(403);

# Try to get a user profile
$a = $t->get_ok('/user/administrator/profile')->status_is(404);

# Logout
$t->get_ok('/logout')->status_is(200);

# Login
note("Login");
$t->get_ok('/login')->element_exists('input[name=username][type=text]')
  ->element_exists('input[name=password][type=password]');

my $post_in = {username => 'administrator', password => 'password'};
my $ret = $t->post_ok('/login' => form => $post_in);

note("Go to admin");

# Check that we have the right admin summary page.
$t->get_ok('/admin/summary')->status_is(200)
  ->content_like(
  qr!<h1 class="al-h1"><small>Administration</small> Summary</h1>!i,
  'Admin summary page contains title.')->content_like(
  qr!p><b>Instance name:</b> Default CLI init</p>!i,
  'Admin summary page contains instance name.'
  )->content_like(qr!<p><b>Description:</b><br />!i,
  'Admin summary page contains instance desc.')->content_like(
  qr!<div class="panel-heading">Databases!i,
  'Admin summary page contains databases panel.'
  )->content_like(
  qr!<div class="panel-heading">Models!i,
  'Admin summary page contains models desc.'
  )->content_like(
  qr!<div class="panel-heading">Jobs!i,
  'Admin summary page contains jobs desc.'
  )->content_like(
  qr!<div class="panel-heading">Projects!i,
  'Admin summary page contains projects desc.'
  );

# Check that we have the right admin Database page.
$t->get_ok('/admin/repo')->status_is(200)->content_like(
  qr!<h1 class="al-h1"><small>Administration</small> Alambic Repository</h1>!i,
  'Repo admin page contains title.'
  )->content_like(qr!Start a backup</a>!i,
  'Repo admin page contains start backup.')->content_like(
  qr!<div class="panel-heading">Databases!i,
  'Repo admin page contains databases panel.'
  )->content_like(
  qr!<div class="panel-heading">Backups!i,
  'Repo admin page contains backups panel.'
  );

# Check that we have the right admin Models page.
$t->get_ok('/admin/models')->status_is(200)
  ->content_like(
  qr!<h1 class="al-h1"><small>Administration</small> Alambic Models</h1>!i,
  'Repo admin page contains title.')->content_like(
  qr!<div class="panel-heading">Metrics!i,
  'Repo admin page contains metrics panel.'
  )->content_like(
  qr!<div class="panel-heading">Attributes!i,
  'Repo admin page contains attributes panel.'
  )->content_like(
  qr!<div class="panel-heading">Quality Model!i,
  'Repo admin page contains quality model panel.'
  );

# Check that we have the right admin Models page.
$t->get_ok('/admin/jobs')->status_is(200)
  ->content_like(qr!<h1 class="al-h1"><small>Administration</small> Jobs</h1>!i,
  'Jobs admin page contains title.')
  ->content_like(qr!Purge jobs</a>!i, 'Jobs admin page contains purge jobs.')
  ->content_like(
  qr!<tr><th>ID</th><th>Task</th><th>Status</th><th>Created</th>!i,
  'Jobs admin page contains table for jobs.');

# Check that we have the right admin Projects page.
$t->get_ok('/admin/projects')->status_is(200)
  ->content_like(
  qr!<h1 class="al-h1"><small>Administration</small> Projects</h1>!i,
  'Projects admin page contains title.')
  ->content_like(qr!Create empty project</a>!i,
  'Projects admin page contains create empty project.')
  ->content_like(qr!Create project from Eclipse PMI Wizard</a>!i,
  'Projects admin page contains create project from PMI wizard.')
  ->content_like(
  qr!<tr>\s*<th>ID</th>\s*<th>Name</th>\s*<th>Is active</th>\s*<th>Last update</th>!i,
  'Projects admin page contains table for projects.'
  );

# Check that we have the right admin Users page.
$t->get_ok('/admin/users')->status_is(200)
  ->content_like(
  qr!<h1 class="al-h1"><small>Administration</small> Users management</h1>!i,
  'Users admin page contains title.')->content_like(qr!Add user</a>!i,
  'Users admin page contains create add user.')
  ->content_like(
  qr!<tr>\s*<th>ID</th>\s*<th>Name</th>\s*<th>Email</th>\s*<th>Roles</th>!i,
  'Users admin page contains table for projects.')
  ->content_like(qr!<td>administrator</td>!i,
  'Users admin page contains administrator\'s id.')->content_like(
  qr!<td>alambic\@castalia.solutions</td>!i,
  'Users admin page contains administrator\'s email.'
  );

# Check that we have the right admin Tools page.
$t->get_ok('/admin/tools')->status_is(200)
  ->content_like(
  qr!<h1 class="al-h1"><small>Administration</small> Tools</h1>!i,
  'Tools admin page contains title.')
  ->content_like(qr!<th>Id</th>\s*<th>Name</th>!i,
  'Tools admin page contains table header.')
  ->content_like(qr!<td><b>Git Tool</b></td>!i,
  'Tools admin page contains git tool.')
  ->content_like(qr!<td>git version .*</td>!i,
  'Tools admin page contains git version.')
  ->content_like(qr!<td><b>R sessions</b></td>!i,
  'Tools admin page contains R tool.')
  ->content_like(qr!<td>R version !i, 'Tools admin page contains R version.');

# Try to get a user profile
$a
  = $t->get_ok('/user/administrator/profile')->status_is(200)
  ->content_like(qr!<a href="/user/administrator/profile">Summary</a></li>!i,
  'User profile contains summary tab.')
  ->content_like(qr!aria-expanded="false">Projects!i,
  'User profile contains projects tab.')
  ->content_like(qr!<dt>ID</dt><dd>administrator</dd>!i,
  'User profile contains id.')
  ->content_like(qr!<dt>Name</dt><dd>Administrator</dd>!i,
  'User profile contains name.')
  ->content_like(qr!<dt>Email</dt><dd>alambic\@castalia.solutions</dd>!i,
  'User profile contains email.')
  ->content_like(qr!<dt>Roles</dt><dd>Admin</dd>!i,
  'User profile contains roles.');


# Logout
note("Logout");
$t->get_ok('/logout')->status_is(200);

$a = $t->get_ok('/admin/summary')->status_is(403);
$a = $t->get_ok('/admin/repo')->status_is(403);
$a = $t->get_ok('/admin/models')->status_is(403);
$a = $t->get_ok('/admin/jobs')->status_is(403);
$a = $t->get_ok('/admin/projects')->status_is(403);
$a = $t->get_ok('/admin/users')->status_is(403);
$a = $t->get_ok('/admin/tools')->status_is(403);

# Try to get a user profile
$a = $t->get_ok('/user/administrator/profile')->status_is(404);


done_testing();
