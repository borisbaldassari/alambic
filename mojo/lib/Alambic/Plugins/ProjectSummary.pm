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

package Alambic::Plugins::ProjectSummary;

use strict;
use warnings;

use Alambic::Tools::R;

use Mojo::UserAgent;
use Mojo::JSON qw( decode_json encode_json );
use Data::Dumper;

# Main configuration hash for the plugin
my %conf = (
  "id"   => "ProjectSummary",
  "name" => "Project summary",
  "desc" => [
    "The Project Summary plugin creates a bunch of exportable HTML snippets, images and badges.",
  ],
  "type"    => "post",
  "ability" => ['figs', 'viz'],
  "params"  => {
    "proxy" =>
      'If a proxy is required to access the <a href="https://shields.io">shields.io</a> web site, please provide its URL here. A blank field means no proxy, and the <code>default</code> keyword uses the proxy from environment variables, see <a href="https://alambic.io/Documentation/Admin/Projects.html">the online documentation about proxies</a> for more details. Example: <code>https://user:pass@proxy.mycorp:3777</code>.',
  },
  "provides_cdata"   => [],
  "provides_info"    => [],
  "provides_data"    => {},
  "provides_metrics" => {},
  "provides_figs"    => {
    "badge_attr_alambic.svg" =>
      "A badge to display current value of main quality attribute on an external web site (uses shields.io)",
    "badge_attr_root.svg" =>
      "A badge to display current value of main quality attribute on an external web site (uses shields.io)",
    "badge_psum_attrs.html" =>
      "A HTML snippet to display main quality attributes and their values.",
    "psum_attrs.html" =>
      "A HTML snippet to display main quality attributes and their values.",
    "badge_qm" => "A HTML snippet that displays main quality attributes.",
    "badge_project_main" =>
      "A HTML snippet that displays the name and description of the project.",
    "badge_qm_viz" =>
      "A HTML snippet that displays the quality model visualisation.",
    "badge_downloads" =>
      "A HTML snippet that displays downloads for main data.",
    "badge_plugins" =>
      "A HTML snippet that displays a list of plugins for the project.",
  },
  "provides_recs" => [],
  "provides_viz"  => {"badges.html" => "Badges",},
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
sub run_post($$) {
  my ($self, $project_id, $conf) = @_;

  # Get the params
  my $proxy_url = $conf->{'proxy'} || '';

  my @log;

  my $repofs  = Alambic::Model::RepoFS->new();
  my $models  = $conf->{'models'};
  my $project = $conf->{'project'};
  my $qm      = $project->get_qm(
    $models->get_qm(),
    $models->get_attributes(),
    $models->get_metrics()
  );
  my $run = $conf->{'last_run'};

  my $params
    = {"root.name" => $qm->[0]{"name"}, "root.value" => $qm->[0]{"ind"},};

  # Add value of direct children of main quality attribute
  # i.e. should be product/process/ecosystem
  foreach my $c (@{$qm->[0]{'children'}}) {
    $params->{$c->{'mnemo'}} = $c->{'ind'};
    $params->{"QMN_" . $c->{'mnemo'}} = $c->{'name'};
  }

  # Create badges in output for root attribute
  my $badge = &_create_badge($proxy_url, \@log, 'alambic', $qm->[0]{"ind"});
  $repofs->write_output($project_id, "badge_attr_alambic.svg", $badge);
  $badge = &_create_badge($proxy_url, \@log, $qm->[0]{'name'}, $qm->[0]{'ind'});
  $repofs->write_output($project_id, "badge_attr_root.svg", $badge);

  my $psum_attrs = &_create_psum_attrs($self, $params);
  $repofs->write_output($project_id, "badge_psum_attrs.html", $psum_attrs);


  # Foreach child of root attribute create a badge.
  foreach my $attr (@{$qm->[0]{'children'}}) {
    $badge = &_create_badge($proxy_url, \@log, $attr->{'name'}, $attr->{'ind'});
    $repofs->write_output($project_id,
      "badge_attr_" . $attr->{'name'} . ".svg", $badge);
  }

  # Execute the figures R scripts.
  my $r = Alambic::Tools::R->new();
  push(@log, "[Plugins::ProjectSummary] Executing R snippet files.");
  @log = (
    @log,
    @{
      $r->knit_rmarkdown_html('ProjectSummary', $project_id, 'psum_attrs.rmd',
        [], $params)
    }
  );

  # Now generate the main html document.
  push(@log, "[Plugins::ProjectSummary] Executing R report.");
  $r   = Alambic::Tools::R->new();
  @log = (
    @log, @{$r->knit_rmarkdown_inc('ProjectSummary', $project_id, 'badges.Rmd')}
  );

  return {"metrics" => {}, "recs" => [], "info" => {}, "log" => \@log,};
}

sub _create_badge($$$) {
  my $proxy_url = shift;
  my $log       = shift;
  my $name      = shift || "";
  my $value     = shift || 0;

  my @colours = ("red", "orange", "yellow", "green", "brightgreen");

  my $url
    = 'https://img.shields.io/badge/'
    . $name . '-'
    . $value
    . '%20%2F%205-'
    . $colours[int($value)] . '.svg';

  my $ua = Mojo::UserAgent->new;

  # Configure Proxy
  if ($proxy_url =~ m!^default!i) {

    # If 'default', then use detect
    $ua->proxy->detect;
    my $proxy_http  = $ua->proxy->http;
    my $proxy_https = $ua->proxy->https;
    push(@$log,
      "[Plugins::ProjectSummary] Using default proxy [$proxy_http] and [$proxy_https]."
    );
  }
  elsif ($proxy_url =~ m!\S+!) {

    # If something, then use it
    $ua->proxy->http($proxy_url)->https($proxy_url);
    push(@$log, "[Plugins::ProjectSummary] Using provided proxy [$proxy_url].");
  }
  else {
    # If blank, then use no proxy
    push(@$log, "[Plugins::ProjectSummary] No proxy defined [$proxy_url].");
  }

  # GET the resource
  my $svg = $ua->get($url)->res->body;

  push(@$log, "[Plugins::ProjectSummary] Create badge for [$name].");

  return $svg;
}

sub _create_psum_attrs() {
  my ($self, $params) = @_;

  my $root_value = $params->{'root.value'} || '';
  my $root_name  = $params->{'root.name'}  || '';

  my $html_t = qq'<!DOCTYPE html>
    <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
      <meta charset="utf-8">
      <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
      <meta name="generator" content="pandoc" />

      <link href="/css/bootstrap.min.css" rel="stylesheet">
      <link href="/css/plugins/metisMenu/metisMenu.min.css" rel="stylesheet">
      <link href="/css/sb-admin-2.css" rel="stylesheet">
      <link rel="stylesheet" type="text/css" href="/css/font-awesome.min.css">
      <link rel="stylesheet" href="/css/default.css">
    </head>

    <body style=\'font-family: "arial"; font-color: #3E3F3A; margin: 10px\'">
      <div class="panel panel-default">
        <div class="panel-heading">
          $root_name <span class="pull-right">$root_value / 5</span>
        </div>
        <table class="table table-striped">
';

  my @ids = grep { $_ =~ /^QM_/ } sort keys %$params;

  foreach my $id (@ids) {
#    print "DBG QM $id.";
    $html_t
      .= '<tr><td><a href="/documentation/attributes.html#'
      . $id . '">'
      . $params->{'QMN_' . $id}
      . '</a><span class="pull-right">'
      . $params->{$id}
      . " / 5</span></td></tr>\n";
  }

  $html_t .= qq'
        </table>
      </div>
    </body>
    </html>';

  return $html_t;
}


1;


=encoding utf8

=head1 NAME

B<Alambic::Plugins::ProjectSummary> - A plugin to display badges 
and exportable snippets about the project's analysis.

=head1 DESCRIPTION

B<Alambic::Plugins::ProjectSummary> provides exportable html snippets 
and images about the project's analysis results.

Parameters: None

For the complete description of the plugin see the user documentation on the web site: L<https://alambic.io/Plugins/Pre/ProjectSummary.html>.

=head1 SEE ALSO

L<https://alambic.io/Plugins/Pre/ProjectSummary.html>,

L<Mojolicious>, L<http://alambic.io>, L<https://bitbucket.org/BorisBaldassari/alambic>


=cut
