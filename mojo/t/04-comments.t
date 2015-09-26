use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

# Include application
use FindBin;
require "$FindBin::Bin/../script/alambic";

my $t = Test::Mojo->new('Alambic');

# Check that we have the right home page for comments
$t->get_ok('/admin/comments', "Get admin comment.")
        ->status_is(200)
        ->content_like(qr!These pages allow teams to add custom comments to the projects!i, "Get the first paragraph.")
        ->content_like(qr!<li><a href="/projects/polarsys.capella.html">Capella</a></li>!i);

# Check that the comments are correctly displayed for a single project
$t->get_ok('/admin/comments/polarsys.capella')
        ->status_is(200)
        ->content_like(qr!<td width="1cm"><a href="/admin/comments/polarsys.capella"><i class="fa fa-eye"></i></a></td>!i, 'Check Capella is displayed.')
        ->content_like(qr!<td width="1cm"><a href="/admin/comments/modeling.gendoc"><i class="fa fa-eye"></i></a></td>!i, 'Check modeling.gendoc is displayed.')
        ->content_like(qr!<th>Comments for project polarsys.capella</th>!i, 'Check header for capella comments table.');

# Check that the edit page is ok without auth.
$t->get_ok('/admin/comments/polarsys.capella/e/1440582148')
        ->status_is(200)
        ->content_like(qr!<td width="1cm"><a href="/admin/comments/polarsys.capella"><i class="fa fa-eye"></i></a></td>!i, 'Check eye on project list.')
        ->content_unlike(qr!<b>Editing comment 1440582148 on polarsys.capella.</b>!i, 'Check the edit form is not displayed.')
        ->content_unlike(qr!<input name="author" type="text" value="Boris Baldassari">!i, 'Check the author in edit form is not displayed.');


# Request with custom cookie
# my $tx = $t->ua->build_tx(GET => '/admin/comments/polarsys.capella/');
# $tx->req->cookies({name => 'session_user', value => 'boris.baldassari'});
# $t->request_ok($tx)->status_is(200)->content_like(qr!-pencil!, 'with cookies.');

# Check that the delete page is ok without auth.
$t->get_ok('/admin/comments/polarsys.capella/d/1440582148')
        ->status_is(200)
        ->content_like(qr!<li><a href="/projects/polarsys.capella.html">Capella</a></li>!i, 'Delete has project name.')
        ->content_unlike(qr!<b>Deleting comment 1440582148 on polarsys.capella.</b></p><br />!i, 'Check the delete form is not displayed.')
        ->content_unlike(qr!<input name="author" type="text" value="Boris Baldassari" disabled>!i, 'Check the author in delete form is not displayed.');

done_testing(19);