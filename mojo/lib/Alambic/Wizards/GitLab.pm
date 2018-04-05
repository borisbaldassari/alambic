package Alambic::Wizards::GitLab;

use strict; 
use warnings;

use GitLab::API::v4;
use Mojo::JSON qw( decode_json encode_json );
use Data::Dumper;


# Main configuration hash for the plugin
my %conf = (
    "id" => "GitLab",
    "name" => "GitLab Wizard",
    "desc" => [
	'The GitLab wizard creates a new project with all data source plugins needed to analyse a project using all features from GitLab (ITS, SCM).',
    ],
    "params" => {
	"gitlab_url" => "The URL of the GitLab server, e.g. https://gitlab.com",
	"gitlab_id" => "The ID or namespace of the project to analyse, e.g. 13 or bbaldassari/Alambic",
	"gitlab_token" => "The Access token to use for the authentication. You can get it from <a href=\"https://gitlab.com/profile/personal_access_tokens\">https://gitlab.com/profile/personal_access_tokens</a>. tiPs2VdkhaDnfmteiToD",
    },
    "plugins" => [
	"GitLabProject",
	"GitLabIts",
	"Git",
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
sub run_wizard($$$) {
    my ($self, $project_id, $conf) = @_;

    my $gitlab_id = $conf->{'gitlab_id'};
    my $gitlab_url = $conf->{'gitlab_url'};
    my $gitlab_token = $conf->{'gitlab_token'};
    
    my @log;
    my %info;
    
    # Create GitLab API object for all rest operations.
    my $api = GitLab::API::v4->new(
        url   => $gitlab_url . "/api/v4",
        token => $gitlab_token,
	);
    push( @log, "[Wizards::GitLab] Retrieving information from [$gitlab_url] with id [$gitlab_id]." );
    
    # Call all info about the project.
    my $gl_project = $api->project(
        $gitlab_id,
    );
    
    my $name = $gl_project->{'name'} || 'UNKNOWN';
    my $desc = $gl_project->{'description'} || 'UNKNOWN';
    $info{'GL_PROJECT_WEB_URL'} = $gl_project->{'web_url'};
    $info{'GL_PROJECT_ID'} = $gl_project->{'id'};
    my $git_url = $gl_project->{'http_url_to_repo'};
    
    my $plugins_conf = {
	"GitLabProject" => { 'gitlab_url' => $gitlab_url, 'gitlab_id' => $gitlab_id, 'gitlab_token' => $gitlab_token },
	"GitLabIts" => { 'gitlab_url' => $gitlab_url, 'gitlab_id' => $gitlab_id, 'gitlab_token' => $gitlab_token },
	"Git" => { 'git_url' => $git_url },
    };

    my $project = Alambic::Model::Project->new( $project_id, $name, 0, 0, $plugins_conf, { 'info' => \%info} );
    $project->desc($desc);
#    $project->info(\%info);
        
    return { 'project' => $project, 'log' => \@log };
}



1;
