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

package Alambic::Plugins::StackOverflow;

use strict;
use warnings;

use Alambic::Model::RepoFS;
use Alambic::Tools::R;

use Mojo::JSON qw( decode_json encode_json );
use Mojo::UserAgent;
use Data::Dumper;
use File::Copy;
use File::Path qw(remove_tree);
use DateTime;

my %conf = (
  "id"   => "StackOverflow",
  "name" => "Stack Overflow",
  "desc" => [
    "Retrieves questions and answers related to a specific tag from the Stack Overflow question/answer web site.",
    "The analysed time range spans the last 5 years.",
    "Check the documentation for this plugin on the project web site: <a href=\"http://alambic.io/Plugins/Pre/StackOverflow.html\">http://alambic.io/Plugins/Pre/StackOverflow.html</a>."
  ],
  "type"    => "pre",
  "ability" => ['data', 'figs', 'metrics', 'recs', 'viz', 'users'],
  "params"  => {
    "so_keyword" => "A Stack Overflow tag to retrieve questions from.",
    "proxy" =>
      'If a proxy is required to access the remote resource of this plugin, please provide its URL here. A blank field means no proxy, and the <code>default</code> keyword uses the proxy from environment variables, see <a href="https://alambic.io/Documentation/Admin/Projects.html">the online documentation about proxies</a> for more details. Example:  <code>https://user:pass@proxy.mycorp:3777</code>.',
  },
  "provides_cdata" => [],
  "provides_info"  => [],
  "provides_data"  => {
    "so.json" =>
      "The list of questions and answers for the project, in JSON format.",
    "so.csv" =>
      "The list of questions and answers for the project, in CSV format.",
  },
  "provides_metrics" => {
    "SO_QUESTIONS_VOL_5Y" => "SO_QUESTIONS_VOL_5Y",
    "SO_ANSWERS_VOL_5Y"   => "SO_ANSWERS_VOL_5Y",
    "SO_ANSWER_RATE_1Y"   => "SO_ANSWER_RATE_1Y",
    "SO_ANSWER_RATE_5Y"   => "SO_ANSWER_RATE_5Y",
    "SO_VOTES_VOL_5Y"     => "SO_VOTES_VOL_5Y",
    "SO_VIEWS_VOL_5Y"     => "SO_VIEWS_VOL_5Y",
    "SO_ASKERS_5Y"        => "SO_ASKERS_5Y",
  },
  "provides_figs" => {
    "so_evolution.svg" => "Evolution of questions on SO (SVG).",
    "so_plot.svg"      => "Summary of questions on SO (SVG).",
    "so_tm.svg"        => "Main words used on SO (SVG).",
  },
  "provides_recs" => ["SO_ANSWER_RATE_LOW",],
  "provides_viz"  => {"stack_overflow.html" => "Stack Overflow",},
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

  my $so_keyword = $conf->{'so_keyword'};
  my $proxy_url = $conf->{'proxy'} || '';

  # Retrieve and store data from the remote repository.
  $ret{'log'} = &_retrieve_data($project_id, $so_keyword, $proxy_url, $repofs);

  # Analyse retrieved data, generate info, metrics, plots and visualisation.
  my $tmp_ret = &_compute_data($project_id, $so_keyword, $repofs);

  $ret{'metrics'} = $tmp_ret->{'metrics'};
  $ret{'recs'}    = $tmp_ret->{'recs'};
  push(@{$ret{'log'}}, @{$tmp_ret->{'log'}});

  return \%ret;
}


sub _retrieve_data() {
  my ($project_id, $so_keyword, $proxy_url, $repofs) = @_;

  my @log;

  # URL for SO API access.
  my $url = 'https://api.stackexchange.com/2.2/';

  # Compute date for the time range (5 years)
  my $date_now = DateTime->now(time_zone => 'local');
  my $date_before = DateTime->now(time_zone => 'local')->subtract(years => 5);
  my $date_before_ok = $date_before->strftime("%Y-%m-%d");

  my $content_json;
  my %final_json;

  my ($quota_max, $quota_remaining);

  my $continue = 50;
  my $page     = 1;

  # Fetch JSON data from SO
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
      "[Plugins::StackOverflow] Using default proxy [$proxy_http] and [$proxy_https]."
    );
  }
  elsif ($proxy_url =~ m!\S+!) {
   # If something, then use it
    $ua->proxy->http($proxy_url)->https($proxy_url);
    push(@log, "[Plugins::StackOverflow] Using provided proxy [$proxy_url].");
  }
  else {
    # If blank, then use no proxy
    push(@log, "[Plugins::StackOverflow] No proxy defined [$proxy_url].");
  }

  # Read pages (100 items per page) from the SO API.
  while ($continue) {
    my $url_question
      = $url
      . "questions?order=desc&sort=activity&site=stackoverflow"
      . "&tagged="
      . $so_keyword
      . "&fromdate=${date_before_ok}"
      . "&pagesize=100&page="
      . $page;

    push(@log, "[Plugins::StackOverflow] Fetching $url_question.");

    # Get the resource
    $content_json = $ua->get($url_question)->res->body;

    # Decode the json we got and add items to our set.
    if (length($content_json) < 10) {
      push(@log, "[Plugins::StackOverflow] Cannot find [$url_question].");
      return ["[Plugins::StackOverflow] Cannot find [$url_question]."];
    }
    my $content = decode_json($content_json);

    foreach my $item (@{$content->{'items'}}) {
      $final_json{'items'}{$item->{'question_id'}} = $item;
    }

    $page++;

    # Check if there are other pages.
    if ($content->{'has_more'}) {
      $continue--;
    }
    else {
      $continue = 0;
    }

    $quota_max       = $content->{'quota_max'};
    $quota_remaining = $content->{'quota_remaining'};
  }
  my @items = keys %{$final_json{'items'}};
  push(@log,
        "[Plugins::StackOverflow] Fetched data from SO. Got "
      . scalar @items
      . " items.");

  my $json_out = encode_json(\%final_json);

  push(@log, "[Plugins::StackOverflow] Writing questions to JSON file.");
  $repofs->write_input($project_id, "import_so.json", $json_out);
  $repofs->write_output($project_id, "so.json", $json_out);

  push(@log,
    "[Plugins::StackOverflow] Quota: remaining $quota_remaining out of $quota_max."
  );

  return \@log;
}

sub _compute_data() {
  my ($project_id, $so_keyword, $repofs) = @_;

  my %metrics;
  my @recs;
  my @log;

  push(@log,
    "[Plugins::StackOverflow] Starting compute data for [$project_id].");

  # Compute dates to limit time range.
  my $date_now = DateTime->now(time_zone => 'local');
  my $date_1y = DateTime->now(time_zone => 'local')->subtract(years => 1); 
print "1Y" . Dumper($date_1y);
  my $date_5y = DateTime->now(time_zone => 'local')->subtract(years => 5);
  my $date_5y_ok = $date_5y->strftime("%Y-%m-%d");

  # Read file retrieved from repo and decode json.
  my $content_json = $repofs->read_input($project_id, "import_so.json");
  my $content = decode_json($content_json);

  my ($questions, $questions_1y, $answers, $answers_1y, $views, $votes) = (0, 0, 0, 0, 0, 0);
  my %people;

  # Produce a CSV file with all information. Easier to read in R.
  my $csv_out
    = "id,views,score,creation_date,last_activity_date,answer_count,is_answered,title\n";
  foreach my $id (sort keys %{$content->{'items'}}) {
    $questions++;
    my $views_count = $content->{'items'}->{$id}->{'view_count'};
    $views += $views_count;
    my $score = $content->{'items'}->{$id}->{'score'};
    $votes += $score;
    my $creation_date      = $content->{'items'}->{$id}->{'creation_date'};
    my $last_activity_date = $content->{'items'}->{$id}->{'last_activity_date'};
    my $answer_count       = $content->{'items'}->{$id}->{'answer_count'};
    $answers += $answer_count;

    # Manage *_1Y metrics
    if ( DateTime->from_epoch( epoch => $creation_date) > $date_1y ) {
      $answers_1y += $answer_count;
      $questions_1y++;
    }

    my $is_answered = $content->{'items'}->{$id}->{'is_answered'};
    my $title       = $content->{'items'}->{$id}->{'title'};
    $title =~ s!,!!g;

    my $user
      = $content->{'items'}->{$id}->{'owner'}{'user_id'} || 'does_not_exist';
    $people{$user}++;

    $csv_out
      .= "$id,$views_count,$score,$creation_date,$last_activity_date,$answer_count,$is_answered,$title\n";
  }

  # Write that to csv in plugins folder (for R treatment) and output (for download).
  $repofs->write_plugin('StackOverflow', $project_id . "_so.csv", $csv_out);
  $repofs->write_output($project_id, "so.csv", $csv_out);

  # Compute metrics
  $metrics{'SO_QUESTIONS_VOL_5Y'} = $questions;
  $metrics{'SO_ANSWERS_VOL_5Y'}   = $answers;
  $metrics{'SO_ANSWER_RATE_1Y'}   = sprintf("%.2f", ($answers_1y / $questions_1y));
  $metrics{'SO_ANSWER_RATE_5Y'}   = sprintf("%.2f", ($answers / $questions));
  $metrics{'SO_VOTES_VOL_5Y'}     = $votes;
  $metrics{'SO_VIEWS_VOL_5Y'}     = $views;
  $metrics{'SO_ASKERS_5Y'}        = scalar keys %people;

  if ($metrics{'SO_ANSWER_RATE_5Y'} < 0.7) {
    push(
      @recs,
      {
        'rid'      => 'SO_ANSWER_RATE_LOW',
        'severity' => 1,
        'src'      => 'StackOverflow',
        'desc' => 'The average number of answers per question is quite low ('
          . $metrics{'SO_ANSWER_RATE_5Y'}
          . '). It is important to answer '
          . 'to people to show support and make them progress on the project.'
      }
    );

  }

  # Prepare hash of parameters for R exection.
  my %params = (
    "project.tag" => $so_keyword,
    "date.now"    => $date_now,
    "date.before" => $date_5y_ok,
  );

  # Now execute the main R script.
  push(@log, "[Plugins::StackOverflow] Executing R main file.");
  my $r = Alambic::Tools::R->new();
  @log = (
    @log,
    @{
      $r->knit_rmarkdown_inc('StackOverflow', $project_id,
        'stack_overflow.Rmd', [], \%params)
    }
  );

  # And execute r scripts for images
  my @files_r = ('so_evolution', 'so_plot', 'so_tm');
  foreach my $file_r (@files_r) {
    @log = (
      @log,
      @{
        $r->knit_rmarkdown_images(
          'StackOverflow', $project_id,
          $file_r . '.r',
          [$file_r . '.svg']
        )
      }
    );
  }

  return {"metrics" => \%metrics, "recs" => \@recs, "log" => \@log,};
}

1;


=encoding utf8

=head1 NAME

B<Alambic::Plugins::StackOverflow> - A plugin to fetch information from the
Stack Overflow question/answer web site.

=head1 DESCRIPTION

B<Alambic::Plugins::StackOverflow> retrieves information from the questions 
asked about the project on the Stack Overflow question/answer web site.

Parameters:

=over

=item * StackOverflow tag - e.g. C<eclipse-sirius> or C<eclipse-cdt>.

=back

For the complete configuration see the user documentation on the web site: L<https://alambic.io/Plugins/Pre/StackOverflow.html>.

=head1 SEE ALSO

L<https://alambic.io/Plugins/Pre/StackOverflow.html>, L<https://stackoverflow.com>,

L<Mojolicious>, L<http://alambic.io>, L<https://bitbucket.org/BorisBaldassari/alambic>


=cut
