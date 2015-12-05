use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Test::Output;

# Include application
use FindBin;
require "$FindBin::Bin/../script/alambic";

my $t = Test::Mojo->new('Alambic');

# Check the basic models: metrics, attributes, questions, quality model.
$t->get_ok('/data/model_metrics.json')
        ->status_is(200)
        ->json_is('/name', 'PolarSys Metrics', 'Check the json name of the file.');

$t->get_ok('/data/model_attributes.json')
        ->status_is(200)
        ->json_is('/name', 'PolarSys Attributes');

$t->get_ok('/data/model_questions.json')
        ->status_is(200)
        ->json_is('/name', 'PolarSys Questions', 'Check the json name of the file.');

# Check various files needed for the dashboard quality model.
$t->get_ok('/data/polarsys.capella_qm.json')
        ->status_is(200)
        ->json_is('/children/0/mnemo', 'QM_QUALITY', 'Check quality mnemo value.')
        ->json_is('/children/0/ind', 3.3, 'Check quality indicator value.')
        ->json_is('/children/0/name', 'Project Maturity', 'Check quality name value.')
        ->json_is('/children/0/type', 'attribute', 'Check quality attribute value.')
        ->json_is('/children/0/active', 'true', 'Check quality active value.');

done_testing(16);
