use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

# Include application
use FindBin;
require "$FindBin::Bin/../script/alambic";

my $t = Test::Mojo->new('Alambic');

# Enable redirects for logout.
$t->ua->max_redirects(10);

# Check login form page.
$t->get_ok('/login')
        ->status_is(200)
        ->content_like(qr!<form action="login" method="POST"!i, 
          'Get the form tag.')
        ->content_like(qr!<input type="text" class="form-control" name="username">!i, 
          'Get username input tag.')
        ->content_like(qr!<input type="password" class="form-control" name="password">!i, 
          'Get password input tag.');

# Connect using POST.
$t->post_ok('/login' => form => {'username' => 'admin', 'password' => 'admin'})
        ->status_is(200)
        ->content_like(qr!<h1 class="al-h1"><small>Administration</small> Summary</h1>!i, 
          'Check title of administration page after login.');

# Check protected pages in admin: Repository
$t->get_ok('/admin/repo')
        ->status_is(200)
        ->content_like(qr'<h1 class="al-h1"><small>Administration</small> Alambic Repository</h1>'i, 
          'Check title: repo is defined.');

# Check protected pages in admin: Plugins
$t->get_ok('/admin/plugins')
        ->status_is(200)
        ->content_like(qr'<h1 class="al-h1"><small>Administration</small> Plugins</h1>'i, 'Check title.')
        ->content_like(qr'<td>Eclipse Grimoire</td>'i, 'Check eclipse_grimoire name is ok.')
        ->content_like(qr'<td>eclipse_grimoire</td>'i, 'Check eclipse_grimoire id is ok.')
        ->content_like(qr'<td>Eclipse PMI</td>'i, 'Check eclipse_pmi name is ok.')
        ->content_like(qr'<td>eclipse_pmi</td>'i, 'Check eclipse_pmi id is ok.');

# Check protected pages in admin: Comments
$t->get_ok('/admin/comments')
        ->status_is(200)
        ->content_like(qr'<a href="/admin/comments/tools.cdt/a/"><i class="fa fa-plus"></i></a>'i, 
          'Check rights ok on tools.cdt.');

# Check protected pages in admin: Comments for specific project tools.cdt
$t->get_ok('/admin/comments/tools.cdt')
        ->status_is(200)
        ->content_like(qr'<a href="/admin/comments/tools.cdt/e/1451253372"><i class="fa fa-pencil">'i, 
          'Check edit rights ok on tools.cdt.')
        ->content_like(qr'<a href="/admin/comments/tools.cdt/d/1451253372"><i class="fa fa-trash-o">'i, 
          'Check delete ok on tools.cdt.');

# Check protected pages in admin: Projects
$t->get_ok('/admin/projects')
        ->status_is(200)
        ->content_like(qr!<a href="/admin/project/tools.cdt">CDT</a>!i, 
          'Check tools.cdt is in list.')
        ->content_like(qr!<td>on</td>\s+<td>Sun Dec 27 20:22:32 2015</td>!i, 
          'Check project parameters.');

# Check protected pages in admin: Users
$t->get_ok('/admin/users')
        ->status_is(200)
        ->content_like(qr!<p>Users defined on the system as for now are:</p>!i, 
          'Check first paragraph of users page.')
        ->content_like(qr'<td>admin</td><td><b>Administrator</b></td>'i, 
          'Check admin user is in list.')
        ->content_like(qr'<td>/admin<br />/admin/read_files<br />/admin/projects<br />/admin/users<br />/admin/jobs<br />/admin/repo<br />/admin/plugins</td>'i, 
          'Check admin rights in list.')
        ->content_like(qr'<td>user.1</td><td><b>Anonymous</b></td>\s+<td></td>'i, 
          'Check anonymous user is in list.');

# Now logout.
$t->get_ok('/logout')
        ->status_is(200)
        ->content_like(qr!<h1 class="al-h1"><small>Welcome to the</small> Alambic Dashboard</h1>!i, 
          'Check logout ok: welcome title.')
        ->content_like(qr!<a href="/login"><i class="fa fa-user fa-fw fa-lg"></i>!i, 
          'Check logout ok: login icon.');

# Re-check protected pages in admin..
$t->get_ok('/admin/read_files/models')
        ->status_is(200)
        ->content_like(qr!<input class="btn btn-primary" type="submit" value="Submit">!i, 
          'Check there is a login form when trying to read files.');

$t->get_ok('/admin/read_files/projects')
        ->status_is(200)
        ->content_like(qr!<input class="btn btn-primary" type="submit" value="Submit">!i, 
          'Check there is a login form when trying to read files.');

# Re-check protected pages in admin..
$t->get_ok('/admin/plugins')
        ->status_is(200)
        ->content_like(qr!<input class="btn btn-primary" type="submit" value="Submit">!i, 
          'Check there is a login form when accessing plugins admin.');

# Re-check protected pages in admin..
$t->get_ok('/admin/repo')
        ->status_is(200)
        ->content_like(qr!<input class="btn btn-primary" type="submit" value="Submit">!i, 
          'Check there is a login form when accessing repo admin.');

# Re-check protected pages in admin..
$t->get_ok('/admin/comments')
        ->status_is(200)
        ->content_unlike(qr!<i class="fa fa-plus">!i, 
          'Check projects are not changeable in comments admin.');

# Re-check protected pages in admin..
$t->get_ok('/admin/comments/tools.cdt')
        ->status_is(200)
        ->content_unlike(qr!<i class="fa fa-pencil">!i, 
          'Check project tools.cdt is not changeable in comments admin.');

# Re-check protected pages in admin..
$t->get_ok('/admin/projects')
        ->status_is(200)
        ->content_like(qr!<input class="btn btn-primary" type="submit" value="Submit">!i, 
          'Check there is a login form when accessing projects admin.');

# Re-check protected pages in admin..
$t->get_ok('/admin/users')
        ->status_is(200)
        ->content_like(qr!<input class="btn btn-primary" type="submit" value="Submit">!i, 
          'Check there is a login form when accessing users admin.');

# Re-check protected pages in admin: project management
$t->get_ok('/admin/projects/new')
        ->status_is(200)
        ->content_like(qr!<input class="btn btn-primary" type="submit" value="Submit">!i, 
          'Check there is a login form when creating new project.');

$t->get_ok('/admin/project/tools.cdt/retrieve')
        ->status_is(200)
        ->content_like(qr!<input class="btn btn-primary" type="submit" value="Submit">!i, 
          'Check there is a login form when retrieving project.');

$t->get_ok('/admin/project/tools.cdt/analyse')
        ->status_is(200)
        ->content_like(qr!<input class="btn btn-primary" type="submit" value="Submit">!i, 
          'Check there is a login form when analysing project.');

# Check login form page.
$t->get_ok('/login')
        ->status_is(200)
        ->content_like(qr!<form action="login" method="POST"!i, 
          'Get the form tag.')
        ->content_like(qr!<input type="text" class="form-control" name="username">!i, 
          'Get username input tag.')
        ->content_like(qr!<input type="password" class="form-control" name="password">!i, 
          'Get password input tag.');

$t->post_ok('/login' => form => {'username' => 'admin', 'password' => 'bad'})
        ->status_is(200)
        ->content_like(qr!Some parts of this site are protected!i, 
          'Bad password should get back to login.')
        ->content_unlike(qr!You have been successfully authenticated!i, 
          'Should not be authenticated.');

$t->post_ok('/login' => form => {'username' => 'bad', 'password' => 'admin'})
        ->status_is(200)
        ->content_like(qr!Some parts of this site are protected!i, 
          'Bad login should get back to login.')
        ->content_unlike(qr!You have been successfully authenticated!i, 
          'Should not be authenticated.');

$t->get_ok('/admin/project/tools.cdt/del')
        ->status_is(200)
        ->content_like(qr!<input class="btn btn-primary" type="submit" value="Submit">!i, 
          'Check there is a login form when deleting project.');


done_testing(88);
