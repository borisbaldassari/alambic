package Alambic::Plugins::Git;

use strict;
use warnings;

use Alambic::Model::RepoFS;
use Alambic::Tools::Git;
use Alambic::Tools::R;

use Date::Parse;
use Time::Piece;
use Time::Seconds;
use Mojo::JSON qw( decode_json encode_json );
use Data::Dumper;

# Main configuration hash for the plugin
my %conf = (
  "id"   => "Git",
  "name" => "Git",
  "desc" => [
    "Retrieves configuration management data from a git local repository. This plugin uses the Git Tool in Alambic, so please make sure ",
    'See <a href="https://bitbucket.org/BorisBaldassari/alambic/wiki/Plugins/3.x/Git">the project\'s wiki</a> for more information.',
  ],
  "type"    => "pre",
  "ability" => ['info', 'metrics', 'data', 'recs', 'figs', 'viz', 'users'],
  "params"  => {
    "git_url" =>
      'The git server URL, e.g. https://BorisBaldassari@bitbucket.org/BorisBaldassari/alambic.git.',
  },
  "provides_cdata" => [],
  "provides_info"  => ["GIT_SERVER",],
  "provides_data"  => {
    "import_git.txt" =>
      "The original git log file as retrieved from git (TXT).",
    "metrics_git.json" => "Current metrics for the SCM Git plugin (JSON).",
    "git_commits.csv" =>
      "Evolution of number of commits and authors by day (CSV)."
  },
  "provides_metrics" => {
    "SCM_AUTHORS"       => "SCM_AUTHORS",
    "SCM_AUTHORS_1W"    => "SCM_AUTHORS_1W",
    "SCM_AUTHORS_1M"    => "SCM_AUTHORS_1M",
    "SCM_AUTHORS_1Y"    => "SCM_AUTHORS_1Y",
    "SCM_COMMITS"       => "SCM_COMMITS",
    "SCM_COMMITS_1W"    => "SCM_COMMITS_1W",
    "SCM_COMMITS_1M"    => "SCM_COMMITS_1M",
    "SCM_COMMITS_1Y"    => "SCM_COMMITS_1Y",
    "SCM_COMMITTERS"    => "SCM_COMMITTERS",
    "SCM_COMMITTERS_1W" => "SCM_COMMITTERS_1W",
    "SCM_COMMITTERS_1M" => "SCM_COMMITTERS_1M",
    "SCM_COMMITTERS_1Y" => "SCM_COMMITTERS_1Y",
    "SCM_FILES"         => "SCM_FILES",
  },
  "provides_figs" => {
    'git_summary.html'      => "HTML export of Git main metrics.",
    'git_evol_summary.html' => "HTML export of Git SCM evolution summary.",
    'git_evol_authors.png'  => "PNG export of Git SCM authors evolution.",
    'git_evol_authors.svg'  => "SVG export of Git SCM authors evolution.",
    'git_evol_authors.html' => "HTML export of Git authors evolution.",
    'git_evol_commits.png'  => "PNG export of Git SCM commits evolution.",
    'git_evol_commits.svg'  => "SVG export of Git SCM commits evolution.",
    'git_evol_commits.html' => "HTML export of Git commits evolution.",
  },
  "provides_recs" => ["SCM_LOW_ACTIVITY", "SCM_ZERO_ACTIVITY",],
  "provides_viz" => {"git_scm.html" => "Git SCM",},
);

# Models::RepoFS object
my $repofs;

# Tools::Git object
my $g;

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
  $repofs = Alambic::Model::RepoFS->new();

  # Create a Tools::Git object for all our manipulations
  my $git_url = $conf->{'git_url'};
  $g = Alambic::Tools::Git->new($project_id, $git_url);

  # Create or update local working copy
  push(@{$ret{'log'}}, @{&_setup_repo($project_id, $git_url, $repofs)});

  # Analyse git log, generate info, metrics, plots and visualisation.
  my $tmp_ret = &_compute_data($project_id, $repofs);

  $ret{'metrics'}         = $tmp_ret->{'metrics'};
  $ret{'recs'}            = $tmp_ret->{'recs'};
  $ret{'info'}{'GIT_URL'} = $git_url;
  push(@{$ret{'log'}}, @{$tmp_ret->{'log'}});

  return \%ret;
}

# Create (clone) or update (pull) the repository locally.
# Also get the git log for the repository.
sub _setup_repo($$$) {
  my ($project_id, $git_url, $repofs) = @_;

  my $log = ["[Plugins:Git] Setup local repository for [$project_id]."];

  $log = $g->git_clone_or_pull($project_id);
  push(@$log, @{$g->git_log($project_id)});

  return $log;
}


# Basically read the imported files and extract metrics
sub _compute_data($$) {
  my ($project_id, $repofs) = @_;

  my %metrics;
  my @recs;
  my @log;

  # Create a Tools::Git object for all our manipulations
  my @commits = @{$g->git_commits()};

  # Time::Piece object. Will be used for the date calculations.
  my $t_now = localtime;
  my $t_1w  = $t_now - ONE_WEEK;
  my $t_1m  = $t_now - ONE_MONTH;
  my $t_1y  = $t_now - ONE_YEAR;

  $metrics{'SCM_COMMITS'} = scalar @commits;

  my (%authors, %authors_1w, %authors_1m, %authors_1y, %users);
  my (%committers, %committers_1w, %committers_1m, %committers_1y);
  my %timeline_c;
  my %timeline_a;
  push(@log,
    "[Plugins::Git] Parsing git log: " . scalar @commits . " commits.");

  foreach my $c (@commits) {
    my $date = Time::Piece->strptime($c->{'time'} || 0, "%s");
    my $date_m = $date->strftime("%Y-%m-%d");
    $timeline_c{$date_m}++;
    my $id = $c->{'id'};

    if (defined($c->{'auth'})) {
      $authors{$c->{'auth'}}++;
      my $event = {
        "type" => "commit",
        "id"   => $c->{'id'},
        "time" => $c->{'time'},
        "msg"  => $c->{'msg'}
      };
      push(@{$users{$c->{'auth'}}}, $event);
      $timeline_a{$date_m}{$c->{'auth'}}++;
    }
    if (defined($c->{'cmtr'})) {
      $committers{$c->{'cmtr'}}++;
    }

    # Is the commit recent (<1W)?
    if ($date > $t_1w->epoch) {
      $metrics{'SCM_COMMITS_1W'}++;
      if (defined($c->{'auth'})) {
        $authors_1w{$c->{'auth'}}++;
      }
      if (defined($c->{'cmtr'})) {
        $committers_1w{$c->{'cmtr'}}++;
      }
    }

    # Is the commit recent (<1M)?
    if ($date > $t_1m->epoch) {
      $metrics{'SCM_COMMITS_1M'}++;
      if (defined($c->{'auth'})) {
        $authors_1m{$c->{'auth'}}++;
      }
      if (defined($c->{'cmtr'})) {
        $committers_1m{$c->{'cmtr'}}++;
      }
    }

    # Is the commit recent (<1Y)?
    if ($date > $t_1y->epoch) {
      $metrics{'SCM_COMMITS_1Y'}++;
      if (defined($c->{'auth'})) {
        $authors_1y{$c->{'auth'}}++;
      }
      if (defined($c->{'cmtr'})) {
        $committers_1y{$c->{'cmtr'}}++;
      }
    }
  }

  $metrics{'SCM_AUTHORS'}       = scalar keys %authors;
  $metrics{'SCM_AUTHORS_1W'}    = scalar keys %authors_1w;
  $metrics{'SCM_AUTHORS_1M'}    = scalar keys %authors_1m;
  $metrics{'SCM_AUTHORS_1Y'}    = scalar keys %authors_1y;
  $metrics{'SCM_COMMITTERS'}    = scalar keys %committers;
  $metrics{'SCM_COMMITTERS_1W'} = scalar keys %committers_1w;
  $metrics{'SCM_COMMITTERS_1M'} = scalar keys %committers_1m;
  $metrics{'SCM_COMMITTERS_1Y'} = scalar keys %committers_1y;

  # Set user information for profile
  push(@log, "[Plugins::Git] Writing user events file.");
  my $events = {};
  foreach my $u (sort keys %users) {
    $events->{$u} = $users{$u};
  }
  $repofs->write_users("Git", $project_id, $events);

  # Write scm metrics json file to disk.
  $repofs->write_output($project_id, "metrics_git.json",
    encode_json(\%metrics));

  # Write static metrics file
  my @metrics = sort map { $conf{'provides_metrics'}{$_} }
    keys %{$conf{'provides_metrics'}};
  my $csv_out = join(',', sort @metrics) . "\n";
  $csv_out .= join(',', map { $metrics{$_} || '' } sort @metrics) . "\n";
  $repofs->write_plugin('Git', $project_id . "_git.csv", $csv_out);
  $repofs->write_output($project_id, "metrics_git.csv", $csv_out);

  # Write commits history json file to disk.
  my %timeline = (%timeline_a, %timeline_c);
  my @timeline
    = map { $_ . "," . $timeline_c{$_} . "," . scalar(keys %{$timeline_a{$_}}) }
    sort keys %timeline;
  $csv_out = "date,commits,authors\n";
  $csv_out .= join("\n", @timeline) . "\n";
  $repofs->write_plugin('Git', $project_id . "_git_commits.csv", $csv_out);
  $repofs->write_output($project_id, "git_commits.csv", $csv_out);

  # Now execute the main R script.
  push(@log, "[Plugins::Git] Executing R main file.");
  my $r = Alambic::Tools::R->new();
  @log = (@log, @{$r->knit_rmarkdown_inc('Git', $project_id, 'git_scm.Rmd')});

  # And execute the figures R scripts.
  @log = (
    @log,
    @{
      $r->knit_rmarkdown_html('Git', $project_id, 'git_evol_commits.rmd',
        ['git_evol_commits.png', 'git_evol_commits.svg'])
    }
  );
  @log = (
    @log,
    @{
      $r->knit_rmarkdown_html('Git', $project_id, 'git_evol_authors.rmd',
        ['git_evol_authors.png', 'git_evol_authors.svg'])
    }
  );
  @log = (
    @log, @{$r->knit_rmarkdown_html('Git', $project_id, 'git_evol_summary.rmd')}
  );
  @log
    = (@log, @{$r->knit_rmarkdown_html('Git', $project_id, 'git_summary.rmd')});


  # # Execute checks and fill recs.

# # If less than 5 commits during last year, consider the project inactive.
# if ( ( $metrics_new->{'SCM_COMMITS_365'} || 0 ) < 2 ) {
# 	push( @recs, { 'rid' => 'SCM_LOW_ACTIVITY',
# 		       'severity' => 0,
# 		       'src' => 'EclipseScm',
# 		       'desc' => 'There have been only ' . $metrics_new->{'SCM_COMMITS_365'}
# 		       . ' commits during last year. The project is considered inactive.'
# 	      }
# 	    );
# } elsif ( ( $metrics_new->{'SCM_COMMITS_365'} || 0 ) < 12 ) {
# 	push( @recs, { 'rid' => 'SCM_LOW_ACTIVITY',
# 		       'severity' => 0,
# 		       'src' => 'EclipseScm',
# 		       'desc' => 'There have been only ' . $metrics_new->{'SCM_COMMITS_365'}
# 		       . ' commits during last year. The project has a very low activity.'
# 	      }
# 	      );
# 	}


  return {"metrics" => \%metrics, "recs" => \@recs, "log" => \@log,};
}


1;
