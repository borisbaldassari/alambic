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

package Alambic::Plugins::Bugzilla;

use strict;
use warnings;

use Alambic::Model::RepoFS;
use Alambic::Tools::R;

use Mojo::UserAgent;
use Mojo::JSON qw( decode_json encode_json );
use Date::Parse;
use Time::Piece;
use Time::Seconds;
use Text::CSV;
use Data::Dumper;

# Main configuration hash for the plugin
my %conf = (
  "id"   => "Bugzilla",
  "name" => "Bugzilla",
  "desc" => [
    'The Bugzilla plugin retrieves issues information from a Bugzilla server (version 5.1+), using the <a href="http://bugzilla.readthedocs.io/en/latest/api/index.html">REST API</a>.',
    'See <a href="https://alambic.io/Plugins/Pre/Bugzilla">the project\'s wiki</a> for more information.',
  ],
  "type"    => "pre",
  "ability" => ['info', 'metrics', 'data', 'figs', 'recs', 'viz', 'users'],
  "params"  => {
    "bugzilla_url"     => "The URL of the Bugzilla server, e.g. https://bugs.eclipse.org/bugs/.",
    "bugzilla_project" => "The project ID to be requested on the bugzilla server.",
    "proxy" =>
      'If a proxy is required to access the remote resource of this plugin, please provide its URL here. A blank field means no proxy, and the <code>default</code> keyword uses the proxy from environment variables, see <a href="https://alambic.io/Documentation/Admin/Projects.html">the online documentation about proxies</a> for more details. Example: <code>https://user:pass@proxy.mycorp:3777</code>.',
  },
  "provides_cdata" => [],
  "provides_info"  => ["BZ_URL",],
  "provides_data"  => {
    "import_bugzilla.json" =>
      "The original file of current information, downloaded from the Bugzilla server (JSON).",
    "metrics_bugzilla.csv" =>
      "The list of metrics with their values (CSV).",
    "metrics_bugzilla.json" =>
      "The list of metrics with their values (JSON).",
    "bugzilla_evol.csv" =>
      "The evolution of issues created and authors by day (CSV).",
    "bugzilla_issues.csv" =>
      "The list of issues, with fields 'id, summary, status, assignee, reporter, due_date, created_at, updated_at' (CSV).",
    # "bugzilla_issues_late.csv" =>
    #   "The list of late issues (i.e. their due_date has past), with fields 'id, summary, status, assignee, reporter, due_date, created_at, updated_at' (CSV).",
    "bugzilla_issues_open.csv" =>
      "The list of open issues, with fields 'id, summary, status, assignee, reporter, due_date, created_at, updated_at' (CSV).",
    "bugzilla_issues_open_unassigned.csv" =>
      "The list of open and unassigned issues, with fields 'id, summary, status, assignee, reporter, due_date, created_at, updated_at' (CSV).",
    "bugzilla_components.csv" =>
      "The list of components that have at least one bug registered against them (CSV).",
    "bugzilla_milestones.csv" =>
      "The list of milestones that have at least one bug targeted for (CSV).",
    "bugzilla_versions.csv" =>
      "The list of software versions that have at least one bug registered against them (CSV).",
  },
  "provides_metrics" => {
    "BZ_VOL"             => "ITS_ISSUES_ALL",
    "BZ_AUTHORS"         => "ITS_AUTHORS",
    "BZ_AUTHORS_1W"      => "ITS_AUTHORS_1W",
    "BZ_AUTHORS_1M"      => "ITS_AUTHORS_1M",
    "BZ_AUTHORS_1Y"      => "ITS_AUTHORS_1Y",
    "BZ_CREATED_1W"      => "ITS_CREATED_1W",
    "BZ_CREATED_1M"      => "ITS_CREATED_1M",
    "BZ_CREATED_1Y"      => "ITS_CREATED_1Y",
    "BZ_UPDATED_1W"      => "ITS_UPDATED_1W",
    "BZ_UPDATED_1M"      => "ITS_UPDATED_1M",
    "BZ_UPDATED_1Y"      => "ITS_UPDATED_1Y",
    "BZ_OPEN"            => "ITS_OPEN",
    "BZ_OPEN_PERCENT"    => "ITS_OPEN_PERCENT",
#    "BZ_LATE"            => "ITS_LATE",
    "BZ_OPEN_UNASSIGNED" => "ITS_OPEN_UNASSIGNED",
  },
  "provides_figs" => {
    'bugzilla_summary.html' => "HTML summary of Bugzilla issues main metrics (HTML)",
    'bugzilla_evol_summary.html' => "Evolution of Bugzilla main metrics (HTML)",
    'bugzilla_evol_created.html' => "Evolution of Bugzilla issues creation (HTML)",
    'bugzilla_evol_authors.html' => "Evolution of Bugzilla issues authors (HTML)",
  },
  "provides_recs" => ["BZ_LATE_ISSUES",],
  "provides_viz"  => {"bugzilla.html" => "Bugzilla",},
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

  my $bugzilla_url         = $conf->{'bugzilla_url'};
  my $bugzilla_project = $conf->{'bugzilla_project'};
  my $proxy_url    = $conf->{'proxy'} || '';

  # Set info BZ_URL
  my $url_base = "https://bugs.eclipse.org/bugs/";
  $ret{'info'}{'BZ_URL'} = $url_base . '/buglist.cgi?product=' . $bugzilla_project;

#  my $bugzilla_conf
#    = {url => $bugzilla_url, username => $bugzilla_user, password => $bugzilla_passwd,};

  # Configure Proxy
  if ($proxy_url =~ m!^default!i) {

    # If 'default', then use detect
    foreach my $v (('https_proxy', 'HTTPS_PROXY', 'http_proxy', 'HTTP_PROXY')) {
      if (defined($ENV{$v})) {
#        $bugzilla_conf->{'proxy'} = $ENV{$v};
        push(
          @{$ret{'log'}},
          "[Plugins::Bugzilla] Using default proxy ["
#            . $bugzilla_conf->{'proxy'} . "]."
        );
        last;
      }
    }
  }
  elsif ($proxy_url =~ m!\S+$!) {
    # If something, then use it
#    $bugzilla_conf->{'proxy'} = $proxy_url;
    push(
      @{$ret{'log'}},
      "[Plugins::Bugzilla] Using provided proxy [$proxy_url]."
    );
  }
  else {
    # If blank, then use no proxy
    push(@{$ret{'log'}}, "[Plugins::Bugzilla] No proxy defined [$proxy_url].");
  }


  my $ua  = Mojo::UserAgent->new;
  my @bugs;

  # Define the list of attributes we want to use for the list of bugs
  # This is only used when no bug_id is provided, though.
  my @attrs_def = ('id', 'summary', 'status', 'resolution', 'severity', 'priority', 'classification', 
             'platform', 'product', 'version', 'component', 'creation_time', 'creator', 
             'assigned_to', 'last_change_time', 'target_milestone', 'url');

  my $url = $url_base . "rest/bug?product=" . $bugzilla_project . 
      "&include_fields=" . join(',', @attrs_def) . ",is_open";
  
  push(@{$ret{'log'}}, "[Plugins::Bugzilla] Using URL [$url].");
  my $res = $ua->get($url)->result;
  
  if (not $res->is_success) {
      push(@{$ret{'log'}}, 
           "[Plugins::Bugzilla] ERROR: Could not get resource [$url].\n" . 
           "Message is: " . $res->message . "\n" );
      return \%ret;
  }
  
  my $json = $res->body;
  my $data = decode_json($json); 
  push(@{$ret{'log'}}, "[Plugins::Bugzilla] Found " . scalar(@{$data->{'bugs'}}) . " issues.\n");
  
  # Write json file to import directory
  $repofs->write_input( $project_id, "import_bugzilla.json",
                        encode_json($data->{'bugs'}) );

  # my (@late, @open, @unassigned_open, %people);
  my $csv_out = join( ',', @attrs_def ) . "\n";

  my $csv_open_out            = $csv_out;
  my $csv_unassigned_open_out = $csv_out;
  
  my ($bz_created_1w, $bz_created_1m, $bz_created_1y) = (0, 0, 0);
  my ($bz_updated_1w, $bz_updated_1m, $bz_updated_1y) = (0, 0, 0);
  my (%authors, %authors_1w, %authors_1m, %authors_1y, %people);
  my (%components, %milestones, %versions);
  my (@open, @unassigned_open);
  my %timeline_c;
  my %timeline_a;
  
  my $csv                 = Text::CSV->new({binary => 1, eol => "\n"});
# It seems that the deadline field is never filled (i.e. always undef).
#  my $csv_late            = Text::CSV->new({binary => 1, eol => "\n"});
  my $csv_open            = Text::CSV->new({binary => 1, eol => "\n"});
  my $csv_unassigned_open = Text::CSV->new({binary => 1, eol => "\n"});
  my $first = 10;
  foreach my $issue (@{$data->{'bugs'}}) {

      # Convert string dates to epoch seconds      
      my $date_created
          = Time::Piece->strptime(int(str2time($issue->{'creation_time'}) || 0), "%s");
      my $date_updated
          = Time::Piece->strptime(int(str2time($issue->{'creation_time'}) || 0), "%s");
      my $t_now = time();

      my $date_m = $date_created->strftime("%Y-%m-%d"); 
      $timeline_c{$date_m}++;
      $timeline_a{$date_m}{$issue->{'creator'}}++;
      $authors{$issue->{'creator'}}++;

      # Rebuild the URL for the issue.
      $issue->{'url'} = $url_base . '/bugs/show_bug.cgi?id=' . $issue->{'id'};
      
      my @attrs_v = map { $issue->{$_} } @attrs_def;
      $csv->combine(@attrs_v);
      $csv_out .= $csv->string();
#      if ($first) { print "KEYS " . Dumper(%$issue); $first-- }
      if ( $issue->{'is_open'} ) {
          push(@open, $issue->{'id'});
          $csv_open_out .= $csv->string();
      }


      # list components
      if ( defined($issue->{'component'}) ) {
          $components{$issue->{'component'}}++;
      }

      # list target_milestones
      if ( defined($issue->{'target_milestone'}) ) {
          $milestones{$issue->{'target_milestone'}}++;
      }

      # list versions
      if ( defined($issue->{'version'}) ) {
          $versions{$issue->{'version'}}++;
      }

      #   # Check if issue's due date has past
      #   if (defined($date_due) and $date_due < $t_now) {
      #     push(@late, $issue->{'key'});
      #     $csv_late_out .= $csv->string();
      #   }
      
      # Check if issue is assigned and open
      if ( (not defined($issue->{'assigned_to'}))
           && grep($issue->{'is_open'}) ) {
          push(@unassigned_open, $issue->{'id'});
          $csv_unassigned_open_out .= $csv->string();
      }
      
      # Populate %people to show activity in the user's profile
      if ( exists $issue->{'assigned_to'} ) {
          my $event = {
              "type" => "issue_assigned",
              "id"   => $issue->{'id'},
              "msg"  => $issue->{'summary'},
              "url"  => $issue->{'url'},
          };
          push(@{$people{$issue->{'assigned_to'}}}, $event);
      }
      
      # Populate %people to show activity in the user's profile
      if (exists $issue->{'creator'}) {
          my $event = {
              "type" => "issue_created",
              "id"   => $issue->{'id'},
              "msg"  => $issue->{'summary'},
              "url"  => $issue->{'url'},
              "time" => $issue->{'creation_time'}
          };
          push(@{$people{$issue->{'creator'}}}, $event);
      }
      
      # Is the issue recent (<1W)?
      if ($date_created > $t_1w->epoch) {
          $authors_1w{$issue->{'creator'}}++;
          $bz_created_1w++;
      }
      
      # Is the issue recent (<1M)?
      if ($date_created > $t_1m->epoch) {
          $authors_1m{$issue->{'creator'}}++;
          $bz_created_1m++;
      }
      
      # Is the issue recent (<1Y)?
      if ($date_created > $t_1y->epoch) {
          $authors_1y{$issue->{'creator'}}++;
          $bz_created_1y++;
      }
      
      # Has the issue been updated recently (<1W)?
      if ($date_updated > $t_1w->epoch) {
          $bz_updated_1w++;
      }
      
      # Has the issue been updated recently (<1M)?
      if ($date_updated > $t_1m->epoch) {
          $bz_updated_1m++;
      }
      
      # Has the issue been updated recently (<1Y)?
      if ($date_updated > $t_1y->epoch) {
          $bz_updated_1y++;
      }
  }
  
  # Write metrics to csv and json files.
  $repofs->write_output($project_id, "bugzilla_issues.csv",      $csv_out);
  # $repofs->write_output($project_id, "bugzilla_issues_late.csv", $csv_late_out);
  $repofs->write_output($project_id, "bugzilla_issues_open.csv", $csv_open_out);
  $repofs->write_output($project_id, "bugzilla_issues_open_unassigned.csv",
                        $csv_unassigned_open_out);

  # Compute lists (components, milestones, versions)
  # Milestones
  $csv = Text::CSV->new({binary => 1, eol => "\n"});
  $csv_out = "Milestone,Bugs\n";
  foreach my $i (sort keys %milestones) {
      $csv->combine( ($i, $milestones{$i} ) );
      $csv_out .= $csv->string();
  }
  $repofs->write_output($project_id, "bugzilla_milestones.csv", $csv_out);

  # Components
  $csv = Text::CSV->new({binary => 1, eol => "\n"});
  $csv_out = "Component,Bugs\n";
  foreach my $i (sort keys %components) {
      $csv->combine( ($i, $components{$i} ) );
      $csv_out .= $csv->string();
  }
  $repofs->write_output($project_id, "bugzilla_components.csv", $csv_out);

  # Versions
  $csv = Text::CSV->new({binary => 1, eol => "\n"});
  $csv_out = "Version,Bugs\n";
  foreach my $i (sort keys %versions) {
      $csv->combine( ($i, $versions{$i} ) );
      $csv_out .= $csv->string();
  }
  $repofs->write_output($project_id, "bugzilla_versions.csv", $csv_out);





  # Compute and store metrics
  $ret{'metrics'}{'ITS_ISSUES_ALL'}     = scalar @{$data->{'bugs'}};
  $ret{'metrics'}{'ITS_AUTHORS'} = scalar keys %authors;
  $ret{'metrics'}{'ITS_OPEN'}    = scalar @open;
  $ret{'metrics'}{'ITS_OPEN_PERCENT'}
  = sprintf("%.0f", 100 * (scalar @open) / (scalar @{$data->{'bugs'}}));
  # $ret{'metrics'}{'ITS_LATE'}            = scalar @late            || 0;
  $ret{'metrics'}{'ITS_OPEN_UNASSIGNED'} = scalar @unassigned_open || 0;
  $ret{'metrics'}{'ITS_AUTHORS_1W'}      = scalar keys %authors_1w || 0;
  $ret{'metrics'}{'ITS_AUTHORS_1M'}      = scalar keys %authors_1m || 0;
  $ret{'metrics'}{'ITS_AUTHORS_1Y'}      = scalar keys %authors_1y || 0;
  $ret{'metrics'}{'ITS_CREATED_1W'}      = $bz_created_1w;
  $ret{'metrics'}{'ITS_CREATED_1M'}      = $bz_created_1m;
  $ret{'metrics'}{'ITS_CREATED_1Y'}      = $bz_created_1y;
  $ret{'metrics'}{'ITS_UPDATED_1W'}      = $bz_updated_1w;
  $ret{'metrics'}{'ITS_UPDATED_1M'}      = $bz_updated_1m;
  $ret{'metrics'}{'ITS_UPDATED_1Y'}      = $bz_updated_1y;
  
  # Set user information for profile
  push(@{$ret{'log'}}, "[Plugins::Bugzilla] Writing user events file.");
  my $events = {};
  foreach my $u (sort keys %people) {
      $events->{$u} = $people{$u};
  }
  $repofs->write_users("Bugzilla", $project_id, $events);
  
  # Write bugzilla metrics json file to disk.
  $repofs->write_output($project_id, "metrics_bugzilla.json",
                        encode_json($ret{'metrics'}));

  # Write bugzilla metrics csv file
  my @metrics = map { $conf{'provides_metrics'}{$_} } sort keys %{$conf{'provides_metrics'}};
  $csv_out = join( ',', @metrics ) . "\n";
  my @attrs_v = map { $ret{'metrics'}{$_} } @metrics;
  $csv->combine(@attrs_v);
  $csv_out .= $csv->string();
  $repofs->write_output($project_id, "metrics_bugzilla.csv", $csv_out);

  # Write issues history csv file to disk.
  my %timeline = (%timeline_a, %timeline_c);
  my @timeline
      = map { $_ . "," . $timeline_c{$_} . "," . scalar(keys %{$timeline_a{$_}}) }
     sort keys %timeline;

  $csv_out = "date,issues_created,authors\n";
  $csv_out .= join("\n", @timeline) . "\n";
  $repofs->write_output($project_id, "bugzilla_evol.csv", $csv_out);

  # # Now execute the main R script.
  # push(@{$ret{'log'}}, "[Plugins::Bugzilla] Executing R main file.");
  # my $r = Alambic::Tools::R->new();
  # @{$ret{'log'}} = (
  #   @{$ret{'log'}},
  #   @{$r->knit_rmarkdown_inc('Bugzilla', $project_id, 'bugzilla_its.Rmd')}
  # );

  # # And execute the figures R scripts.
  # @{$ret{'log'}} = (
  #   @{$ret{'log'}},
  #   @{
  #     $r->knit_rmarkdown_html('Bugzilla', $project_id, 'bugzilla_evol_authors.rmd',
  #       ['bugzilla_evol_authors.png', 'bugzilla_evol_authors.svg'])
  #   }
  # );
  # @{$ret{'log'}} = (
  #   @{$ret{'log'}},
  #   @{
  #     $r->knit_rmarkdown_html('Bugzilla', $project_id, 'bugzilla_evol_created.rmd',
  #       ['bugzilla_evol_created.png', 'bugzilla_evol_created.svg'])
  #   }
  # );
  # @{$ret{'log'}} = (
  #   @{$ret{'log'}},
  #   @{
  #     $r->knit_rmarkdown_html('Bugzilla', $project_id, 'bugzilla_evol_summary.rmd',
  #       [])
  #   }
  # );
  # @{$ret{'log'}} = (
  #   @{$ret{'log'}},
  #   @{$r->knit_rmarkdown_html('Bugzilla', $project_id, 'bugzilla_summary.rmd', [])}
  # );

  # # Recommendation for late issues
  # if (scalar @late) {
  #   push(
  #     @{$ret{'recs'}},
  #     {
  #       'rid'      => 'BZ_LATE_ISSUES',
  #       'severity' => 2,
  #       'src'      => 'JiraIts',
  #       'desc'     => 'There are '
  #         . scalar @late
  #         . ' issues with a past due date. Either re-plan them or mark them done.'
  #     }
  #   );
  # }

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
