#! perl -I../../lib/

use strict;
use warnings;

use Test::More;
use Mojo::JSON qw( decode_json);
use Data::Dumper;

BEGIN { use_ok('Alambic::Plugins::Git'); }

my $plugin = Alambic::Plugins::Git->new('test.project',
  'https://BorisBaldassari@bitbucket.org/BorisBaldassari/alambic.git');
isa_ok($plugin, 'Alambic::Plugins::Git');

note("Checking the plugin parameters. ");
my $conf = $plugin->get_conf();

ok(grep(m!info!,    @{$conf->{'ability'}}), "Conf has ability > info");
ok(grep(m!metrics!, @{$conf->{'ability'}}), "Conf has not ability > metrics");
ok(grep(m!data!,    @{$conf->{'ability'}}), "Conf has not ability > data");
ok(grep(m!recs!,    @{$conf->{'ability'}}), "Conf has not ability > recs");
ok(grep(m!figs!,    @{$conf->{'ability'}}), "Conf has not ability > figs");
ok(grep(m!viz!,     @{$conf->{'ability'}}), "Conf has ability > viz");
ok(grep(m!users!,   @{$conf->{'ability'}}), "Conf has not ability > users");

ok(
  grep(m!GIT_SERVER!, @{$conf->{'provides_info'}}),
  "Conf has provides_info > MLS_DEV_URL"
);

ok(grep(m!import_git.txt!, keys %{$conf->{'provides_data'}}),
  "Conf has provides_data > import_git.txt");
ok(grep(m!metrics_git.json!, keys %{$conf->{'provides_data'}}),
  "Conf has provides_data > metrics_git.json");
ok(grep(m!git_commits.csv!, keys %{$conf->{'provides_data'}}),
  "Conf has provides_data > git_commits.csv");

ok(grep(m!SCM_AUTHORS!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > SCM_AUTHORS");
ok(grep(m!SCM_COMMITS!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > SCM_COMMITS");
ok(grep(m!SCM_COMMITTERS!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > SCM_COMMITTERS");
ok(grep(m!SCM_FILES!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > SCM_FILES");

ok(grep(m!SCM_FILES!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > SCM_FILES");

ok(grep(m!metrics!, @{$conf->{'ability'}}), "Conf has ability > metrics");
ok(grep(m!data!,    @{$conf->{'ability'}}), "Conf has ability > data");
ok(grep(m!recs!,    @{$conf->{'ability'}}), "Conf has ability > recs");
ok(grep(m!info!,    @{$conf->{'ability'}}), "Conf has ability > info");
ok(grep(m!viz!,     @{$conf->{'ability'}}), "Conf has ability > viz");

ok(grep(m!git_url!, keys %{$conf->{'params'}}), "Conf has params > git_url");

ok(
  grep(m!SCM_LOW_ACTIVITY!, @{$conf->{'provides_recs'}}),
  "Conf has provides_recs > SCM_LOW_ACTIVITY"
);
ok(
  grep(m!SCM_ZERO_ACTIVITY!, @{$conf->{'provides_recs'}}),
  "Conf has provides_recs > SCM_ZERO_ACTIVITY"
);

ok(grep(m!git_summary.html!, keys %{$conf->{'provides_figs'}}),
  "Conf has provides_figs > git_summary.html");

ok(grep(m!git_scm!, keys %{$conf->{'provides_viz'}}),
  "Conf has provides_figs > git_scm");

# Execute the plugin
note("Execute the plugin with alambic.test project. ");
my $ret = $plugin->run_plugin(
  "alambic.test",
  {
    'git_url' =>
      'https://BorisBaldassari@bitbucket.org/BorisBaldassari/alambic.git'
  }
);

ok(grep(m!GIT_URL!, keys %{$ret->{'info'}}), "Ret has info > GIT_URL");

ok(grep(m!\[Tools::Git\] Getting Git log!, @{$ret->{'log'}}),
  "Ret has log > Getting Git log");
ok(grep(m!\[Plugins::Git\] Parsing git log:!, @{$ret->{'log'}}),
  "Ret has log > Parsing git log");
ok(grep(m!\[Plugins::Git\] Writing user events file.!, @{$ret->{'log'}}),
  "Ret has log > Getting Git log");

ok($ret->{'metrics'}{'SCM_COMMITTERS'} =~ /\d+/, "Metrics has SCM_COMMITTERS");
ok($ret->{'metrics'}{'SCM_COMMITTERS'} < 999,    "Metrics has SCM_COMMITTERS");
ok($ret->{'metrics'}{'SCM_COMMITTERS_1M'} =~ /\d+/,
  "Metrics has SCM_COMMITTERS_1M");
ok($ret->{'metrics'}{'SCM_COMMITTERS_1W'} =~ /\d+/,
  "Metrics has SCM_COMMITTERS_1W");
ok($ret->{'metrics'}{'SCM_COMMITTERS_1Y'} =~ /\d+/,
  "Metrics has SCM_COMMITTERS_1Y");

ok($ret->{'metrics'}{'SCM_AUTHORS'} =~ /\d+/,    "Metrics has SCM_AUTHORS");
ok($ret->{'metrics'}{'SCM_AUTHORS'} < 999,       "Metrics has SCM_AUTHORS");
ok($ret->{'metrics'}{'SCM_AUTHORS_1M'} =~ /\d+/, "Metrics has SCM_AUTHORS_1M");
ok($ret->{'metrics'}{'SCM_AUTHORS_1W'} =~ /\d+/, "Metrics has SCM_AUTHORS_1W");
ok($ret->{'metrics'}{'SCM_AUTHORS_1Y'} =~ /\d+/, "Metrics has SCM_AUTHORS_1Y");

ok($ret->{'metrics'}{'SCM_COMMITS'} =~ /\d+/,    "Metrics has SCM_COMMITS");
ok($ret->{'metrics'}{'SCM_COMMITS'} < 99999,     "Metrics has SCM_COMMITS");
ok($ret->{'metrics'}{'SCM_COMMITS_1M'} =~ /\d+/, "Metrics has SCM_COMMITS_1M");
ok($ret->{'metrics'}{'SCM_COMMITS_1W'} =~ /\d+/, "Metrics has SCM_COMMITS_1W");
ok($ret->{'metrics'}{'SCM_COMMITS_1Y'} =~ /\d+/, "Metrics has SCM_COMMITS_1Y");

# Check that files have been created.
note("Check that files have been created. ");
ok(-e "projects/tools.cdt/input/tools.cdt_import_pmi.json",
  "Check that file import_pmi.json exists.");
ok(
  -e "projects/tools.cdt/output/tools.cdt_pmi.json",
  "Check that file tools.cdt_metrics_pmi.json exists."
);
ok(
  -e "projects/tools.cdt/output/tools.cdt_pmi_checks.json",
  "Check that file tools.cdt_metrics_pmi_checks.json exists."
);
ok(
  -e "projects/tools.cdt/output/tools.cdt_pmi_checks.csv",
  "Check that file tools.cdt_metrics_pmi_checks.csv exists."
);


done_testing();
