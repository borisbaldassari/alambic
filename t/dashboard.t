use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

# Include application
use FindBin;
require "$FindBin::Bin/../script/alambic";

my $t = Test::Mojo->new('Alambic');

# Check the summary
$t->get_ok('/projects/polarsys.capella.html')
        ->status_is(200)
        ->content_like(qr!<h2>Project polarsys.capella</h2>!i)
        ->content_like(qr!<span style="color: #DA7A08; font-size: 200%">38 / 45</span>!i)
        ->content_like(qr!Sample comment for Capella.!i);

# Check the quality model
$t->get_ok('/projects/polarsys.capella_qm.html')
        ->status_is(200)
        ->content_like(qr!<h3>The Quality model</h3>!i);

# Check the attributes list
$t->get_ok('/projects/polarsys.capella_attrs.html')
        ->status_is(200)
        ->content_like(qr!<a href="/documentation/attributes.html#QM_ACTIVITY">Activity</a>!i)
        ->content_like(qr!<span class="label label-scale" style="background-color: #CCF24D">2.3</span>!i)
        ->content_like(qr!<td>4 / 4 metrics</td>!i);

# Check the questions list
$t->get_ok('/projects/polarsys.capella_questions.html')
        ->status_is(200)
        ->content_like(qr!<a href="/documentation/questions.html#CODE_CLONE">Code cloning</a>!i)
        ->content_like(qr!<span class="label label-scale" style="background-color: #33CC00">5.0</span>!i)
        ->content_like(qr!<td>1 / 1 metrics</td>!i);

# Check the metrics list
$t->get_ok('/projects/polarsys.capella_metrics.html')
        ->status_is(200)
        ->content_like(qr!<a href="/documentation/metrics.html#COMMENT_LINES_DENSITY">Comment rate</a>!i)
        ->content_like(qr!<span class="label label-scale" style="background-color: #99E633">3</span>!i)
        ->content_like(qr!<td>15</td>!i);


done_testing(23);
