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

package Alambic::Plugins::EclipsePmi;

use strict;
use warnings;

use Alambic::Model::RepoFS;

use Mojo::JSON qw( decode_json encode_json );
use Mojo::UserAgent;
use Date::Parse;
use Mojolicious::Controller;
use Mojolicious::Renderer;
use Data::Dumper;


# Main configuration hash for the plugin
my %conf = (
  "id"   => "EclipsePmi",
  "name" => "Eclipse PMI",
  "desc" => [
    "Eclipse PMI Retrieves meta data about the project from the Eclipse PMI infrastructure.",
    'See <a href="https://alambic.io/Plugins/Pre/EclipsePmi.html">the project\'s documentation</a> for more information.',
  ],
  "type"    => "pre",
  "ability" => ["metrics", "info", 'data', "recs", "viz"],
  "params"  => {
    "project_pmi" =>
      "The project ID used to identify the project on the PMI server. Look for it in the URL of the project on <a href=\"http://projects.eclipse.org\">http://projects.eclipse.org</a>.",
    "proxy" =>
      'If a proxy is required to access the remote resource of this plugin, please provide its URL here. A blank field means no proxy, and the <code>default</code> keyword uses the proxy from environment variables, see <a href="https://alambic.io/Documentation/Admin/Projects.html">the online documentation about proxies</a> for more details. Example: <code>https://user:pass@proxy.mycorp:3777</code>.',
  },
  "provides_cdata" => [],
  "provides_info"  => [
      "PROJECT_MLS_DEV_URL",        
      "PROJECT_MLS_USR_URL",
      "PROJECT_URL",                 
      "PROJECT_WIKI_URL",
      "PROJECT_DOWNLOAD_URL",
      "PROJECT_SCM_URL",           
      "PROJECT_ITS_URL",           
      "PROJECT_CI_URL",             
      "PROJECT_DOC_URL",
      "PROJECT_NAME",         
      "PROJECT_DESC",               
      "PROJECT_ID",

      "PMI_BUGZILLA_CREATE_URL", 
      "PMI_BUGZILLA_COMPONENT",
      "PMI_BUGZILLA_PRODUCT",
      "PMI_BUGZILLA_QUERY_URL", 
      "PMI_GETTINGSTARTED_URL",
      "PMI_UPDATESITE_URL",
  ],
  "provides_data" => {
    "pmi.json" => "The PMI file as returned by the Eclipse repository (JSON).",
    "pmi_checks.json" => "The list of PMI checks and their results (JSON).",
    "pmi_checks.csv"  => "The list of PMI checks and their results (CSV).",
  },
  "provides_metrics" => {
    "PROJECT_ITS_INFO"    => "PROJECT_ITS_INFO",
    "PROJECT_SCM_INFO"    => "PROJECT_SCM_INFO",
    "PROJECT_MLS_INFO"    => "PROJECT_MLS_INFO",
    "PROJECT_CI_INFO"    => "PROJECT_CI_INFO",
    "PROJECT_DOC_INFO"    => "PROJECT_DOC_INFO",
    "PROJECT_DL_INFO" => "PROJECT_DL_INFO",
    "PROJECT_GETTINGSTARTED_INFO" => "PROJECT_GETTINGSTARTED_INFO",
    "PROJECT_ITS_ACCESS"    => "PROJECT_ITS_ACCESS",
    "PROJECT_SCM_ACCESS"    => "PROJECT_SCM_ACCESS",
    "PROJECT_MLS_ACCESS"    => "PROJECT_MLS_ACCESS",
    "PROJECT_CI_ACCESS"    => "PROJECT_CI_ACCESS",
    "PROJECT_DOC_ACCESS"    => "PROJECT_DOC_ACCESS",
    "PROJECT_DL_ACCESS" => "PROJECT_DL_ACCESS",
    "PROJECT_REL_VOL"     => "PROJECT_REL_VOL",
    "PROJECT_ACCESS_INFO"     => "PROJECT_ACCESS_INFO",

    "OSS_INCLUSION"     => "OSS_INCLUSION",
    "OSS_ESCALATE"     => "OSS_ESCALATE",
    "OSS_DEP_CHECK" => "OSS_DEP_CHECK",
    "DOC_GOV"     => "DOC_GOV",
    "GOV_BOARD_PUBLIC"     => "GOV_BOARD_PUBLIC",
  },
  "provides_figs" => {},
  "provides_recs" => [
    "PMI_EMPTY_BUGZILLA_CREATE", "PMI_NOK_BUGZILLA_CREATE",
    "PMI_EMPTY_BUGZILLA_QUERY",  "PMI_NOK_BUGZILLA_QUERY",
    "PMI_EMPTY_TITLE",           "PMI_NOK_WEB",
    "PMI_EMPTY_WEB",             "PMI_NOK_WIKI",
    "PMI_EMPTY_WIKI",            "PMI_NOK_DOWNLOAD",
    "PMI_EMPTY_DOWNLOAD",        "PMI_NOK_GETTING_STARTED",
    "PMI_EMPTY_GETTING_STARTED", "PMI_NOK_DOC",
    "PMI_EMPTY_DOC",             "PMI_NOK_PLAN",
    "PMI_EMPTY_PLAN",            "PMI_NOK_PROPOSAL",
    "PMI_EMPTY_PROPOSAL",        "PMI_NOK_DEV_ML",
    "PMI_EMPTY_DEV_ML",          "PMI_NOK_USER_ML",
    "PMI_EMPTY_USER_ML",         "PMI_NOK_SCM",
    "PMI_EMPTY_SCM",             "PMI_NOK_UPDATE",
    "PMI_EMPTY_UPDATE",          "PMI_NOK_CI",
    "PMI_EMPTY_CI",              "PMI_EMPTY_REL",
  ],
  "provides_viz" => {"pmi_checks" => "Eclipse PMI Checks",},
);

my $eclipse_url  = "https://projects.eclipse.org/json/project/";
my $polarsys_url = "https://polarsys.org/json/project/";


# Constructor to build a new EclipsePmi object.
sub new {
  my ($class) = @_;

  return bless {}, $class;
}

# Get Wizard plugin configuration.
sub get_conf() {
  return \%conf;
}


# Run wizard plugin: retrieves data + compute_data.
sub run_plugin($$) {
  my ($self, $project_id, $conf) = @_;

  my $project_pmi = $conf->{'project_pmi'} || $project_id;
  my $proxy_url   = $conf->{'proxy'}       || '';

  my %ret = ('metrics' => {}, 'info' => {}, 'recs' => [], 'log' => [],);

  # Create RepoFS object for writing and reading files on FS.
  my $repofs = Alambic::Model::RepoFS->new();

  # Retrieve and store data from the remote repository.
  my $ret_tmp = &_retrieve_data($project_id, $project_pmi, $proxy_url, $repofs);
  if (not defined($ret_tmp)) {
    return {'log' => ['Could not fetch anything useful from PMI.']};
  }
  else {
    $ret{'log'} = $ret_tmp;
  }

  # Analyse retrieved data, generate info, metrics, plots and visualisation.
  my $tmp_ret = &_compute_data($project_id, $project_pmi, $proxy_url, $repofs);

  $ret{'metrics'} = $tmp_ret->{'metrics'};
  $ret{'info'}    = $tmp_ret->{'info'};
  $ret{'recs'}    = $tmp_ret->{'recs'};
  push(@{$ret{'log'}}, @{$tmp_ret->{'log'}});

  return \%ret;
}


sub _retrieve_data($$$) {
  my ($project_id, $project_pmi, $proxy_url, $repofs) = @_;

  my @log;

  my $ua = Mojo::UserAgent->new;
  $ua->max_redirects(10);
  $ua->inactivity_timeout(60);

  # Configure Proxy
  if ($proxy_url =~ m!^default!i) {

    # If 'default', then use detect
    $ua->proxy->detect;
    my $proxy_http  = $ua->proxy->http;
    my $proxy_https = $ua->proxy->https;
    push(@log,
      "[Plugins::EclipsePmi] Using default proxy [$proxy_http] and [$proxy_https]."
    );
  }
  elsif ($proxy_url =~ m!\S+!) {

    # If something, then use it
    $ua->proxy->http($proxy_url)->https($proxy_url);
    push(@log, "[Plugins::EclipsePmi] Using provided proxy [$proxy_url].");
  }
  else {
    # If blank, then use no proxy
    push(@log, "[Plugins::EclipsePmi] No proxy defined [$proxy_url].");
  }

  # Fetch json file from projects.eclipse.org
  my ($url, $content);
  if ($project_id =~ m!^polarsys!) {
    $url = $polarsys_url . $project_pmi;
    push(@log, "[Plugins::EclipsePmi] Using PolarSys PMI infra at [$url].");
    $content = $ua->get($url)->res->body;

#    sleep 1; why the hell do we sleep?
  }
  else {
    $url = $eclipse_url . $project_pmi;
    push(@log, "[Plugins::EclipsePmi] Using Eclipse PMI infra at [$url].");
    $content = $ua->get($url)->res->body;
  }

  # Check if we actually get some results.
  my $pmi;
  my $is_ok = 0;
  eval {
    $pmi   = decode_json($content);
    $is_ok = 1;
  };
  return undef unless $is_ok;

  my $custom_pmi;
  if (defined($pmi->{'projects'}{$project_pmi})) {
    $custom_pmi = $pmi->{'projects'}{$project_pmi};
  }
  else {
    return undef unless defined $content;
  }
  $custom_pmi->{'pmi_url'} = $url;

  push(@log, "[Plugins::EclipsePmi] Writing PMI json file to input.");
  $repofs->write_input($project_id, "import_pmi.json",
    encode_json($custom_pmi));

  return \@log;
}

sub _compute_data($) {
  my ($project_id, $project_pmi, $proxy_url, $repofs) = @_;

  my %info;
  my %metrics;
  my @recs;
  my @log;
  my $checks_ok;
  my $checks_nok;
  my $pub_doc_info    = 0;
  my $pub_access_info = 0;

  # Initialise boolean metrics with zeros..
  $metrics{"PROJECT_DL_ACCESS"} = 0;
  $metrics{"PROJECT_DOC_ACCESS"} = 0;
  $metrics{"PROJECT_CI_ACCESS"} = 0;
  $metrics{"PROJECT_ITS_ACCESS"} = 0;
  $metrics{"PROJECT_SCM_ACCESS"} = 0;
  $metrics{"PROJECT_MLS_ACCESS"} = 0;
  $metrics{"PROJECT_GETTINGSTARTED_INFO"} = 0;
  $metrics{"PROJECT_DL_INFO"} = 0;
  $metrics{"PROJECT_CI_INFO"} = 0;
  $metrics{"PROJECT_SCM_INFO"} = 0;
  $metrics{"PROJECT_ITS_INFO"} = 0;
  $metrics{"PROJECT_MLS_INFO"} = 0;

  # At Eclipse, all projects benefit from the forge's
  # community guidelines and processes. 
  $metrics{"OSS_INCLUSION"} = 1;
  $metrics{"OSS_ESCALATE"} = 1;
  $metrics{"DOC_GOV"} = 1;
  $metrics{"GOV_BOARD_PUBLIC"} = 1;
  $metrics{"OSS_DEP_CHECK"} = 1;

  push(@log, "[Plugins::EclipsePmi] Starting compute data for [$project_id].");

  my $ua = Mojo::UserAgent->new;
  $ua->max_redirects(10);
  $ua->inactivity_timeout(60);

  # Configure Proxy
  if ($proxy_url =~ m!^default!i) {

    # If 'default', then use detect
    $ua->proxy->detect;
    my $proxy_http  = $ua->proxy->http;
    my $proxy_https = $ua->proxy->https;
    push(@log,
      "[Plugins::EclipsePmi] Using default proxy [$proxy_http] and [$proxy_https]."
    );
  }
  elsif ($proxy_url =~ m!\S+!) {

    # If something, then use it
    $ua->proxy->http($proxy_url)->https($proxy_url);
    push(@log, "[Plugins::EclipsePmi] Using provided proxy [$proxy_url].");
  }
  else {
    # If blank, then use no proxy
    push(@log, "[Plugins::EclipsePmi] No proxy defined [$proxy_url].");
  }

  # Read data from pmi file in $data_input
  my $json = $repofs->read_input($project_id, "import_pmi.json");

  # Decode the entire JSON
  my $raw_project = decode_json($json)
    or push(@log, "ERROR: Could not decode json: \n$json");

  # Retrieve basic information about the project
  $info{"PROJECT_NAME"} = $raw_project->{"title"};
  $info{"PROJECT_DESC"}  = $raw_project->{"description"}->[0]->{"safe_value"};
  $info{"PROJECT_ID"}    = $raw_project->{"id"}->[0]->{"value"};

  # Retrieve information about Bugzilla
  my $pub_its_info = 0;
  if (scalar @{$raw_project->{"bugzilla"}} > 0) {

    $info{"PMI_BUGZILLA_PRODUCT"}
      = $raw_project->{"bugzilla"}->[0]->{"product"};
    if ($info{"PMI_BUGZILLA_PRODUCT"} =~ m!\S+!) {
      $pub_its_info++;
    }
    else {
      push(
        @recs,
        {
          'rid'      => 'PMI_EMPTY_BUGZILLA_PRODUCT',
          'severity' => 2,
          'desc' =>
            'The Bugzilla product entry is empty in the PMI. People willing to enter a bug for the first time will look for it.'
        }
      );
    }

    $info{"PMI_BUGZILLA_COMPONENT"}
      = $raw_project->{"bugzilla"}->[0]->{"component"};

    $info{"PMI_BUGZILLA_CREATE_URL"}
      = $raw_project->{"bugzilla"}->[0]->{"create_url"};
    if ($info{"PMI_BUGZILLA_CREATE_URL"} =~ m!\S+!) {
      $pub_its_info++;
    }
    else {
      push(
        @recs,
        {
          'rid'      => 'PMI_EMPTY_BUGZILLA_CREATE',
          'severity' => 2,
          'desc' =>
            'The Bugzilla URL entry to create a bug is empty in the PMI. People willing to enter a bug for the first time will look for it.'
        }
      );
    }

    if ($ua->head($info{"PMI_BUGZILLA_CREATE_URL"})) {
      $pub_its_info++;
    }
    else {
      push(
        @recs,
        {
          'rid'      => 'PMI_NOK_BUGZILLA_CREATE',
          'severity' => 2,
          'desc'     => 'The Bugzilla URL ['
            . $info{"PMI_BUGZILLA_CREATE_URL"}
            . '] entry to create bug in the PMI cannot be accessed.'
        }
      );
    }

    $info{"PMI_BUGZILLA_QUERY_URL"}
      = $raw_project->{"bugzilla"}->[0]->{"query_url"};
    if ($info{"PMI_BUGZILLA_QUERY_URL"} =~ m!\S+!) {
      $pub_its_info++;
    }
    else {
      push(
        @recs,
        {
          'rid'      => 'PMI_EMPTY_BUGZILLA_QUERY',
          'severity' => 2,
          'desc' =>
            'The Bugzilla URL entry to query bugs is empty in the PMI. People willing to search for a bug for the first time will look for it.'
        }
      );
    }

    if ($ua->head($info{"PMI_BUGZILLA_QUERY_URL"})) {
      $pub_its_info++;
    }
    else {
      push(
        @recs,
        {
          'rid'      => 'PMI_NOK_BUGZILLA_QUERY',
          'severity' => 2,
          'desc'     => 'The Bugzilla URL ['
            . $info{"PMI_BUGZILLA_QUERY_URL"}
            . '] to query bugs in the PMI cannot be accessed.'
        }
      );
    }
  }
  $metrics{"PROJECT_ITS_INFO"} = $pub_its_info;

  my $ret_check;
  $ret_check->{'pmi'}         = $raw_project;
  $ret_check->{'id_pmi'}      = $project_pmi;
  $ret_check->{'pmi_url'}     = $raw_project->{'pmi_url'};
  $ret_check->{'name'}        = $raw_project->{'title'};
  $ret_check->{'last_update'} = time();

  # $ua = Mojo::UserAgent->new;
  # $ua->max_redirects(10);

  # Test title
  my $proj_name = $raw_project->{'title'};
  my $check;
  $check->{'value'} = $proj_name;
  push(
    @{$check->{'results'}},
    ($proj_name !~ m!^\s*$!) ? 'OK' : 'Failed: no title defined.'
  );
  $check->{'desc'} = 'Checks if a name is defined for the project: !~ m!^\s*$!';
  $ret_check->{'checks'}->{'title'} = $check;
  if ($proj_name !~ m!^\s*$!) {
    push(
      @recs,
      {
        'rid'      => 'PMI_EMPTY_TITLE',
        'severity' => 2,
        'desc'     => 'The title entry is empty in the PMI.'
      }
    );
  }

  # Check website_url info
  if (exists($raw_project->{'website_url'}[0])) {
    $pub_doc_info++;
  }

  # Test Web site
  $check = {};
  $check->{'results'} = [];
  $check->{'desc'}
    = 'Checks if the URL can be fetched using a simple get query.';
  my $url;
  if (exists($raw_project->{'website_url'}->[0]->{'url'})) {
    $info{"PROJECT_MAIN_URL"} = $raw_project->{'website_url'}->[0]->{'url'};
    $check->{'value'} = $info{"PROJECT_MAIN_URL"};
    my $results = &_check_url($ua, $info{"PROJECT_MAIN_URL"}, 'Website');
    push(@{$check->{'results'}}, $results);
    if ($results !~ /^OK/) {
      push(
        @recs,
        {
          'rid'      => 'PMI_NOK_WEB',
          'severity' => 3,
          'desc' =>
            "The web site URL [$url] cannot be retrieved in the PMI. The URL should be checked."
        }
      );
    }
  }
  else {
    push(@{$check->{'results'}}, "Failed: no URL defined for website_url.");
    push(
      @recs,
      {
        'rid'      => 'PMI_EMPTY_WEB',
        'severity' => 3,
        'desc'     => 'The web site URL is missing in the PMI.'
      }
    );
  }
  $ret_check->{'checks'}->{'website_url'} = $check;

  # Check wiki_url info
  if (exists($raw_project->{'wiki_url'}[0])) {
    $pub_doc_info++;
  }

  # Test Wiki
  $check = {};
  $check->{'results'} = [];
  $check->{'desc'}
    = "Sends a get request to the project wiki URL and looks at the headers in the response (200, 404..).";
  if (exists($raw_project->{'wiki_url'}->[0]->{'url'})) {
    my $url = $raw_project->{'wiki_url'}->[0]->{'url'};
    $info{"PROJECT_WIKI_URL"} = $url;
    $check->{'value'} = $info{"PROJECT_WIKI_URL"};
    my $results = &_check_url($ua, $url, 'Wiki');
    push(@{$check->{'results'}}, $results);
    if ($results !~ /^OK/) {
      push(
        @recs,
        {
          'rid'      => 'PMI_NOK_WIKI',
          'severity' => 3,
          'desc' =>
            "The wiki URL [$url] in the PMI cannot be retrieved. It helps people understand and use the product and should be fixed."
        }
      );
    }
  }
  else {
    push(@{$check->{'results'}}, "Failed: no URL defined for wiki_url.");
    push(
      @recs,
      {
        'rid'      => 'PMI_EMPTY_WIKI',
        'severity' => 3,
        'desc' =>
          'The wiki URL is missing in the PMI. It helps people understand and use the product and should be filled.'
      }
    );
  }
  $ret_check->{'checks'}->{'wiki_url'} = $check;

  # Test Bugzilla create url
  $check = {};
  $check->{'results'} = [];
  $check->{'desc'}
    = 'Checks if the URL can be fetched using a simple get query.';
  if (exists($raw_project->{'bugzilla'}->[0]->{'create_url'})) {
    $url = $raw_project->{'bugzilla'}->[0]->{'create_url'};
    $check->{'value'} = $url;
    push(@{$check->{'results'}}, &_check_url($ua, $url, 'Create'));
  }
  else {
    push(@{$check->{'results'}}, "Failed: no URL defined for create_url.");
  }
  $ret_check->{'checks'}->{'bugzilla_create_url'} = $check;


  # Test Bugzilla query url
  $check = {};
  $check->{'results'} = [];
  $check->{'desc'}
    = 'Checks if the URL can be fetched using a simple get query.';
  if (exists($raw_project->{'bugzilla'}->[0]->{'query_url'})) {
    $url = $raw_project->{'bugzilla'}->[0]->{'query_url'};
    $check->{'value'} = $url;
    push(@{$check->{'results'}}, &_check_url($ua, $url, 'Query'));
  }
  else {
    push(@{$check->{'results'}}, "Failed: no URL defined for query_url.");
  }
  $ret_check->{'checks'}->{'bugzilla_query_url'} = $check;

  # Check download_url info
  if (exists($raw_project->{'download_url'}[0])) {
    $pub_access_info++;
  }

  # Check downloads info
  if (exists($raw_project->{'downloads'}[0])) {
    $pub_access_info++;
  }

  # Test Download url
  $check = {};
  $check->{'results'} = [];
  $check->{'desc'}
    = 'Checks if the URL can be fetched using a simple get query.';
  if (exists($raw_project->{'download_url'}->[0]->{'url'})) {
    $metrics{"PROJECT_DL_INFO"} ++;
    $info{"PROJECT_DOWNLOAD_URL"} = $raw_project->{'download_url'}->[0]->{'url'};
    $url                      = $raw_project->{'download_url'}->[0]->{'url'};
    $check->{'value'}         = $url;
    push(@{$check->{'results'}}, &_check_url($ua, $url, 'Download'));
    if ($check->{'results'}[-1] !~ /^OK/) {
      push(
        @recs,
        {
          'rid'      => 'PMI_NOK_DOWNLOAD',
          'severity' => 3,
          'desc' =>
            "The download URL [$url] cannot be retrieved in the PMI. People need it to download, use, and contribute to the project and should be correctly filled."
        }
      );
    } else {
      $metrics{"PROJECT_DL_ACCESS"}++;
    }
  }
  else {
    push(@{$check->{'results'}}, "Failed: no URL defined for download_url.");
    push(
      @recs,
      {
        'rid'      => 'PMI_EMPTY_DOWNLOAD',
        'severity' => 3,
        'desc' =>
          'The download URL is empty in the PMI. People need it to download, use, and contribute to the project and should be correctly filled.'
      }
    );
  }
  $ret_check->{'checks'}->{'download_url'} = $check;

  # Check gettingstarted_url info
  if (exists($raw_project->{'gettingstarted_url'}[0])) {
    $pub_doc_info++;
  }

  # Test Getting started url
  $check = {};
  $check->{'results'} = [];
  $check->{'desc'}
    = 'Checks if the URL can be fetched using a simple get query.';
  if (exists($raw_project->{'gettingstarted_url'}->[0]->{'url'})) {
    $info{"PROJECT_GETTINGSTARTED_URL"}
      = $raw_project->{'gettingstarted_url'}->[0]->{'url'};
    $url = $raw_project->{'gettingstarted_url'}->[0]->{'url'};
    $check->{'value'} = $url;
    push(@{$check->{'results'}}, &_check_url($ua, $url, 'Documentation'));
    if ($check->{'results'}[-1] !~ /^OK/) {
      push(
        @recs,
        {
          'rid'      => 'PMI_NOK_GETTING_STARTED',
          'severity' => 1,
          'desc' =>
            "The getting started URL [$url] cannot be retrieved in the PMI. It helps people use, and contribute to, the project and should be correctly filled."
        }
      );
    }
    $metrics{"PROJECT_GETTINGSTARTED_INFO"} = 1;
  }
  else {
    push(
      @{$check->{'results'}},
      "Failed: no URL defined for gettingstarted_url."
    );
    push(
      @recs,
      {
        'rid'      => 'PMI_EMPTY_GETTING_STARTED',
        'severity' => 1,
        'desc' =>
          'The getting started URL is empty in the PMI. It helps people use, and contribute to, the project and should be correctly filled.'
      }
    );
  }
  $ret_check->{'checks'}->{'gettingstarted_url'} = $check;

  # Check build_doc info
  if (exists($raw_project->{'build_doc'}[0])) {
    $pub_doc_info++;
  }

  # Check documentation info
  if (exists($raw_project->{'documentation'}[0])) {
    $pub_doc_info++;
  }

  # Check documentation_url info
  if (exists($raw_project->{'documentation_url'}[0])) {
    $pub_doc_info++;
  }

  # Test Documentation url
  $check = {};
  $check->{'results'} = [];
  $check->{'desc'}
    = 'Checks if the URL can be fetched using a simple get query.';
  if (exists($raw_project->{'documentation_url'}->[0]->{'url'})) {
    $info{"PROJECT_DOC_URL"}
      = $raw_project->{'documentation_url'}->[0]->{'url'};
    $url = $raw_project->{'documentation_url'}->[0]->{'url'};
    $check->{'value'} = $url;
    push(@{$check->{'results'}}, &_check_url($ua, $url, 'Documentation'));
    if ($check->{'results'}[-1] !~ /^OK/) {
      push(
        @recs,
        {
          'rid'      => 'PMI_NOK_DOC',
          'severity' => 1,
          'desc' =>
            "The documentation URL [$url] cannot be retrieved in the PMI. It helps people use, and contribute to, the project and should be correctly filled."
        }
      );
    } else {
      $metrics{"PROJECT_DOC_ACCESS"} = 1;
    }
  }
  else {
    push(
      @{$check->{'results'}},
      "Failed: no URL defined for documentation_url."
    );
    push(
      @recs,
      {
        'rid'      => 'PMI_EMPTY_DOC',
        'severity' => 1,
        'desc' =>
          'The documentation URL is empty in the PMI. It helps people use, and contribute to, the project and should be correctly filled.'
      }
    );
  }
  $ret_check->{'checks'}->{'documentation_url'} = $check;

  # Test plan url
  $check = {};
  $check->{'results'} = [];
  $check->{'desc'}
    = 'Checks if the URL can be fetched using a simple get query.';
  if (exists($raw_project->{'plan_url'}->[0]->{'url'})) {
    $info{"PROJECT_PLAN_URL"} = $raw_project->{'plan_url'}->[0]->{'url'};
    $url                  = $raw_project->{'plan_url'}->[0]->{'url'};
    $check->{'value'}     = $url;
    push(@{$check->{'results'}}, &_check_url($ua, $url, 'Plan'));
    if ($check->{'results'}[-1] !~ /^OK/) {
      push(
        @recs,
        {
          'rid'      => 'PMI_NOK_PLAN',
          'severity' => 1,
          'desc' =>
            "The plan document URL [$url] cannot be retrieved in the PMI. It helps people understand the roadmap of the project and should be correctly filled."
        }
      );
    }
  }
  else {
    push(@{$check->{'results'}}, "Failed: no URL defined for plan.");
    push(
      @recs,
      {
        'rid'      => 'PMI_EMPTY_PLAN',
        'severity' => 1,
        'desc' =>
          'The plan document URL is empty in the PMI. It helps people understand the roadmap of the project and should be filled.'
      }
    );
  }
  $ret_check->{'checks'}->{'plan_url'} = $check;

  # Test proposal url
  $check = {};
  $check->{'results'} = [];
  $check->{'desc'}
    = 'Checks if the URL can be fetched using a simple get query.';
  if (exists($raw_project->{'proposal_url'}->[0]->{'url'})) {
    $url = $raw_project->{'proposal_url'}->[0]->{'url'};
    $check->{'value'} = $url;
    push(@{$check->{'results'}}, &_check_url($ua, $url, 'Proposal'));
    if ($check->{'results'}[-1] !~ /^OK/) {
      push(
        @recs,
        {
          'rid'      => 'PMI_NOK_PROPOSAL',
          'severity' => 1,
          'desc' =>
            "The proposal document URL [$url] cannot be retrieved in the PMI. It helps people understand the genesis of the project and should be correctly filled."
        }
      );
    }
  }
  else {
    push(@{$check->{'results'}}, "Failed: no URL defined for proposal.");
    push(
      @recs,
      {
        'rid'      => 'PMI_EMPTY_PROPOSAL',
        'severity' => 1,
        'desc' =>
          'The proposal document URL is empty in the PMI. It helps people understand the genesis of the project and should be filled.'
      }
    );
  }
  $ret_check->{'checks'}->{'proposal_url'} = $check;

  # Test dev_list url
  $check = {};
  $check->{'results'} = [];
  $check->{'desc'}
    = 'Checks if the Dev ML URL can be fetched using a simple get query.';
  if (ref($raw_project->{'dev_list'}) =~ m!HASH!) {
    $info{"PROJECT_MLS_DEV_URL"} = $raw_project->{'dev_list'}->{'url'};
    $url                     = $raw_project->{'dev_list'}->{'url'};
    $check->{'value'}        = $url;
    my $results = &_check_url($ua, $url, 'Dev ML');
    push(@{$check->{'results'}}, $results);
    if ($check->{'results'}[-1] !~ /^OK/) {
      push(
        @recs,
        {
          'rid'      => 'PMI_NOK_DEV_ML',
          'severity' => 3,
          'desc' =>
            "The developer mailing list URL [$url] in the PMI cannot be retrieved. It helps people know where to ask questions if they want to contribute."
        }
      );
    }
  }
  else {
    push(@{$check->{'results'}}, 'Failed: no dev mailing list defined.');
    push(
      @recs,
      {
        'rid'      => 'PMI_EMPTY_DEV_ML',
        'severity' => 3,
        'desc' =>
          'The developer mailing list URL is empty in the PMI. It helps people know where to ask questions if they want to contribute.'
      }
    );
  }
  $ret_check->{'checks'}->{'dev_list'} = $check;

  # Check mailing_lists info
  if (exists($raw_project->{'mailing_lists'}[0])) {
    $pub_doc_info++;
  }

  # Test mailing_lists
  $check = {};
  $check->{'results'} = [];
  $check->{'desc'}
    = 'Checks if the Mailing lists URL can be fetched using a simple get query.';
  my @mls = @{$raw_project->{'mailing_lists'}};
  if (scalar @mls > 0) {
    foreach my $ml (@mls) {
      $url = $ml->{'url'};
      my $name  = $ml->{'name'};
      my $email = $ml->{'email'};
      $check->{'value'} = $url;
      if ($email =~ m!.+@.+!) {
        push(
          @{$check->{'results'}},
          "OK. [$name] ML correctly defined with email."
        );
      }
      else {
        push(@{$check->{'results'}},
          "Failed: no email defined on [$name] ML .");
      }
      push(@{$check->{'results'}}, &_check_url($ua, $url, "[$name] ML"));
    }
  }
  else {
    push(@{$check->{'results'}}, 'Failed: no mailing list defined.');
  }
  $ret_check->{'checks'}->{'mailing_lists'} = $check;

  # Check forums info
  if (exists($raw_project->{'forums'}[0])) {
    $pub_doc_info++;
  }

  # Test forums
  $check = {};
  $check->{'results'} = [];
  $check->{'desc'}
    = 'Checks if the Forums URL can be fetched using a simple get query.';
  @mls = @{$raw_project->{'forums'}};
  if (scalar @mls > 0) {
    foreach my $ml (@mls) {
      $url = $ml->{'url'};
      my $name = $ml->{'name'};
      $info{"PROJECT_MLS_USR_URL"} = $url;
      $metrics{"PROJECT_MLS_INFO"}++;
      $check->{'value'} = $url;
      if ($name =~ m!\S+!) {
        push(@{$check->{'results'}}, "OK. Forum [$name] correctly defined.");
      }
      else {
        push(@{$check->{'results'}}, "Failed: no name defined on forum.");
      }
      push(@{$check->{'results'}}, &_check_url($ua, $url, "Forum [$name]"));
      if ($check->{'results'}[-1] !~ /^OK/) {
        push(
          @recs,
          {
            'rid'      => 'PMI_NOK_USER_ML',
            'severity' => 3,
            'desc' =>
              "The user mailing list / forum URL [$url] in the PMI cannot be retrieved. It helps people know where to ask questions if they want to use the product and should be fixed."
          }
        );
      } else {
        $metrics{"PROJECT_MLS_ACCESS"} = 1;
      }
    }
  }
  else {
    push(@{$check->{'results'}}, 'Failed: no forums defined.');
    push(
      @recs,
      {
        'rid'      => 'PMI_EMPTY_USER_ML',
        'severity' => 3,
        'desc' =>
          'The user mailing list URL is empty in the PMI. It helps people know where to ask questions if they want to use the product and should be filled.'
      }
    );
  }
  $ret_check->{'checks'}->{'forums'} = $check;

  # Test source_repos
  $check = {};
  $check->{'results'} = [];
  $check->{'desc'}
    = 'Checks if the Source repositories are filled and can be fetched using a simple get query.';
  my @src = @{$raw_project->{'source_repo'}};
  if (scalar @src > 0) {
    foreach my $ml (@src) {
      $url = $ml->{'url'};
      my $name = $ml->{'name'};
      my $path = $ml->{'path'};
      my $type = $ml->{'type'};
      $info{"PROJECT_SCM_URL"} = $url;
      $check->{'value'} = $url;
      if ($path =~ m!.+$!) {
        push(
          @{$check->{'results'}},
          "OK. Source repo [$name] type [$type] path [$path]."
        );
      }
      else {
        push(
          @{$check->{'results'}},
          "Failed. Source repo [$name] bad type [$type] or path [$path]."
        );
      }
      push(
        @{$check->{'results'}},
        &_check_url($ua, $url, "Source repo [$name]")
      );
      if ($check->{'results'}[-1] !~ /^OK/) {
        push(
          @recs,
          {
            'rid'      => 'PMI_NOK_SCM',
            'severity' => 3,
            'desc' =>
              'The source repository URL [$url] in the PMI cannot be retrieved. People need it if they want to contribute to the product, and it should be fixed.'
          }
        );
      } else {
        $metrics{"PROJECT_SCM_ACCESS"} = 1;
      }
    }
  }
  else {
    push(@{$check->{'results'}}, 'Failed. No source repo defined.');
    push(
      @recs,
      {
        'rid'      => 'PMI_EMPTY_SCM',
        'severity' => 3,
        'desc' =>
          "The source repository URL is empty in the PMI. People need it if they want to contribute to the product, and it should be filled."
      }
    );
  }
  $ret_check->{'checks'}->{'source_repo'} = $check;

  # Retrieve information about source repos
  my $pub_scm_info = 0;
  if (scalar @{$raw_project->{"source_repo"}} > 0) {
    $pub_scm_info++;
    if (defined($info{"PMI_SCM_URL"})) {
      $pub_scm_info++;
      if ($ua->head($info{"PMI_SCM_URL"})) {
        $pub_scm_info++;
      }
    }

  }
  $metrics{"PROJECT_SCM_INFO"} = $pub_scm_info;

  # Check update_sites info
  if (exists($raw_project->{'update_sites'}[0])) {
    $pub_access_info++;
  }

  # Test update_sites
  $check = {};
  $check->{'results'} = [];
  $check->{'desc'}
    = 'Checks if the update sites can be fetched using a simple get query.';
  my @ups = @{$raw_project->{'update_sites'}};
  if (scalar @ups > 0) {
    foreach my $us (@ups) {
      $url = $us->{'url'};
      my $title = $us->{'title'};
      $check->{'value'} = $url;
      $info{"PMI_UPDATESITE_URL"} = $url;
      if ($title =~ m!\S+!) {
        push(@{$check->{'results'}}, "OK. Update site [$title] has title.");
      }
      else {
        push(@{$check->{'results'}}, "Failed. Update site has no title.");
      }
      push(
        @{$check->{'results'}},
        &_check_url($ua, $url, "Update site [$title]")
      );
      if ($check->{'results'}[-1] !~ /^OK/) {
        push(
          @recs,
          {
            'rid'      => 'PMI_NOK_UPDATE',
            'severity' => 3,
            'desc' =>
              "The update site URL [$url] in the PMI cannot be retrieved. People need it if they want to use the product, and it should be fixed."
          }
        );
      }
    }
  }
  else {
    push(@{$check->{'results'}}, 'Failed. No update site defined.');
    push(
      @recs,
      {
        'rid'      => 'PMI_EMPTY_UPDATE',
        'severity' => 3,
        'desc' =>
          'The update site URL is empty in the PMI. People need it if they want to use the product, and it should be filled.'
      }
    );
  }
  $ret_check->{'checks'}->{'update_sites'} = $check;

  # Check build_doc info
  if (exists($raw_project->{'build_doc'}[0])) {
    $pub_doc_info++;
  }

  # Test CI
  my $proj_ci = $raw_project->{'build_url'}->[0]->{'url'} || '';
  $check              = {};
  $check->{'results'} = [];
  $check->{'value'}   = $proj_ci;
  $check->{'desc'}
    = "Sends a get request to the given CI URL and looks at the headers in the response (200, 404..). Also checks if the URL is really a Hudson instance (through a call to its API).";

  if ($proj_ci =~ m!\S+! && $ua->get($proj_ci)) {
    push(@{$check->{'results'}}, "OK. Fetched CI URL.");
    my $url = $proj_ci . '/api/json?depth=1';
    $info{"PROJECT_CI_URL"} = $proj_ci;
    $metrics{"PROJECT_CI_INFO"}++;
    my $json_str = $ua->get($url)->res->body;
    if ($json_str =~ m!^\s*{!) {
      my $content_tmp = decode_json($json_str);
      my $name        = $content_tmp->{'assignedLabels'}->[0]->{'name'};

      if (defined($name)) {
        push(
          @{$check->{'results'}},
          "OK. CI URL is a Hudson instance. Title is [$name]"
        );
        $metrics{"PROJECT_CI_ACCESS"}++;
      }
      else {
        push(
          @{$check->{'results'}},
          'Failed: CI URL is not the root of a Hudson instance.'
        );
        push(
          @recs,
          {
            'rid'      => 'PMI_NOK_CI',
            'severity' => 3,
            'desc' =>
              "The Hudson CI engine URL [$proj_ci] in the PMI is not detected as the root of a Hudson instance."
          }
        );
      }
    }
    else {
      push(@{$check->{'results'}}, "Failed: could not decode Hudson JSON.");
    }
  }
  else {
    push(@{$check->{'results'}}, "Failed: could not get CI URL [$proj_ci].");
    push(
      @recs,
      {
        'rid'      => 'PMI_EMPTY_CI',
        'severity' => 3,
        'desc'     => "The Hudson CI engine URL [$url] in the PMI is empty."
      }
    );
  }
  $ret_check->{'checks'}->{'build_url'} = $check;

  # Test releases
  $check              = {};
  $check->{'results'} = [];
  $check->{'desc'}    = 'Checks if the releases have been correctly filled.';
  if (exists($raw_project->{'releases'})) {
    my @rels = @{$raw_project->{'releases'}};
    $metrics{"PROJECT_REL_VOL"} = scalar @rels;

    if (scalar @rels > 0) {
      foreach my $rel (@rels) {
        my $title      = $rel->{'title'};
        my $dateval    = $rel->{'date'}->[0]->{'value'};
        my $date       = str2time($dateval);
        my $milestones = scalar @{$rel->{'milestones'}};
        my $review_state
          = $rel->{'review'}->{'state'}->[0]->{'value'} || 'none';
        my $rel_type = $rel->{'type'}->[0]->{'value'} || 1;
        if ($rel_type < 3 && $date < time()) {
          if ($review_state =~ m!success!) {
            push(
              @{$check->{'results'}},
              "OK. Review for [$title] is 'success'."
            );
          }
          else {
            push(
              @{$check->{'results'}},
              "Failed. Review for [$title] type [$rel_type] is [$review_state] on [$dateval]."
            );
          }
        }
      }
    }
    else {
      push(@{$check->{'results'}}, 'Failed. No release defined.');
      push(
        @recs,
        {
          'rid'      => 'PMI_EMPTY_REL',
          'severity' => 2,
          'desc' =>
            'There is no release defined in the PMI. Adding releases helps people evaluate the evolution and organisation of the project.'
        }
      );
    }
  }
  else {
    push(@{$check->{'results'}}, 'Failed. No release defined.');
    push(
      @recs,
      {
        'rid'      => 'PMI_EMPTY_REL',
        'severity' => 2,
        'desc' =>
          'There is no release defined in the PMI. Adding releases helps people evaluate the evolution and organisation of the project.'
      }
    );
  }
  $ret_check->{'checks'}->{'releases'} = $check;

  # Set metrics related to doc and access info
  $metrics{"PROJECT_DOC_INFO"}    = $pub_doc_info;
  $metrics{"PROJECT_ACCESS_INFO"} = $pub_access_info;


  # Write pmi checks json file to disk.
  push(@log,
    "[Plugins::EclipsePmi] Writing PMI checks json file to output dir.");
  $repofs->write_output($project_id, "pmi_checks.json",
    encode_json($ret_check));

  # Write pmi checks csv file to disk.
  push(@log,
    "[Plugins::EclipsePmi] Writing PMI checks csv file to output dir.");
  my $ret_check_csv = "Description,Value,Results\n";
  foreach my $l (sort keys %{$ret_check->{'checks'}}) {
    my $desc = $ret_check->{'checks'}{$l}{'desc'};
    $desc =~ s!,!!;
    my $value = $ret_check->{'checks'}{$l}{'value'} || '';
    $value =~ s!,!!;
    my $result = join("\\\\", @{$ret_check->{'checks'}{$l}{'results'}}) || '';
    $result =~ s!,!!;
    $ret_check_csv .= $desc . "," . $value . "," . $result . "\n";
  }
  $repofs->write_output($project_id, "pmi_checks.csv", $ret_check_csv);


  # Write pmi json file to disk.
  push(@log,
    "[Plugins::EclipsePmi] Writing updated PMI json file to output dir.");
  $repofs->write_output($project_id, "pmi.json", encode_json($raw_project));

  return {
    "info"    => \%info,
    "metrics" => \%metrics,
    "recs"    => \@recs,
    "log"     => \@log,
  };
}


sub _check_url($$$) {
  my $ua  = shift;
  my $url = shift || '';
  my $str = shift || '';

  my $fetch_result;
  if (defined($url) && $url =~ m!^http! && $ua->head($url)) {
    $fetch_result
      = "OK: $str <a href=\"$url\">URL</a> could be successfully fetched.";
  }
  else {
    $fetch_result = 'Failed: could not get $str URL [$url].';
  }
  return $fetch_result;
}


1;


=encoding utf8

=head1 NAME

B<Alambic::Plugins::EclipsePmi> - A plugin to fetch information from the
Eclipse PMI repository.

=head1 DESCRIPTION

B<Alambic::Plugins::EclipsePmi> retrieves information from the 
L<Eclipse PMI repository|https://wiki.eclipse.org/Project_Management_Infrastructure>.

Parameters:

=over

=item * Eclipse project ID - e.g. C<modeling.sirius> or C<tools.cdt>.

=back

For the complete configuration see the user documentation on the web site: L<https://alambic.io/Plugins/Pre/EclipsePmi.html>.

=head1 SEE ALSO

L<https://alambic.io/Plugins/Pre/EclipsePmi.html>, L<https://wiki.eclipse.org/Project_Management_Infrastructure>,

L<Mojolicious>, L<http://alambic.io>, L<https://bitbucket.org/BorisBaldassari/alambic>


=cut

