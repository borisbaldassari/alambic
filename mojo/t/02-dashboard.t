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
        ->content_like(qr!<h2>Project polarsys.capella</h2>!i, 'Project title is ok.')
        ->content_like(qr!<span style="color: #DA7A08; font-size: 200%">31 / 45</span>!i, 'Colour and numbers of completeness are ok.')
        ->content_like(qr!Sample comment for Capella.!i, 'There is a comment for the project');

# Check the quality model
$t->get_ok('/projects/polarsys.capella_qm.html')
        ->status_is(200)
        ->content_like(qr!<h3>The Quality model</h3>!i, 'Title QM is ok.');

# Check the attributes list
$t->get_ok('/projects/polarsys.capella_attrs.html')
        ->status_is(200)
        ->content_like(qr!<a href="/documentation/attributes.html#QM_ACTIVITY">Activity</a>!i, 'Attributes contain Activity.')
        ->content_like(qr!<span class="label label-scale" style="background-color: #99E633">3.3</span>!i, 'Colour and numbers are ok for Activity.')
        ->content_like(qr!<td>4 / 4 metrics</td>!i, 'Completeness is ok for Activity.');

# Check the questions list
$t->get_ok('/projects/polarsys.capella_questions.html')
        ->status_is(200)
        ->content_like(qr!<a href="/documentation/questions.html#CODE_CLONE">Code cloning</a>!i, 'Questions contain Code Cloning')
        ->content_like(qr!<span class="label label-scale" style="background-color: #33CC00">5.0</span>!i, 'Colour and numbers are ok for Code Cloning.')
        ->content_like(qr!<td>1 / 1 metrics</td>!i, 'Completeness is ok for Code Cloning');

# Check the metrics list
$t->get_ok('/projects/polarsys.capella_metrics.html')
        ->status_is(200)
        ->content_like(qr!<a href="/documentation/metrics.html#COMMENT_LINES_DENSITY">Comment rate</a>!i, 'Metrics contain Comment rate.')
        ->content_like(qr!<span class="label label-scale" style="background-color: #99E633">3</span>!i, 'Colour and indicator are ok for Comment rate.')
        ->content_like(qr!<td>15</td>!i, 'Value is ok for Comment rate.');


done_testing(23);
