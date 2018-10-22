#########################################################
#
# Copyright (c) 2015-2017 Castalia Solutions and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
#
# Contributors:
#   Boris Baldassari - Castalia Solutions
#
#########################################################

package Alambic::Wizards::EclipsePmi;

use strict;
use warnings;

use Mojo::JSON qw( decode_json encode_json );
use Mojo::UserAgent;
use Alambic::Model::Project;
use Data::Dumper;


# Main configuration hash for the plugin
my %conf = (
  "id"   => "EclipsePmi",
  "name" => "Eclipse PMI Wizard",
  "desc" => [
    'The Eclipse PMI wizard creates a new project with all data source plugins needed to analyse a project from the Eclipse forge, including Eclipse ITS (Bugzilla), Eclipse PMI, Git SCM and Jenkins CI. It retrieves and uses values from the PMI repository to set the plugin parameters automatically.',
    "This wizard only creates the plugins that should always be available. Depending on the project's configuration and data sources availability, other plugins may be needed and can manually be added to the configuration.",
  ],
  "params"  => {"proxy_url" => "The proxy to be used to access remote data, if any."},
  "plugins" => ["EclipsePmi", "Jenkins", "Git", "Bugzilla", "ProjectSummary"],
);

my $eclipse_url  = "https://projects.eclipse.org/json/project/";
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
sub run_wizard($) {
  my ($self, $project_id, $conf) = @_;

  my $proxy_url = $conf->{'proxy'} || '';

  my @log;

  my $ua = Mojo::UserAgent->new;
  $ua->max_redirects(10);
  $ua->inactivity_timeout(60);

  # Fetch json file from projects.eclipse.org
  my ($url, $content);
  if ($project_id =~ m!^polarsys!) {
    $url = $polarsys_url . $project_id;
    push(@log, "[Plugins::EclipsePmi] Using PolarSys PMI infra at [$url].");
    $content = $ua->get($url)->res->body;
  }
  else {
    $url = $eclipse_url . $project_id; 
    push(@log, "[Plugins::EclipsePmi] Using Eclipse PMI infra at [$url].");
    $content = $ua->get($url)->res->body;
  }

  # Just make sure we actually received something useful.
  if ( length($content) < 5 ) {
    push(@log, "ERROR: Could not get anything useful from [$url]! \n"
	 . "Maybe the project.id is not right?");
    return {'log' => \@log};
  }
  
  
  # Check if we actually get some results.
  my $pmi = decode_json($content);
  my $project_pmi; 
  if (defined($pmi->{'projects'}{$project_id})) {
    $project_pmi = $pmi->{'projects'}{$project_id};
  }
  else {
    push(@log, "ERROR: Could not get [$url]!");
    return {'log' => \@log};
  }
  $project_pmi->{'pmi_url'} = $url;

  my $name         = $project_pmi->{'title'};
  my $desc         = $project_pmi->{'description'}[0]{'summary'};
  my $project_ci   = $project_pmi->{'build_url'}[0]{'url'};
  my $project_git  = $project_pmi->{'source_repo'}[0]{'url'};
  my $bz_product   = $project_pmi->{'bugzilla'}[0]{'product'};
  my $bz_url_enter = $project_pmi->{'bugzilla'}[0]{'create_url'};
  $bz_url_enter    =~ m!^(http.+/)enter_bug\.cgi.+!;
  my $bz_url       = $1;
  
  my $plugins_conf = {
    "EclipsePmi"     => {'proxy' => $proxy_url, 'project_pmi' => $project_id},
    "Jenkins"        => {'proxy' => $proxy_url, 'jenkins_url'  => $project_ci},
    "Bugzilla"       => {
      "proxy" => $proxy_url, 
      "bugzilla_project" => $bz_product, 
      "bugzilla_url"     => $bz_url,
    },
    "Git"            => {
      'proxy' => $proxy_url, 
      'git_url'     => $project_git},
    "ProjectSummary" => { 'proxy' => $proxy_url },
  };

  my $project
    = Alambic::Model::Project->new($project_id, $name, 0, 0, $plugins_conf);
  $project->desc($desc);

  return {'project' => $project, 'log' => \@log};
}


1;


=encoding utf8

=head1 NAME

B<Alambic::Wizards::EclipsePmi> - A wizard plugin to add a project 
from the Eclipse forge.

=head1 DESCRIPTION

B<Alambic::Wizards::EclipsePmi> provides a way to easily initialise a project
from the Eclipse forge. 

Parameters:

=over

=item * Eclipse project ID - e.g. modeling.sirius or tools.cdt.

=back

Plugins automatically initialised with this wizard:

=over

=item * EclipsePmi - Get project information from the Eclipse PMI.

=item * Bugzilla - For Issue tracking.

=item * Jenkins - For Continuous Integration (works with Hudson too).

=item * Git - For SCM.

=item * ProjectSummary - For exportable figures and badges.

=back

=head1 SEE ALSO

L<Mojolicious>, L<http://alambic.io>, L<https://bitbucket.org/BorisBaldassari/alambic>

=cut

