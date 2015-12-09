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

# Check various files needed for the dashboard quality model: attributes.
$t->get_ok('/data/polarsys.capella_attributes.json')
        ->status_is(200)
        ->json_is('/QM_QUALITY', '3.3', 'Check qm_quality value from capella attrs.')
        ->json_is('/QM_PROCESS', '4.1', 'Check qm_process value from capella attrs.')
        ->json_is('/QM_PRODUCT', '2.8', 'Check qm_product value from capella attrs.')
        ->json_is('/QM_ECOSYSTEM', '3.0', 'Check qm_ecosystem value from capella attrs.');

# Check various files needed for the dashboard quality model: questions.
$t->get_ok('/data/polarsys.capella_questions.json')
        ->status_is(200)
        ->json_is('/MLS_DEV_DIVERSITY', '1.0', 'Check mls_dev_diversity value from capella questions.')
        ->json_is('/ITS_REL', '3.3', 'Check its_rel value from capella questions.')
        ->json_is('/SCM_ACTIVITY', '5.0', 'Check scm_activity value from capella questions.')
        ->json_is('/CODE_DOC', '3.0', 'Check code_doc value from capella questions.');

# Check various files needed for the dashboard quality model: metrics.
$t->get_ok('/data/polarsys.capella_metrics.json')
        ->status_is(200)
        ->json_is('/FUNCTION_COMPLEXITY', '3.1', 'Check function_complexity value from capella metrics.')
        ->json_is('/MLS_USR_RESP_TIME_MED_3M', '0.88', 'Check mls_usr_resp_time_med_3m value from capella metrics.')
        ->json_is('/ITS_UPDATES_3M', '240', 'Check its_updates_3m value from capella metrics.')
        ->json_is('/SCM_COMMITTERS_3M', '12', 'Check scm_committers_3m value from capella metrics.');

# Check various files needed for the dashboard quality model: violations.
$t->get_ok('/data/polarsys.capella_violations.json')
        ->status_is(200)
        ->json_is('/ConstructorCallsOverridableMethod/value', '48', 'Check ConstructorCallsOverridableMethod value from capella violations.')
        ->json_is('/ConstructorCallsOverridableMethod/cat', 'REL', 'Check ConstructorCallsOverridableMethod category from capella violations.')
        ->json_is('/ConstructorCallsOverridableMethod/name', 'ConstructorCallsOverridableMethod', 'Check ConstructorCallsOverridableMethod name from capella violations.')
        ->json_is('/OverrideBothEqualsAndHashcode/value', '8', 'Check OverrideBothEqualsAndHashcode value from capella violations.')
        ->json_is('/PositionLiteralsFirstInCaseInsensitiveComparisons/value', '13', 'Check PositionLiteralsFirstInCaseInsensitiveComparisons value from capella violations.');

done_testing(41);
