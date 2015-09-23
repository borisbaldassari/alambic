use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Test::Mojo::Session;

# Include application
use FindBin;
require "$FindBin::Bin/../script/alambic";

my $t = Test::Mojo->new('Alambic');

# Enable redirects for logout.
$t->ua->max_redirects(10);

# Check login form page.
$t->get_ok('/login')
        ->status_is(200)
        ->content_like(qr!<form action="login" method="POST">!i, 'Get the form tag.')
        ->content_like(qr!<p><input name="username" type="text" /></p>!i, 'Get username input tag.');

# Connect using POST.
$t->post_ok('/login' => form => {'username' => 'admin', 'password' => 'admin'})
        ->status_is(200)
        ->content_like(qr!<h2>Administration</h2>!i, 'Check title of administration page after login.');

# Check protected pages in admin: Repository
$t->get_ok('/admin/repo')
        ->status_is(200)
        ->content_like(qr'<h3>Repository information</h3>'i, 'Check first paragraph: repo is defined.')
        ->content_like(qr'Fetch url is <code>git@bitbucket.org:BorisBaldassari/test.git</code>'i, 'Check repo is ok.');


# Check protected pages in admin: Plugins
$t->get_ok('/admin/plugins')
        ->status_is(200)
        ->content_like(qr'<td>Eclipse Grimoire</td>'i, 'Check eclipse_grimoire name is ok.')
        ->content_like(qr'<td>eclipse_grimoire</td>'i, 'Check eclipse_grimoire id is ok.')
        ->content_like(qr'<td>Eclipse PMI</td>'i, 'Check eclipse_pmi name is ok.')
        ->content_like(qr'<td>eclipse_pmi</td>'i, 'Check eclipse_pmi id is ok.');


# Check protected pages in admin: Comments
$t->get_ok('/admin/comments')
        ->status_is(200)
        ->content_like(qr'<a href="/admin/comments/modeling.gendoc/a/"><i class="fa fa-plus"></i></a>'i, 'Check rights ok on modeling.gendoc.')
        ->content_like(qr'<a href="/admin/comments/polarsys.capella/a/"><i class="fa fa-plus"></i></a>'i, 'Check rights on polarsys.capella.');


# Check protected pages in admin: Comments for specific project polarsys.capella
$t->get_ok('/admin/comments/polarsys.capella')
        ->status_is(200)
        ->content_like(qr'<a href="/admin/comments/polarsys.capella/e/1440582148"><i class="fa fa-pencil">'i, 'Check rights ok on polarsys.capella.');


# Check protected pages in admin: Comments for specific project modeling.gendoc
$t->get_ok('/admin/comments/polarsys.capella')
        ->status_is(200)
        ->content_like(qr'<i class="fa fa-pencil">'i, 'Check rights are ok on modeling.gendoc.');


# Check protected pages in admin: Projects
$t->get_ok('/admin/projects')
        ->status_is(200)
        ->content_like(qr!<td>polarsys.capella</td>!i, 'Check polarsys.capella is in list.')
        ->content_like(qr!<td>modeling.gendoc</td>!i, 'Check modeling.gendoc is in list.');


# Check protected pages in admin: Users
$t->get_ok('/admin/users')
        ->status_is(200)
        ->content_like(qr!<p>Users defined on the system:</p>!i, 'Check first paragraph of users page.')
        ->content_like(qr'<b>Administrator</b> \( admin \)<br />'i, 'Check admin user is in list.')
        ->content_like(qr'<b>Anonymous</b> \( user.1 \)<br />'i, 'Check anonymous user is in list.');


# Now logout.
$t->get_ok('/logout')
        ->status_is(200)
        ->content_like(qr!<p>You just landed on the <strong>PolarSys Maturity Assessment dashboard</strong>!i, 'Check logout ok.');

# Re-check protected pages in admin..
$t->get_ok('/admin/read_files/models')
        ->status_is(200)
        ->content_like(qr!<input type="submit" value="Login"></input>!i, 'Check there is a login form when trying to read files.');
$t->get_ok('/admin/read_files/projects')
        ->status_is(200)
        ->content_like(qr!<input type="submit" value="Login"></input>!i, 'Check there is a login form when trying to read files.');

# Re-check protected pages in admin..
$t->get_ok('/admin/plugins')
        ->status_is(200)
        ->content_like(qr!<input type="submit" value="Login"></input>!i, 'Check there is a login form when accessing plugins admin.');

# Re-check protected pages in admin..
$t->get_ok('/admin/repo')
        ->status_is(200)
        ->content_like(qr!<input type="submit" value="Login"></input>!i, 'Check there is a login form when accessing repo admin.');

# Re-check protected pages in admin..
$t->get_ok('/admin/comments')
        ->status_is(200)
        ->content_unlike(qr!<i class="fa fa-plus">!i, 'Check projects are not changeable in comments admin.');

# Re-check protected pages in admin..
$t->get_ok('/admin/comments/polarsys.capella')
        ->status_is(200)
        ->content_unlike(qr!<i class="fa fa-pencil">!i, 'Check project polarsys.capella is not changeable in comments admin.');

# Re-check protected pages in admin..
$t->get_ok('/admin/projects')
        ->status_is(200)
        ->content_like(qr!<input type="submit" value="Login"></input>!i, 'Check there is a login form when accessing projects admin.');

# Re-check protected pages in admin..
$t->get_ok('/admin/users')
        ->status_is(200)
        ->content_like(qr!<input type="submit" value="Login"></input>!i, 'Check there is a login form when accessing users admin.');

# Re-check protected pages in admin: project management
$t->get_ok('/admin/projects/new')
        ->status_is(200)
        ->content_like(qr!<input type="submit" value="Login"></input>!i, 'Check there is a login form when creating new project.');

$t->get_ok('/admin/project/polarsys.capella/retrieve')
        ->status_is(200)
        ->content_like(qr!<input type="submit" value="Login"></input>!i, 'Check there is a login form when retrieving project.');

$t->get_ok('/admin/project/polarsys.capella/analyse')
        ->status_is(200)
        ->content_like(qr!<input type="submit" value="Login"></input>!i, 'Check there is a login form when analysing project.');

# Check login form page.
$t->get_ok('/login')
        ->status_is(200)
        ->content_like(qr!<form action="login" method="POST">!i, 'Get the form tag.')
        ->content_like(qr!<p><input name="username" type="text" /></p>!i, 'Get username input tag.');

$t->post_ok('/login' => form => {'username' => 'admin', 'password' => 'bad'})
        ->status_is(200)
        ->content_like(qr!Some parts of this site are protected!i, 'Bad password should get back to login.')
        ->content_unlike(qr!You have been successfully authenticated!i, 'Should not be authenticated.');

$t->post_ok('/login' => form => {'username' => 'bad', 'password' => 'admin'})
        ->status_is(200)
        ->content_like(qr!Some parts of this site are protected!i, 'Bas login should get back to login.')
        ->content_unlike(qr!You have been successfully authenticated!i, 'Should not be authenticated.');

#$t->get_ok('/admin/project/polarsys.capella/del')
#        ->status_is(200)
#        ->content_like(qr!<input type="submit" value="Login"></input>!i, 'Check there is a login form when deleting project.');


done_testing(84);
