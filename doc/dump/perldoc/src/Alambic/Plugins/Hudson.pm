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

package Alambic::Plugins::Hudson;
use base 'Mojolicious::Plugin';

use strict;
use warnings;

use Alambic::Model::RepoFS;
use Alambic::Tools::R;

use Mojo::JSON qw( decode_json encode_json );
use Mojo::UserAgent;
use DateTime;
use Data::Dumper;
use Text::CSV;


# Main configuration hash for the plugin
my %conf = (
  "id"   => "Hudson",
  "name" => "Hudson CI",
  "desc" => [
    "Retrieves information from a Hudson continuous integration engine, displays a summary of its status, and provides recommendations to better use CI.",
    "Check the documentation for this plugin on the project web site: <a href=\"http://alambic.io/Plugins/Pre/Hudson.html\">http://alambic.io/Plugins/Pre/Hudson.html</a>."
  ],
  "type"    => "pre",
  "ability" => ['metrics', 'viz', 'figs', 'recs'],
  "params"  => {
    "hudson_url" =>
      "The base URL for the Hudson instance. In other words, the URL one would point to to get the main page of the project's Hudson, with the list of jobs.",
    "proxy" =>
      'If a proxy is required to access the remote resource of this plugin, please provide its URL here. A blank field means no proxy, and the <code>default</code> keyword uses the proxy from environment variables, see <a href="https://alambic.io/Documentation/Admin/Projects.html">the online documentation about proxies</a> for more details. Example: <code>https://user:pass@proxy.mycorp:3777</code>.',
  },
  "provides_info"    => [],
  "provides_metrics" => {
    "CI_JOBS"        => "CI_JOBS",
    "CI_JOBS_GREEN"  => "CI_JOBS_GREEN",
    "CI_JOBS_YELLOW" => "CI_JOBS_YELLOW",
    "CI_JOBS_RED"    => "CI_JOBS_RED",
    "CI_JOBS_FAILED_1W" =>
      "CI_JOBS_FAILED_1W",    # last build is failed for more than 1W
    "CI_JOBS_GREEN_RATIO" => "CI_JOBS_GREEN_RATIO",
  },
  "provides_data" => {},
  "provides_figs" => {
    'hudson_hist.html' => "History of Hudson builds (HTML)",
    'hudson_pie.html'  => "Pie of jobs statuses (HTML)",
  },
  "provides_recs" => ["CI_FAILING_JOBS",],
  "provides_viz"  => {"hudson.html" => "Hudson CI",},
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
sub run_plugin($$) {
  my ($self, $project_id, $conf) = @_;

  my %ret = ('metrics' => {}, 'info' => {}, 'recs' => [], 'log' => [],);

  # Create RepoFS object for writing and reading files on FS.
  my $repofs = Alambic::Model::RepoFS->new();

  my $hudson_url = $conf->{'hudson_url'};
  my $proxy_url = $conf->{'proxy'} || '';

  # Retrieve and store data from the remote repository.
  $ret{'log'} = &_retrieve_data($project_id, $hudson_url, $proxy_url, $repofs);

  # Analyse retrieved data, generate info, metrics, plots and visualisation.
  my $tmp_ret = &_compute_data($project_id, $hudson_url, $repofs);

  $ret{'metrics'} = $tmp_ret->{'metrics'};
  $ret{'recs'}    = $tmp_ret->{'recs'};
  push(@{$ret{'log'}}, @{$tmp_ret->{'log'}});

  return \%ret;
}

sub _retrieve_data($) {
  my $project_id = shift;
  my $hudson_url = shift;
  my $proxy_url  = shift;
  my $repofs     = shift;

  my $hudson;
  my @log;

  my $url = $hudson_url . "/api/json?depth=2";
  push(@log,
    "[Plugins::Hudson] Starting retrieval of data for [$project_id] url [$url]."
  );

  # Fetch json file from the dashboard.eclipse.org
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
      "[Plugins::Hudson] Using default proxy [$proxy_http] and [$proxy_https]."
    );
  }
  elsif ($proxy_url =~ m!\S+!) {

    # If something, then use it
    $ua->proxy->http($proxy_url)->https($proxy_url);
    push(@log, "[Plugins::Hudson] Using provided proxy [$proxy_url].");
  }
  else {
    # If blank, then use no proxy
    push(@log, "[Plugins::Hudson] No proxy defined [$proxy_url].");
  }

  my $json = $ua->get($url)->res->body;
  if (length($json) < 10) {
    push(@log, "[Plugins::Hudson] Cannot find [$url].\n");
  }
  else {
    $repofs->write_input($project_id, "import_hudson.json", $json);
  }

  return \@log;
}

sub _compute_data($) {
  my $project_id = shift;
  my $hudson_url = shift;
  my $repofs     = shift;

  my @log;
  my %metrics;
  my @recs;

  push(@log, "[Plugins::Hudson] Starting compute data for [$project_id].");

  # Read data from file in $data_input
  my $json = $repofs->read_input($project_id, "import_hudson.json");
  my $hudson = decode_json($json);

  $metrics{'CI_JOBS'}           = scalar @{$hudson->{'jobs'}};
  $metrics{'CI_JOBS_GREEN'}     = 0;
  $metrics{'CI_JOBS_YELLOW'}    = 0;
  $metrics{'CI_JOBS_RED'}       = 0;
  $metrics{'CI_JOBS_FAILED_1W'} = 0;

  # Find the date for one week ago
  my $date_now   = DateTime->now();
  my $date_1w    = DateTime->now()->subtract(days => 7);
  my $date_1w_ms = $date_1w->epoch() * 1000;

  foreach my $job (@{$hudson->{'jobs'}}) {
    if ($job->{'color'} =~ m!green!) {
      $metrics{'CI_JOBS_GREEN'}++;
    }
    elsif ($job->{'color'} =~ m!yellow!) {
      $metrics{'CI_JOBS_YELLOW'}++;
    }
    elsif ($job->{'color'} =~ m!red!) {
      $metrics{'CI_JOBS_RED'}++;
    }

    my $job_last_success = $job->{'lastSuccessfulBuild'}{'timestamp'} || 0;

    # If last successful build is more than 1W old, count it.
    if ($job_last_success < $date_1w_ms && $job->{'color'} =~ m!red!) {
      $metrics{'CI_JOBS_FAILED_1W'}++;
      my $rec = {
        "rid"      => "CI_FAILING_JOBS",
        "severity" => 3,
        "desc"     => "Job "
          . $job->{'name'}
          . " has been failing for more than 1 week. You should either disable it if it's not relevant anymore, or fix it.",
      };
      push(@recs, $rec);
    }
  }
  my $total
    = $metrics{'CI_JOBS_GREEN'}
    + $metrics{'CI_JOBS_YELLOW'}
    + $metrics{'CI_JOBS_RED'};
  $metrics{'CI_JOBS_GREEN_RATIO'}
    = int(100 * $metrics{'CI_JOBS_GREEN'} / $total);

  # Prepare the Text::CSV module.
  my $csv
    = Text::CSV->new(
    {sep_char => ',', binary => 1, quote_char => '"', auto_diag => 1}
    )    # should set binary attribute.
    or die "Cannot use CSV: " . Text::CSV->error_diag();

  # Write metrics json file to disk.
  $repofs->write_output($project_id, "metrics_hudson.json",
    encode_json(\%metrics));

  # Write csv file for metrics
  my @metrics_csv = sort map { $conf{'provides_metrics'}{$_} }
    keys %{$conf{'provides_metrics'}};
  my $csv_out = join(',', sort @metrics_csv) . "\n";
  $csv->combine(map { $metrics{$_} } sort @metrics_csv);
  $csv_out .= $csv->string() . "\n";

  $repofs->write_plugin('Hudson', $project_id . "_hudson_metrics.csv",
    $csv_out);

  # Write csv file for main information about hudson instance
  @metrics_csv = ('name', 'desc', 'jobs', 'url');
  $csv_out = join(',', @metrics_csv) . "\n";
  $csv->combine(
    (
      $hudson->{'nodeName'}, $hudson->{'nodeDescription'},
      $metrics{'CI_JOBS'},   $hudson_url
    )
  );
  $csv_out .= $csv->string() . "\n";

  $repofs->write_plugin('Hudson', $project_id . "_hudson_main.csv", $csv_out);

  # Write csv file for jobs
  my @jobs_metrics = (
    'name',                       'buildable',
    'color',                      'last_build',
    'last_build_time',            'last_build_duration',
    'last_failed_build',          'last_failed_build_time',
    'last_failed_build_duration', 'last_successful_build',
    'last_successful_build_time', 'last_successful_build_duration',
    'next_build_number',          'health_report',
    'url'
  );
  $csv_out = join(',', @jobs_metrics) . "\n";
  my $sep = ',';

  my @builds_metrics
    = ('time', 'name', 'result', 'id', 'number', 'duration', 'url');
  my $csv_out_builds = join(',', @builds_metrics) . "\n";

  foreach my $job (@{$hudson->{'jobs'}}) {
    my $name         = $job->{'name'};
    my $lb_id        = $job->{'lastBuild'}->{'number'} || 0;
    my $lb_time      = $job->{'lastBuild'}->{'timestamp'} || 0;
    my $lb_duration  = $job->{'lastBuild'}->{'duration'} || 0;
    my $lfb_id       = $job->{'lastFailedBuild'}->{'number'} || 0;
    my $lfb_time     = $job->{'lastFailedBuild'}->{'timestamp'} || 0;
    my $lfb_duration = $job->{'lastFailedBuild'}->{'duration'} || 0;
    my $lsb_id       = $job->{'lastSuccessfulBuild'}->{'number'} || 0;
    my $lsb_time     = $job->{'lastSuccessfulBuild'}->{'timestamp'} || 0;
    my $lsb_duration = $job->{'lastSuccessfulBuild'}->{'duration'} || 0;
    my $hr_score     = $job->{'healthReport'}[0]{'score'} || 0;
    $csv_out
      .= $name
      . $sep
      . $job->{'buildable'}
      . $sep
      . $job->{'color'}
      . $sep
      . $lb_id
      . $sep
      . $lb_time
      . $sep
      . $lb_duration
      . $sep
      . $lfb_id
      . $sep
      . $lfb_time
      . $sep
      . $lfb_duration
      . $sep
      . $lsb_id
      . $sep
      . $lsb_time
      . $sep
      . $lsb_duration
      . $sep
      . $job->{'nextBuildNumber'}
      . $sep
      . $hr_score
      . $sep
      . $job->{'url'} . "\n";

    # Now read all builds.
    foreach my $build (@{$job->{'builds'}}) {
      my $time     = $build->{'timestamp'};
      my $name     = $build->{'fullDisplayName'};
      my $result   = $build->{'result'} || 'UNKNOWN';
      my $id       = $build->{'id'};
      my $number   = $build->{'number'};
      my $duration = $build->{'duration'};
      my $url      = $build->{'url'};

      $csv_out_builds
        .= $time
        . $sep
        . $name
        . $sep
        . $result
        . $sep
        . $id
        . $sep
        . $number
        . $sep
        . $duration
        . $sep . '"'
        . $url . "\"\n";
    }
  }

  # Write jobs csv file
  $repofs->write_plugin('Hudson', $project_id . "_hudson_jobs.csv", $csv_out);

  # Write builds csv file
  $repofs->write_plugin('Hudson', $project_id . "_hudson_builds.csv",
    $csv_out_builds);

  # Now execute the main R script.
  push(@log, "[Plugins::Hudson] Executing R main file.");
  my $r = Alambic::Tools::R->new();
  @log = (@log, @{$r->knit_rmarkdown_inc('Hudson', $project_id, 'hudson.Rmd')});

  # And execute the figures R scripts.
  my @figs = ('hudson_hist.rmd', 'hudson_pie.rmd');
  foreach my $fig (sort @figs) {
    push(@log, "[Plugins::Hudson] Executing R fig file [$fig].");
    @log = (@log, @{$r->knit_rmarkdown_html('Hudson', $project_id, $fig)});
  }

  return {"metrics" => \%metrics, "recs" => \@recs, "log" => \@log,};
}


1;


=encoding utf8

=head1 NAME

B<Alambic::Plugins::Hudson> - A plugin to fetch information from a Hudson
Continuous Integration server.

=head1 DESCRIPTION

B<Alambic::Plugins::Hudson> retrieves information from a Hudson instance.

Parameters:

=over

=item * Hudson URL A link to the root of the project's Hudson instance.

=back

For the complete configuration see the user documentation on the web site: L<https://alambic.io/Plugins/Pre/Hudson.html>.

=head1 SEE ALSO

L<https://alambic.io/Plugins/Pre/Hudson.html>, L<https://hudson.eclipse.org>,

L<Mojolicious>, L<http://alambic.io>, L<https://bitbucket.org/BorisBaldassari/alambic>


=cut

