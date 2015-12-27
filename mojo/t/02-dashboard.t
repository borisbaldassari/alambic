use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

# Include application
use FindBin;
require "$FindBin::Bin/../script/alambic";

my $t = Test::Mojo->new('Alambic');

# Check the summary
$t->get_ok('/projects/tools.cdt.html')
        ->status_is(200)
        ->content_like(qr!<h1 class="al-h1"><small>tools.cdt</small> Summary</h1>!i, 
          'Project title is ok.')
        ->content_like(qr!<span style="color: #DA7A08; font-size: 200%">12 / 13</span>!i, 
          'Colour and numbers of completeness are ok.')
        ->content_like(qr!style="background-color: #66D91A; width: 84%;">4.2 / 5!i, 
          'Ecosystem assessment is correct for the project')
        ->content_like(qr!Web <a href="http://www.eclipse.org/cdt">http://www.eclipse.org/cdt!i, 
          'PMI web is correct for the project')
        ->content_like(qr!<a href="/admin/comments/tools.cdt/a">\s+<div class="pull-right"><span class="fa fa-plus"></span></div>\s+Add a comment\? \(Authentication required\)</a>!i, 
          'Comments field is displayed.')
        ->content_like(qr!<a href="/admin/comments/tools.cdt/e/1451253372">!i, 
          'There is one comment displayed.')
        ->content_like(qr!<b>35796</b> commits!i, 
          'Number of commits is correct.')
        ->content_like(qr!<b>16869</b> issues opened!i, 
          'Number of issues opened is ok.')
        ->content_like(qr!<b>25898</b> messages sent!i, 
          'Number of messages sent is correct.')
        ->content_like(qr!<div class="panel-heading">Manual data</div>!i, 
          'Manual data field is displayed.');

# Check the quality model
$t->get_ok('/projects/tools.cdt_qm.html')
        ->status_is(200)
        ->content_like(qr!<h1 class="al-h1"><small>tools.cdt</small> Quality model</h1>!i, 
          'Title QM is ok.');

# Check the attributes list
$t->get_ok('/projects/tools.cdt_attrs.html')
        ->status_is(200)
        ->content_like(qr!<a href="/documentation/attributes.html#QM_ACTIVITY">Activity</a>!i, 
          'Attributes contain Activity.')
        ->content_like(qr!<span class="label label-scale" style="background-color: #66D91A">4.2</span>!i, 
          'Colour and numbers are ok for Activity.')
        ->content_like(qr!<td>3 / 3 metrics</td>!i, 
          'Completeness is ok for Activity.');

# Check the questions list
$t->get_ok('/projects/tools.cdt_questions.html')
        ->status_is(200)
        ->content_like(qr!<a href="/documentation/questions.html#ITS_USAGE">ITS usage</a>!i, 
          'Questions contain ITS usage')
        ->content_like(qr!style="background-color: #66D91A">4.0!i, 
          'Colour and numbers are ok for ITS usage.')
        ->content_like(qr!<td>2 / 2 metrics</td>!i, 
          'Completeness is ok for ITS usage');

# Check the metrics list
$t->get_ok('/projects/tools.cdt_metrics.html')
        ->status_is(200)
        ->content_like(qr!<a href="/documentation/metrics.html#ITS_CLOSED_30">Number of issue!i, 
          'Metrics contain its_closed_30.')
        ->content_like(qr!style="background-color: #33CC00">5</span>!i, 
          'Colour and indicator are ok for its_closed_30.')
        ->content_like(qr!<td>31 \(was: 0\)</td>!i, 
          'Value is ok for its_closed_30.');

# Check the errors list
$t->get_ok('/projects/tools.cdt_errors.html')
        ->status_is(200)
        ->content_like(qr!<span class="label label-danger">ERROR</span> Missing metric \[PUB_SCM_INFO_PMI\].!i, 
          'Missing metric pub_scm_info_pmi is missing.');


done_testing(32);
