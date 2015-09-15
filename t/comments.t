use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

# Include application
use FindBin;
require "$FindBin::Bin/../script/alambic";

my $t = Test::Mojo->new('Alambic');

# Check that we have the right home page for comments
$t->get_ok('/admin/comments')
        ->status_is(200)
        ->content_like(qr!These pages allow teams to add custom comments to the projects!i)
        ->content_like(qr!<li><a href="/projects/polarsys.capella.html">Capella</a></li>!i);

# Check that the comments are correctly displayed for a single project
$t->get_ok('/admin/comments/polarsys.capella')
        ->status_is(200)
        ->content_like(qr!<li><a href="/projects/polarsys.capella.html">Capella</a></li>!i)
        ->content_like(qr!<td width="1cm"><a href="/admin/comments/polarsys.capella"><i class="fa fa-eye"></i></a></td>!i)
        ->content_like(qr!<th>Comments for project polarsys.capella</th>!i);

# Check that the edit page is ok
$t->get_ok('/admin/comments/polarsys.capella/e/1440582148')
        ->status_is(200)
        ->content_like(qr!<li><a href="/projects/polarsys.capella.html">Capella</a></li>!i)
        ->content_like(qr!<td width="1cm"><a href="/admin/comments/polarsys.capella"><i class="fa fa-eye"></i></a></td>!i)
        ->content_like(qr!<input name="author" type="text" value="Boris Baldassari">!i);

# Check that the delete page is ok
$t->get_ok('/admin/comments/polarsys.capella/d/1440582148')
        ->status_is(200)
        ->content_like(qr!<li><a href="/projects/polarsys.capella.html">Capella</a></li>!i)
        ->content_like(qr!<td width="1cm"><a href="/admin/comments/polarsys.capella"><i class="fa fa-eye"></i></a></td>!i)
        ->content_like(qr!<input name="author" type="text" value="Boris Baldassari" disabled>!i);

done_testing(19);
