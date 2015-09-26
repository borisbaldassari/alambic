use Mojo::Base -strict;

use Test::Mojo;
use Test::More;

# Include application
use FindBin;
require "$FindBin::Bin/../script/alambic";


my $t = Test::Mojo->new('Alambic');


# Enable redirects for logout.
$t->ua->max_redirects(10);
$t->ua->connect_timeout(10);
$t->ua->inactivity_timeout(15);

# Connect using POST.
$t->post_ok('/login' => form => {'username' => 'admin', 'password' => 'admin'})
    ->status_is(200)
    ->content_like(qr!<h2>Administration</h2>!i, 'Check title of administration page after login.');


# Install new repository.
$t->post_ok('/admin/repo/install' => form => {'git_repo' => 'git@bitbucket.org:BorisBaldassari/alambic_test.git'})
    ->status_is(200)
    ->content_like(qr!All data, configuration and executable files in Alambic!i, 'Initialise repository.')
    ->content_like(qr!<p>Fetch url is <code>git\@bitbucket.org:BorisBaldassari/alambic_test.git</code><br />!i, 'Fetch URL is well defined.')
    ->content_like(qr!<td>\[Alambic\] Initial push!i, 'Initial push is listed.');


# Create a new project modeling.sirius.
$t->post_ok( '/admin/projects/new' => form => {'name' => 'Sirius', 'id' => 'modeling.sirius'} )
    ->status_is(200)
    ->content_like(qr!<li><a href="/projects/modeling.sirius.html">Sirius</a></li>!i, 'Sirius project has been added.');

# Check that we have the right project page for the new project.
$t->get_ok('/admin/project/modeling.sirius')
    ->status_is(200)
    ->content_like(qr!<h2>Project modeling.sirius</h2>!i, 'Page after new project contains sirius.');

# Add a few new data sources: eclipse_grimoire
$t->post_ok('/admin/project/modeling.sirius/ds/eclipse_grimoire/new' => 
           form => {'project_id' => 'modeling.sirius', 
                    'grimoire_url' => 'http://dashboard.eclipse.org/data/json/'})
    ->status_is(200)
    ->content_like(qr!<td>Eclipse Grimoire</td><td>eclipse_grimoire</td><td></td>!i, 'Data source has been created on project.')
    ->content_like(qr!ds/eclipse_grimoire/retrieve"><i class="fa fa-download"></i>!i, 'Data source has retrieve link.')
    ->content_like(qr!ds/eclipse_grimoire/compute"><i class="fa fa-cogs"></i>!i, 'Data source has compute link.');


# Add a few new data sources: eclipse_pmi
$t->post_ok('/admin/project/modeling.sirius/ds/eclipse_pmi/new' => 
           form => {'project_id' => 'modeling.sirius', 
                    'pmi_url' => 'http://projects.eclipse.org/project'})
    ->status_is(200)
    ->content_like(qr!<td>Eclipse PMI</td><td>eclipse_pmi</td><td></td>!i, 'Data source has been created on project.')
    ->content_like(qr!ds/eclipse_pmi/retrieve"><i class="fa fa-download"></i>!i, 'Data source has retrieve link.')
    ->content_like(qr!ds/eclipse_pmi/compute"><i class="fa fa-cogs"></i>!i, 'Data source has compute link.');
    

# Add a few new data sources: stack_overflow
$t->post_ok('/admin/project/modeling.sirius/ds/stack_overflow/new' => 
           form => {'project_id' => 'modeling.sirius', 
                    'so_url' => 'http://projects.eclipse.org/project'})
    ->status_is(200)
    ->content_like(qr!<td>Stack Overflow metrics</td><td>stack_overflow</td><td></td>!i, 'Data source has been created on project.')
    ->content_like(qr!ds/stack_overflow/retrieve"><i class="fa fa-download"></i>!i, 'Data source has retrieve link.')
    ->content_like(qr!ds/stack_overflow/compute"><i class="fa fa-cogs"></i>!i, 'Data source has compute link.');
    

# Delete a data source: stack_overflow
$t->get_ok('/admin/project/modeling.sirius/ds/stack_overflow/del')
    ->status_is(200)
    ->content_unlike(qr!<td>Stack Overflow metrics</td><td>stack_overflow</td><td></td>!i, 'Data source has been deleted on project.')
    ->content_unlike(qr!ds/stack_overflow/retrieve"><i class="fa fa-download"></i>!i, 'Data source has not retrieve link.')
    ->content_unlike(qr!ds/stack_overflow/compute"><i class="fa fa-cogs"></i>!i, 'Data source has not compute link.');
    

# Then retrieve data for all data sources
$t->get_ok('/admin/project/modeling.sirius/retrieve')
    ->status_is(200)
    ->content_like(qr!Data for project modeling.sirius has been retrieved.!i, 'Message states that data has been retrieved.')
    ->content_like(qr!<li class="list-group-item">modeling.sirius_metrics_grimoire.json</li>!i, 'Input files section has metrics_grimoire.')
    ->content_like(qr!<li class="list-group-item">modeling.sirius_metrics_pmi.json</li>!i, 'Input files section has metrics_pmi.')
    ->content_like(qr!<li class="list-group-item">modeling.sirius_pmi.json</li>!i, 'Input files section has pmi file.');


# Analyse all data for project
$t->get_ok('/admin/project/modeling.sirius/analyse')
    ->status_is(200)
    ->content_like(qr!Data for project modeling.sirius has been analysed.!i, 'Message states that data has been analysed.')
    ->content_like(qr!<li class="list-group-item">modeling.sirius_metrics.json</li>!i, 'Data files include generated metrics.');

# TODO add test to push new snapshot twice (second should have nothing new to push).


done_testing(44);
