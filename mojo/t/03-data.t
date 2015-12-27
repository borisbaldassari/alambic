use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Test::Output;

# Include application
use FindBin;
require "$FindBin::Bin/../script/alambic";

my $t = Test::Mojo->new('Alambic');

# Check the basic models: metrics, attributes, questions, quality model.
$t->get_ok('/data/quality_model.json')
        ->status_is(200)
        ->json_is('/name', 'Alambic Quality Model', 
          'Check the json name of the quality model.');

# Check the basic models: metrics, attributes, questions, quality model.
$t->get_ok('/data/quality_model_full.json')
        ->status_is(200)
        ->json_is('/name', 'Alambic Quality Model', 
          'Check the json name of the full quality model.');

# Check the basic models: metrics, attributes, questions, quality model.
$t->get_ok('/data/model_metrics.json')
        ->status_is(200)
        ->json_is('/name', 'Alambic Metrics', 
          'Check the json name of the metrics file.');

$t->get_ok('/data/model_attributes.json')
        ->status_is(200)
        ->json_is('/name', 'Alambic Attributes', 
          'Check the json name of the attributes file.');

$t->get_ok('/data/model_questions.json')
        ->status_is(200)
        ->json_is('/name', 'Alambic Questions', 
          'Check the json name of the questions file.');

# Check various files needed for the dashboard quality model.
$t->get_ok('/data/tools.cdt_qm.json')
        ->status_is(200)
        ->json_is('/name', 'Alambic Quality Model', 
          'Check the json name of the model file.')
        ->json_is('/children/0/mnemo', 'QM_QUALITY', 'Check quality mnemo value.')
        ->json_is('/children/0/ind', 4.3, 'Check quality indicator value.')
        ->json_is('/children/0/name', 'Project Maturity', 'Check quality name value.')
        ->json_is('/children/0/type', 'attribute', 'Check quality attribute value.')
        ->json_is('/children/0/active', 'true', 'Check quality active value.');

# Check various files needed for the dashboard quality model: attributes.
$t->get_ok('/data/tools.cdt_attributes.json')
        ->status_is(200)
        ->json_is('/QM_ITS', '4.5', 'Check qm_quality value from capella attrs.')
        ->json_is('/QM_ACTIVITY', '4.2', 'Check qm_process value from capella attrs.')
        ->json_is('/QM_SUPPORT', '5.0', 'Check qm_product value from capella attrs.')
        ->json_is('/QM_PROCESS', '4.2', 'Check qm_ecosystem value from capella attrs.');

# Check various files needed for the dashboard quality model: questions.
$t->get_ok('/data/tools.cdt_questions.json')
        ->status_is(200)
        ->json_is('/MLS_SUPPORT', '5.0', 'Check mls_support value.')
        ->json_is('/ITS_USAGE', '4.0', 'Check its_usage value.')
        ->json_is('/SCM_ACTIVITY', '4.5', 'Check scm_activity value.')
        ->json_is('/SCM_DIVERSITY', '4.0', 'Check scm_diveristy value.');

# Check various files needed for the dashboard quality model: metrics.
$t->get_ok('/data/tools.cdt_metrics.json')
        ->status_is(200)
        ->json_is('/MLS_THREADS', '10435', 'Check mls_threads value.')
        ->json_is('/ITS_CLOSERS_30', '7', 'Check its_closers_30 value.')
        ->json_is('/SCM_AUTHORS_7', '7', 'Check scm_authors_7 value.')
        ->json_is('/ITS_PERCENTAGE_CLOSED_7', '16', 'Check its_percentage_closed_7 value.');

# Check various files needed for the dashboard quality model: violations.
# $t->get_ok('/data/tools.cdt_violations.json')
#         ->status_is(200)
#         ->json_is('/ConstructorCallsOverridableMethod/value', '48', 'Check ConstructorCallsOverridableMethod value from capella violations.')
#         ->json_is('/ConstructorCallsOverridableMethod/cat', 'REL', 'Check ConstructorCallsOverridableMethod category from capella violations.')
#         ->json_is('/ConstructorCallsOverridableMethod/name', 'ConstructorCallsOverridableMethod', 'Check ConstructorCallsOverridableMethod name from capella violations.')
#         ->json_is('/OverrideBothEqualsAndHashcode/value', '8', 'Check OverrideBothEqualsAndHashcode value from capella violations.')
#         ->json_is('/PositionLiteralsFirstInCaseInsensitiveComparisons/value', '13', 'Check PositionLiteralsFirstInCaseInsensitiveComparisons value from capella violations.');

done_testing(41);
