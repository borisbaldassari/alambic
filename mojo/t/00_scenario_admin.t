use Mojo::Base -strict;

use Test::Mojo;
use Test::More;
use File::Path qw(remove_tree);
use Data::Dumper;

# Include application
use FindBin;
require "$FindBin::Bin/../script/alambic";


my $t = Test::Mojo->new('Alambic');


# Enable redirects for logout.
$t->ua->max_redirects(10);
$t->ua->connect_timeout(10);
$t->ua->inactivity_timeout(40);

# Connect using POST.
$t->post_ok('/login' => form => {'username' => 'admin', 'password' => 'admin'})
    ->status_is(200)
    ->content_like(qr!<h1 class="al-h1"><small>Administration</small> Summary</h1>!i, 
      'Check title of administration page after login.');


# Initialise new repository.
$t->post_ok('/admin/repo/init' => form => {'git_repo' => 'git@bitbucket.org:BorisBaldassari/alambic_test.git'})
    ->status_is(200)
    ->content_like(qr!All data, configuration and executable files in Alambic!i, 
      'Initialise repository.')
    ->content_like(qr!is <code>git\@bitbucket.org:BorisBaldassari/alambic_test.git</code>!i, 
      'Fetch URL is well defined.')
    ->content_like(qr!<td>\[Alambic\] Initial push!i, 'Initial push is listed.');


# Create a new project modeling.sirius.
$t->post_ok( '/admin/projects/new' => form => {'name' => 'Sirius', 'id' => 'modeling.sirius'} )
    ->status_is(200)
    ->content_like(qr!Project \[modeling.sirius\] saved.!i, 
      'Sirius project has been added.');

# Check that we have the right project page for the new project.
$t->get_ok('/admin/project/modeling.sirius')
    ->status_is(200)
    ->content_like(qr!<b>ID</b> modeling.sirius!i, 'Page after new project contains sirius.');

# Add a few new data sources: eclipse_grimoire
$t->post_ok('/admin/project/modeling.sirius/ds/eclipse_grimoire/new' => 
           form => {'project_id' => 'modeling.sirius', 
                    'grimoire_url' => 'http://dashboard.eclipse.org/data/json/'})
    ->status_is(200)
    ->content_like(qr!Plugin \[eclipse_grimoire\] added to project \[modeling.sirius\].!, 
      'Msg ok is displayed.')
    ->content_like(qr!<td>Eclipse Grimoire</td><td>eclipse_grimoire</td>!i, 
      'Data source has been created on project.')
    ->content_like(qr!ds/eclipse_grimoire/check"><i class="fa fa-check"></i>!i, 
      'Data source has check link.')
    ->content_like(qr!ds/eclipse_grimoire/retrieve"><i class="fa fa-download"></i>!i, 
      'Data source has retrieve link.')
    ->content_like(qr!ds/eclipse_grimoire/compute"><i class="fa fa-cogs"></i>!i, 
      'Data source has compute link.')
    ->content_like(qr!ds/eclipse_grimoire/del"><i class="fa fa-ban"></i>!i, 
      'Data source has del link.');


# Add a few new data sources: eclipse_pmi
$t->post_ok('/admin/project/modeling.sirius/ds/eclipse_pmi/new' => 
           form => {'project_id' => 'modeling.sirius'})
    ->status_is(200)
    ->content_like(qr!<td>Eclipse PMI</td><td>eclipse_pmi</td>!i, 
      'Data source has been created on project.')
    ->content_like(qr!ds/eclipse_pmi/check"><i class="fa fa-check"></i>!i, 
      'Data source has check link.')
    ->content_like(qr!ds/eclipse_pmi/retrieve"><i class="fa fa-download"></i>!i, 
      'Data source has retrieve link.')
    ->content_like(qr!ds/eclipse_pmi/compute"><i class="fa fa-cogs"></i>!i, 
      'Data source has compute link.')
    ->content_like(qr!ds/eclipse_pmi/del"><i class="fa fa-ban"></i>!i, 
      'Data source has del link.');
    
# Add a few new data sources: eclipse_mls
$t->post_ok('/admin/project/modeling.sirius/ds/eclipse_mls/new' => 
           form => {'project_id' => 'modeling.sirius', 
                    'grimoire_url' => 'http://dashboard.eclipse.org/data/json/'})
    ->status_is(200)
    ->content_like(qr!<td>Eclipse MLS</td><td>eclipse_mls</td>!i, 
      'Data source has been created on project.')
    ->content_like(qr!ds/eclipse_mls/check"><i class="fa fa-check"></i>!i, 
      'Data source has check link.')
    ->content_like(qr!ds/eclipse_mls/retrieve"><i class="fa fa-download"></i>!i, 
      'Data source has retrieve link.')
    ->content_like(qr!ds/eclipse_mls/compute"><i class="fa fa-cogs"></i>!i, 
      'Data source has compute link.')
    ->content_like(qr!ds/eclipse_mls/del"><i class="fa fa-ban"></i>!i, 
      'Data source has del link.');

# Add a few new data sources: eclipse_its
$t->post_ok('/admin/project/modeling.sirius/ds/eclipse_its/new' => 
           form => {'project_id' => 'modeling.sirius', 
                    'grimoire_url' => 'http://dashboard.eclipse.org/data/json/'})
    ->status_is(200)
    ->content_like(qr!<td>Eclipse ITS</td><td>eclipse_its</td>!i, 
      'Data source has been created on project.')
    ->content_like(qr!ds/eclipse_its/check"><i class="fa fa-check"></i>!i, 
      'Data source has check link.')
    ->content_like(qr!ds/eclipse_its/retrieve"><i class="fa fa-download"></i>!i, 
      'Data source has retrieve link.')
    ->content_like(qr!ds/eclipse_its/compute"><i class="fa fa-cogs"></i>!i, 
      'Data source has compute link.')
    ->content_like(qr!ds/eclipse_its/del"><i class="fa fa-ban"></i>!i, 
      'Data source has del link.');

# Add a few new data sources: eclipse_scm
$t->post_ok('/admin/project/modeling.sirius/ds/eclipse_scm/new' => 
           form => {'project_id' => 'modeling.sirius', 
                    'grimoire_url' => 'http://dashboard.eclipse.org/data/json/'})
    ->status_is(200)
    ->content_like(qr!<td>Eclipse SCM</td><td>eclipse_scm</td>!i, 
      'Data source has been created on project.')
    ->content_like(qr!ds/eclipse_scm/check"><i class="fa fa-check"></i>!i, 
      'Data source has check link.')
    ->content_like(qr!ds/eclipse_scm/retrieve"><i class="fa fa-download"></i>!i, 
      'Data source has retrieve link.')
    ->content_like(qr!ds/eclipse_scm/compute"><i class="fa fa-cogs"></i>!i, 
      'Data source has compute link.')
    ->content_like(qr!ds/eclipse_scm/del"><i class="fa fa-ban"></i>!i, 
      'Data source has del link.');

# Add a few new data sources: stack_overflow
$t->post_ok('/admin/project/modeling.sirius/ds/stack_overflow/new' => 
           form => {'bin_r' => '/usr/bin/R', 
                    'so_keyword' => 'eclipse-sirius'})
    ->status_is(200)
    ->content_like(qr!<td>Stack Overflow metrics</td><td>stack_overflow</td>!i, 
      'Data source has been created on project.')
    ->content_like(qr!ds/stack_overflow/check"><i class="fa fa-check"></i>!i, 
      'Data source has check link.')
    ->content_like(qr!ds/stack_overflow/retrieve"><i class="fa fa-download"></i>!i, 
      'Data source has retrieve link.')
    ->content_like(qr!ds/stack_overflow/compute"><i class="fa fa-cogs"></i>!i, 
      'Data source has compute link.')
    ->content_like(qr!ds/stack_overflow/del"><i class="fa fa-ban"></i>!i, 
      'Data source has del link.');


# Delete a data source: stack_overflow 
$t->get_ok('/admin/project/modeling.sirius/ds/stack_overflow/del')
    ->status_is(200)
    ->content_unlike(qr!<td>Stack Overflow metrics</td><td>stack_overflow</td>!i, 
      'Data source has been deleted on project.')
    ->content_unlike(qr!ds/stack_overflow/retrieve"><i class="fa fa-download"></i>!i, 
      'Data source has not retrieve link.')
    ->content_unlike(qr!ds/stack_overflow/compute"><i class="fa fa-cogs"></i>!i, 
      'Data source has not compute link.');
    

# Then retrieve data for all data sources
$t->get_ok('/admin/project/modeling.sirius/retrieve')
    ->status_is(200)
    ->content_like(qr!Data for project modeling.sirius has been retrieved.!i, 
      'Message states that data has been retrieved.')
    ->content_like(qr!<td>modeling.sirius_metrics_grimoire.json!i, 
      'Input files section has metrics_grimoire.')
    ->content_like(qr!<td>modeling.sirius_metrics_pmi.json!i, 
      'Input files section has metrics_pmi.')
    ->content_like(qr!<td>modeling.sirius_import_pmi.json!i, 
      'Input files section has pmi file.');


# Analyse all data for project
$t->get_ok('/admin/project/modeling.sirius/analyse')
    ->status_is(200)
    ->content_like(qr!Data for project modeling.sirius has been analysed.!i, 
      'Message states that data has been analysed.')
    ->content_like(qr!<td>modeling.sirius_metrics.json!i, 
      'Data files include generated metrics.');

# TODO add test to push new snapshot twice (second should have nothing new to push).

# Clean: remove project for data and projects
my $ret = remove_tree('data/modeling.sirius/', {verbose => 1});
print Dumper($ret);
#if ($ret != 0) { die "Could not delete data! \n" }
$ret = remove_tree('projects/modeling.sirius/', {verbose => 1});
#if ($ret != 0) { die "Could not delete projects! \n" }
$ret = remove_tree('.git', {verbose => 1});
#if ($ret != 0) { die "Could not delete .git! \n" }

done_testing(72);
