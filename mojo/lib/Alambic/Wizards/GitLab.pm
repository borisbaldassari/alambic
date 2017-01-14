package Alambic::Wizards::EclipseGitLab;

use strict; 
use warnings;

use Mojo::JSON qw( decode_json encode_json );
use Data::Dumper;


# Main configuration hash for the plugin
my %conf = (
    "id" => "GitLab",
    "name" => "GitLab Wizard",
    "desc" => [
	'The GitLab wizard creates a new project with all data source plugins needed to analyse a project using all features from GitLab (ITS, CI, SCM, WIKI).',
    ],
    "params" => {
	"gitlab_url" => "The URL of the GitLab server, e.g. https://gitlab.com",
    },
    "plugins" => [
	"GitLabCi",
#	"GitLabIts",
    ],
);



# Constructor
sub new {
    my ($class) = @_;
    
    return bless {}, $class;
}


sub get_conf() {
    return \%conf;
}


# Run plugin: retrieves data + compute_data 
sub run_wizard($$) {
    my ($self, $project_id) = @_;

    my @log;
    
    my $ua = Mojo::UserAgent->new;
    $ua->max_redirects(10);
    $ua->inactivity_timeout(60);

    # Fetch json file from projects.eclipse.org
    my ($url, $content);
    if ($project_id =~ m!^polarsys!) {
        $url = $polarsys_url . $project_id;
        push( @log, "[Plugins::EclipsePmi] Using PolarSys PMI infra at [$url]." );
        $content = $ua->get($url)->res->body;
    } else {
        $url = $eclipse_url . $project_id;
        push( @log, "[Plugins::EclipsePmi] Using Eclipse PMI infra at [$url]." );
        $content = $ua->get($url)->res->body;
    }

    # Check if we actually get some results.
    my $pmi = decode_json($content);
    my $project_pmi;
    if ( defined($pmi->{'projects'}{$project_id}) ) {
        $project_pmi = $pmi->{'projects'}{$project_id};
    } else {
        push( @log, "ERROR: Could not get [$url]!" );
        return { 'log' => \@log };
    }
    $project_pmi->{'pmi_url'} = $url;
    print Dumper($project_pmi);

    my $name = $project_pmi->{'title'};
    my $desc = $project_pmi->{'description'}->[0]->{'summary'};
    my $project_ci = $project_pmi->{'build_url'}->[0]->{'url'};

    my $plugins_conf = {
	"GitLabCi" => { 'project_pmi' => $project_id },
	"GitLabIts" => { 'gitlab_url' => $project_id },
	"Hudson" => { 'hudson_url' => $project_ci },
    };

    my $project = Alambic::Model::Project->new( $project_id, $name, 0, 0, $plugins_conf );
    $project->desc($desc);
        
    return { 'project' => $project, 'log' => \@log };
}



1;
