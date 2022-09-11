#########################################################
#
# Copyright (c) 2015-2017 Castalia Solutions and Thales Group.
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

package Alambic::Plugins::JiraIts;

use strict;
use warnings;

use Alambic::Model::RepoFS;
use Alambic::Tools::R;

use Mojo::JSON qw( decode_json encode_json );
use Date::Parse;
use JIRA::REST;
use Time::Piece;
use Time::Seconds;
use Text::CSV;
use Data::Dumper;

# Main configuration hash for the plugin
my %conf = (
  "id"   => "JiraIts",
  "name" => "Jira",
  "desc" => [
    'The Jira plugin retrieves issue information from an Atlassian Jira server, using the <a href="https://developer.atlassian.com/jiradev/jira-apis/jira-rest-apis">Jira REST API</a>.',
    'See <a href="https://alambic.io/Plugins/Pre/Jira">the project\'s wiki</a> for more information.',
  ],
  "type"    => "pre",
  "ability" => ['info', 'metrics', 'data', 'figs', 'recs', 'viz', 'users'],
  "params"  => {
    "jira_url"     => "The URL of the Jira server, e.g. http://myserver.",
    "jira_user"    => "The user for authentication on the Jira server.",
    "jira_passwd"  => "The password for authentication on the Jira server.",
    "jira_project" => "The project ID to be requested on the Jira server.",
    "jira_open_states" =>
      "The states names considered to be open, as a coma-separated list.",
    "proxy" =>
      'If a proxy is required to access the remote resource of this plugin, please provide its URL here. A blank field means no proxy, and the <code>default</code> keyword uses the proxy from environment variables, see <a href="https://alambic.io/Documentation/Admin/Projects.html">the online documentation about proxies</a> for more details. Example: <code>https://user:pass@proxy.mycorp:3777</code>.',
  },
  "provides_cdata" => [],
  "provides_info"  => ["JIRA_URL",],
  "provides_data"  => {
    "import_jira.json" =>
      "The original file of current information, downloaded from the Jira server (JSON).",
    "jira_evol.csv" =>
      "The evolution of issues created and authors by day (CSV).",
    "jira_issues.csv" =>
      "The list of issues, with fields 'id, summary, status, assignee, reporter, due_date, created_at, updated_at' (CSV).",
    "jira_issues_late.csv" =>
      "The list of late issues (i.e. their due_date has past), with fields 'id, summary, status, assignee, reporter, due_date, created_at, updated_at' (CSV).",
    "jira_issues_open.csv" =>
      "The list of open issues, with fields 'id, summary, status, assignee, reporter, due_date, created_at, updated_at' (CSV).",
    "jira_issues_open_unassigned.csv" =>
      "The list of open and unassigned issues, with fields 'id, summary, status, assignee, reporter, due_date, created_at, updated_at' (CSV).",
    "jira_issues_open_old.csv" =>
      "The list of open and old (i.e. not updated since more than one year) issues, with fields 'id, summary, status, assignee, reporter, due_date, created_at, updated_at' (CSV).",
  },
  "provides_metrics" => {
    "ITS_ISSUES_ALL"             => "ITS_ISSUES_ALL",
    "ITS_AUTHORS"         => "ITS_AUTHORS",
    "ITS_AUTHORS_1W"      => "ITS_AUTHORS_1W",
    "ITS_AUTHORS_1M"      => "ITS_AUTHORS_1M",
    "ITS_AUTHORS_1Y"      => "ITS_AUTHORS_1Y",
    "ITS_CREATED_1W"      => "ITS_CREATED_1W",
    "ITS_CREATED_1M"      => "ITS_CREATED_1M",
    "ITS_CREATED_1Y"      => "ITS_CREATED_1Y",
    "ITS_UPDATED_1W"      => "ITS_UPDATED_1W",
    "ITS_UPDATED_1M"      => "ITS_UPDATED_1M",
    "ITS_UPDATED_1Y"      => "ITS_UPDATED_1Y",
    "ITS_OPEN"            => "ITS_OPEN",
    "ITS_OPEN_OLD"        => "ITS_OPEN_OLD",
    "ITS_OPEN_PERCENT"    => "ITS_OPEN_PERCENT",
    "ITS_LATE"            => "ITS_LATE",
    "ITS_OPEN_UNASSIGNED" => "ITS_OPEN_UNASSIGNED",
  },
  "provides_figs" => {
    'jira_summary.html' => "HTML summary of Jira issues main metrics (HTML)",
    'jira_evol_summary.html' => "Evolution of Jira main metrics (HTML)",
    'jira_evol_created.html' => "Evolution of Jira issues creation (HTML)",
    'jira_evol_authors.html' => "Evolution of Jira issues authors (HTML)",
  },
  "provides_recs" => ["JIRA_LATE_ISSUES",],
  "provides_viz"  => {"jira_its.html" => "Jira ITS",},
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

  # Time::Piece object. Will be used for the date calculations.
  my $t_now = localtime;
  my $t_1w  = $t_now - ONE_WEEK;
  my $t_1m  = $t_now - ONE_MONTH;
  my $t_1y  = $t_now - ONE_YEAR;

  my $jira_url         = $conf->{'jira_url'};
  my $jira_open_states = $conf->{'jira_open_states'};
  my @j_status_open    = split(',', $jira_open_states);

  my $jira_user    = $conf->{'jira_user'};
  my $jira_passwd  = $conf->{'jira_passwd'};
  my $jira_project = $conf->{'jira_project'};
  my $proxy_url    = $conf->{'proxy'} || '';

  my $jira_conf
    = {url => $jira_url, username => $jira_user, password => $jira_passwd,};

  # Configure Proxy
  if ($proxy_url =~ m!^default!i) {

    # If 'default', then use detect
    foreach my $v (('https_proxy', 'HTTPS_PROXY', 'http_proxy', 'HTTP_PROXY')) {
      if (defined($ENV{$v})) {
        $jira_conf->{'proxy'} = $ENV{$v};
        push(
          @{$ret{'log'}},
          "[Plugins::JiraIts] Using default proxy ["
            . $jira_conf->{'proxy'} . "]."
        );
        last;
      }
    }
  }
  elsif ($proxy_url =~ m!\S+$!) {

    # If something, then use it
    $jira_conf->{'proxy'} = $proxy_url;
    push(
      @{$ret{'log'}},
      "[Plugins::JiraIts] Using provided proxy [$proxy_url]."
    );
  }
  else {
    # If blank, then use no proxy
    push(@{$ret{'log'}}, "[Plugins::JiraIts] No proxy defined [$proxy_url].");
  }

  my $jira = JIRA::REST->new($jira_conf);

  $ret{'info'}{'JIRA_URL'} = $jira_url . "/projects/" . $jira_project . "/";


  # Iterate on issues
  push(
    @{$ret{'log'}},
    "[Plugins::JiraIts] Retrieving information from [$jira_url]."
  );
  my $search = $jira->POST(
    '/search',
    undef,
    {
      jql        => 'project=' . $jira_project,
      startAt    => 0,
      maxResults => 10000,
      fields     => [
        qw/summary status assignee reporter created updated duedate priority votes watches issuetype/
      ],
    }
  );

  # Write json file to import directory
  $repofs->write_input($project_id, "import_jira.json",
    encode_json($search->{'issues'}));

  my (@late, @open, @open_unassigned, @open_old, %people);
  my $csv_out
    = "id,summary,type,status,priority,assignee,reporter,due_date,created_at,updated_at,votes,watches\n";
  my $csv_late_out            = $csv_out;
  my $csv_open_out            = $csv_out;
  my $csv_open_unassigned_out = $csv_out;
  my $csv_open_old_out = $csv_out;

  my ($jira_created_1w, $jira_created_1m, $jira_created_1y) = (0, 0, 0);
  my ($jira_updated_1w, $jira_updated_1m, $jira_updated_1y) = (0, 0, 0);
  my (%authors, %authors_1w, %authors_1m, %authors_1y, %users);
  my %timeline_c;
  my %timeline_a;

  my $csv                 = Text::CSV->new({binary => 1, eol => "\n"});
  my $csv_late            = Text::CSV->new({binary => 1, eol => "\n"});
  my $csv_open            = Text::CSV->new({binary => 1, eol => "\n"});
  my $csv_open_unassigned = Text::CSV->new({binary => 1, eol => "\n"});
  my $csv_open_old = Text::CSV->new({binary => 1, eol => "\n"});

  foreach my $issue (@{$search->{'issues'}}) {
    my @attrs;

    my $date
      = Time::Piece->strptime(int(str2time($issue->{'fields'}{'created'}) || 0),
      "%s");
    my $date_m = $date->strftime("%Y-%m-%d");
    my $name = $issue->{'fields'}{'reporter'}{'name'} || '';
    $timeline_c{$date_m}++;
    $timeline_a{$date_m}{$name}++;
    $authors{$name}++;

    @attrs = (
      $issue->{'key'},
      $issue->{'fields'}{'summary'},
      $issue->{'fields'}{'issuetype'}{'name'},
      $issue->{'fields'}{'status'}{'name'},
      $issue->{'fields'}{'priority'}{'name'},
      $issue->{'fields'}{'assignee'}{'name'},
      $issue->{'fields'}{'reporter'}{'name'},
      $issue->{'fields'}{'duedate'},
      $issue->{'fields'}{'created'},
      $issue->{'fields'}{'updated'},
      $issue->{'fields'}{'votes'}{'votes'},
      $issue->{'fields'}{'watches'}{'watchCount'}
    );
    $csv->combine(@attrs);
    $csv_out .= $csv->string();

    if (grep(/$issue->{'fields'}{'status'}{'name'}/, @j_status_open) != 0) {
      push(@open, $issue->{'key'});
      $csv_open_out .= $csv->string();
    }

    # Convert string dates to epoch seconds
    my $date_due = str2time($issue->{'fields'}{'duedate'})
      if defined($issue->{'fields'}{'duedate'});
    my $date_created = str2time($issue->{'fields'}{'created'})
      if defined($issue->{'fields'}{'created'});
    my $date_updated = str2time($issue->{'fields'}{'updated'})
      if defined($issue->{'fields'}{'updated'});
    my $t_now = time();

    # Check if issue's due date has past
    if (defined($date_due) and $date_due < $t_now) {
      push(@late, $issue->{'key'});
      $csv_late_out .= $csv->string();
    }

    # Check if issue is assigned and open
    if ((not defined($issue->{'fields'}{'assignee'}{'name'}))
      && grep(/$issue->{'fields'}{'status'}{'name'}/, @j_status_open) != 0)
    {
      push(@open_unassigned, $issue->{'key'});
      $csv_open_unassigned_out .= $csv->string();
    }

    # Check if issue is old (not been updated for more than 1y) and open
    if (($date_updated < $t_1y->epoch)
      && grep(/$issue->{'fields'}{'status'}{'name'}/, @j_status_open) != 0)
    {
      push(@open_old, $issue->{'key'});
      $csv_open_old_out .= $csv->string();
    }

    # Populate %users to show activity in the user's profile
    if (exists $issue->{'fields'}{'assignee'}{'emailAddress'}) {
      my $event = {
        "type" => "issue_assigned",
        "id"   => $issue->{'key'},
        "msg"  => $issue->{'fields'}{'summary'},
        "url"  => $issue->{'self'}
      };
      push(@{$people{$issue->{'fields'}{'assignee'}{'emailAddress'}}}, $event);
    }

    # Populate %users to show activity in the user's profile
    if (exists $issue->{'fields'}{'reporter'}{'emailAddress'}) {
      my $event = {
        "type" => "issue_created",
        "id"   => $issue->{'key'},
        "msg"  => $issue->{'fields'}{'summary'},
        "url"  => $issue->{'self'},
        "time" => $issue->{'created'}
      };
      push(@{$people{$issue->{'fields'}{'reporter'}{'emailAddress'}}}, $event);
    }

    # Is the issue recent (<1W)?
    if ($date_created > $t_1w->epoch) {
      $authors_1w{$issue->{'fields'}{'reporter'}{'name'}}++;
      $jira_created_1w++;
    }

    # Is the issue recent (<1M)?
    if ($date_created > $t_1m->epoch) {
      $authors_1m{$issue->{'fields'}{'reporter'}{'name'}}++;
      $jira_created_1m++;
    }

    # Is the issue recent (<1Y)?
    if ($date_created > $t_1y->epoch) {
      $authors_1y{$issue->{'fields'}{'reporter'}{'name'}}++;
      $jira_created_1y++;
    }

    # Has the issue been closed recently (<1W)?
    if ($date_updated > $t_1w->epoch) {
      $jira_updated_1w++;
    }

    # Has the issue been closed recently (<1M)?
    if ($date_updated > $t_1m->epoch) {
      $jira_updated_1m++;
    }

    # Has the issue been closed recently (<1Y)?
    if ($date_updated > $t_1y->epoch) {
      $jira_updated_1y++;
    }
  }

  # Write metrics to csv and json files.
  $repofs->write_output($project_id, "jira_issues.csv",      $csv_out);
  $repofs->write_output($project_id, "jira_issues_late.csv", $csv_late_out);
  $repofs->write_output($project_id, "jira_issues_open.csv", $csv_open_out);
  $repofs->write_output($project_id, "jira_issues_open_unassigned.csv",
    $csv_open_unassigned_out);
  $repofs->write_output($project_id, "jira_issues_open_old.csv",
    $csv_open_old_out);

  # Compute and store metrics
  $ret{'metrics'}{'ITS_ISSUES_ALL'}     = scalar @{$search->{'issues'}};
  $ret{'metrics'}{'ITS_OPEN'}    = scalar @open;
  $ret{'metrics'}{'ITS_OPEN_PERCENT'}
    = sprintf("%.0f", 100 * (scalar @open) / (scalar @{$search->{'issues'}}));
  $ret{'metrics'}{'ITS_LATE'}            = scalar @late            || 0;
  $ret{'metrics'}{'ITS_OPEN_UNASSIGNED'} = scalar @open_unassigned || 0;
  $ret{'metrics'}{'ITS_OPEN_OLD'}        = scalar @open_old || 0;
  $ret{'metrics'}{'ITS_AUTHORS'} = scalar keys %authors;
  $ret{'metrics'}{'ITS_AUTHORS_1W'}      = scalar keys %authors_1w || 0;
  $ret{'metrics'}{'ITS_AUTHORS_1M'}      = scalar keys %authors_1m || 0;
  $ret{'metrics'}{'ITS_AUTHORS_1Y'}      = scalar keys %authors_1y || 0;
  $ret{'metrics'}{'ITS_CREATED_1W'}      = $jira_created_1w;
  $ret{'metrics'}{'ITS_CREATED_1M'}      = $jira_created_1m;
  $ret{'metrics'}{'ITS_CREATED_1Y'}      = $jira_created_1y;
  $ret{'metrics'}{'ITS_UPDATED_1W'}      = $jira_updated_1w;
  $ret{'metrics'}{'ITS_UPDATED_1M'}      = $jira_updated_1m;
  $ret{'metrics'}{'ITS_UPDATED_1Y'}      = $jira_updated_1y;

  # Set user information for profile
  push(@{$ret{'log'}}, "[Plugins::JiraIts] Writing user events file.");
  my $events = {};
  foreach my $u (sort keys %people) {
    $events->{$u} = $people{$u};
  }
  $repofs->write_users("JiraIts", $project_id, $events);

  # Write jira metrics json file to disk.
  $repofs->write_output($project_id, "metrics_jira.json",
    encode_json($ret{'metrics'}));

  # Write jira metrics csv file
  my @metrics = sort map { $conf{'provides_metrics'}{$_} }
    keys %{$conf{'provides_metrics'}};
  $csv_out = join(',', sort keys %{$ret{'metrics'}}) . "\n";
  $csv_out
    .= join(',', map { $ret{'metrics'}{$_} || '' } sort keys %{$ret{'metrics'}})
    . "\n";
  $repofs->write_plugin('JiraIts', $project_id . "_jira.csv", $csv_out);
  $repofs->write_output($project_id, "metrics_jira.csv", $csv_out);

  # Write commits history csv file to disk.
  my %timeline = (%timeline_a, %timeline_c);
  my @timeline
    = map { $_ . "," . $timeline_c{$_} . "," . scalar(keys %{$timeline_a{$_}}) }
    sort keys %timeline;
  $csv_out = "date,issues_created,authors\n";
  $csv_out .= join("\n", @timeline) . "\n";
  $repofs->write_plugin('JiraIts', $project_id . "_jira_evol.csv", $csv_out);
  $repofs->write_output($project_id, "jira_evol.csv", $csv_out);

  # Now execute the main R script.
  push(@{$ret{'log'}}, "[Plugins::JiraIts] Executing R main file.");
  my $r = Alambic::Tools::R->new();
  @{$ret{'log'}} = (
    @{$ret{'log'}},
    @{$r->knit_rmarkdown_inc('JiraIts', $project_id, 'jira_its.Rmd')}
  );

  # And execute the figures R scripts.
  @{$ret{'log'}} = (
    @{$ret{'log'}},
    @{
      $r->knit_rmarkdown_html('JiraIts', $project_id, 'jira_evol_authors.rmd',
        ['jira_evol_authors.png', 'jira_evol_authors.svg'])
    }
  );
  @{$ret{'log'}} = (
    @{$ret{'log'}},
    @{
      $r->knit_rmarkdown_html('JiraIts', $project_id, 'jira_evol_created.rmd',
        ['jira_evol_created.png', 'jira_evol_created.svg'])
    }
  );
  @{$ret{'log'}} = (
    @{$ret{'log'}},
    @{
      $r->knit_rmarkdown_html('JiraIts', $project_id, 'jira_evol_summary.rmd',
        [])
    }
  );
  @{$ret{'log'}} = (
    @{$ret{'log'}},
    @{$r->knit_rmarkdown_html('JiraIts', $project_id, 'jira_summary.rmd', [])}
  );

  # Recommendation for late issues
  if (scalar @late) {
    push(
      @{$ret{'recs'}},
      {
        'rid'      => 'JIRA_LATE_ISSUES',
        'severity' => 2,
        'src'      => 'JiraIts',
        'desc'     => 'There are '
          . scalar @late
          . ' issues with a past due date. Either re-plan them or mark them done.'
      }
    );
  }

  return \%ret;
}


1;


=encoding utf8

=head1 NAME

B<Alambic::Plugins::JiraIts> - Retrieves issue tracking data and metrics 
from a Jira server.

=head1 DESCRIPTION

B<Alambic::Plugins::JiraIts> Retrieves issue tracking data and metrics 
from a Jira Server.

Parameters: 

=over

=item * jira_open_states A list of status names considered as open in the workflow, coma-separated.

=item * jira_passwd The password of the user for the connection to the Jira server.

=item * jira_project The Identifier of the project within the Jira instance, e.g. ALX.

=item * jira_url The URL of the Jira server, e.g. https://tracker.openattic.org.

=back
=item * jira_user The id of the user for the connection to the Jira server.


For the complete description of the plugin see the user documentation on the web site: L<https://alambic.io/Plugins/Pre/Jira.html>.

=head1 SEE ALSO

L<https://alambic.io/Plugins/Pre/Jira.html>,

L<Mojolicious>, L<http://alambic.io>, L<https://bitbucket.org/BorisBaldassari/alambic>, L<https://www.atlassian.com/software/jira>


=cut
