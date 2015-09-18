use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Test::Mojo::Session;

# Include application
use FindBin;
require "$FindBin::Bin/../script/alambic";

my $t = Test::Mojo->new('Alambic');

# Check login form page.
$t->get_ok('/login')
        ->status_is(200)
        ->content_like(qr!<form action="login" method="POST">!i, 'Get the form tag.')
        ->content_like(qr!<p><input name="username" type="text" /></p>!i, 'Get username input tag.');

# Connect using POST.
$t->post_ok('/login' => form => {'username' => 'boris.baldassari', 'password' => 'boris123'})
        ->status_is(200)
        ->content_like(qr!<h2>Administration</h2>!i, 'Check title of administration page after login.');

# Check protected pages in admin..
$t->get_ok('/admin/users')
        ->status_is(200)
        ->content_like(qr!<p>Users defined on the system:</p>!i, 'Check first paragraph of users page.')
        ->content_like(qr!<b>Anonymous</b> \( user.1 \)<br />!i, 'Check anonymous user is in list.');

# Enable redirects for logout.
$t->ua->max_redirects(10);

# Now logout.
$t->get_ok('/logout')
        ->status_is(200)
        ->content_like(qr!<p>You just landed on the <strong>PolarSys Maturity Assessment dashboard</strong>!i, 'Check logout ok.');

# Re-check protected pages in admin..
$t->get_ok('/admin/users')
        ->status_is(200)
        ->content_like(qr!<input type="submit" value="Login"></input>!i, 'Check there is login when accessing users admin.');



done_testing();
