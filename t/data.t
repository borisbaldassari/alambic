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
        ->json_is('/name', 'PolarSys Metrics');

$t->get_ok('/data/model_metrics.json')
        ->status_is(200)
        ->json_is('/name', 'PolarSys Metrics');

$t->get_ok('/data/model_metrics.json');
#        ->status_is(200);
#        ->json_is('/name', 'PolarSys Attributes');

# Check various files needed for the dashboard quality model.
$t->get_ok('/data/polarsys.capella_qm.json')
        ->status_is(200)
        ->json_is('/children/0/mnemo', 'QM_QUALITY')
        ->json_is('/children/0/ind', 3.1)
        ->json_is('/children/0/name', 'Project Maturity')
        ->json_is('/children/0/type', 'attribute')
        ->json_is('/children/0/active', 'true');

done_testing();
