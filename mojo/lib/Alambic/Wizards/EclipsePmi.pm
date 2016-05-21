package Alambic::Wizards::EclipsePmi;

use strict; 
use warnings;

use Mojo::JSON qw( decode_json encode_json );
use Data::Dumper;


# Main configuration hash for the plugin
my %conf = (
    "id" => "EclipsePmi",
    "name" => "Eclipse PMI Wizard",
    "desc" => [
	'The Eclipse PMI wizard creates a new project with all data source plugins needed to analyse a project from the Eclipse forge. It retrieves and uses values from the PMI repository to set the plugin parameters automatically.',
    ],
    "params" => {
    },
    "plugins" => [
	"EclipsePmi",
	"EclipseIts",
	"Hudson",
    ],
);

my $eclipse_url = "https://projects.eclipse.org/json/project/";
my $polarsys_url = "https://polarsys.org/json/project/";


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
	"EclipsePmi" => { 'project_pmi' => $project_id },
	"EclipseIts" => { 'project_grim' => $project_id },
	"Hudson" => { 'hudson_url' => $project_ci },
    };

    my $project = Alambic::Model::Project->new( $project_id, $name, 0, 0, $plugins_conf );
    $project->desc($desc);
        
    return { 'project' => $project, 'log' => \@log };
}



1;
