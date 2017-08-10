#! perl -I../../lib/

use strict;
use warnings;

use Test::More;
use Data::Dumper;
use File::Path qw( remove_tree );

BEGIN { use_ok('Alambic::Tools::Git'); }

my $tool = Alambic::Tools::Git->new();
isa_ok($tool, 'Alambic::Tools::Git');

my $version = $tool->version();
ok($version =~ /^git version/, "Tool version returns git version xxx")
  or diag explain $version;

my $log = $tool->test();
ok(grep(!/^ERROR/, @{$log}), "Tool self-test returns no ERROR")
  or diag explain $log;
ok(grep(/^OK: Git exec found/, @{$log}), "Git bin is in path")
  or diag explain $log;

# Create repo for test project
my $exec_cloning = 1;
my $dir_src      = "projects/test.project/";

# Remove existing src directory
if (-d $dir_src && $exec_cloning) {
  my $removed_count = remove_tree($dir_src, {error => \my $err});
  if (@$err) {
    for my $diag (@$err) {
      my ($file, $message) = %$diag;
      if ($file eq '') {
        print "General error: $message\n";
      }
      else {
        print "Problem unlinking $file: $message\n";
      }
    }
  }
}

if ($exec_cloning) {
  note("Cloning Alambic.");
  $log = $tool->git_clone('test.project',
    'https://BorisBaldassari@bitbucket.org/BorisBaldassari/alambic.git');
  ok(grep(/^\[Tools::Git\] Cloning /, @{$log}), "Log has Ok cloning.")
    or diag explain $log;
  ok(-e $dir_src, "Source directory exists after cloning.")
    or diag explain $log;
}

$log = $tool->git_clone_or_pull('test.project',
  'https://BorisBaldassari@bitbucket.org/BorisBaldassari/alambic.git');
$log = $tool->git_clone_or_pull('test.project',
  'https://BorisBaldassari@bitbucket.org/BorisBaldassari/alambic.git');
ok(grep(/^\[Tools::Git\] Directory /, @{$log}), "Log has Directory.")
  or diag explain $log;
ok(grep(/Version is /, @{$log}), "Log has Version.") or diag explain $log;
ok(grep(/^\[Tools::Git\] Pulling from origin/, @{$log}),
  "Log has Pull from origin.")
  or diag explain $log;
ok(grep(/Already up-to-date/, @{$log}), "Pull is already up-to-date.")
  or diag explain $log;

my $commits = $tool->git_commits();
ok(ref($commits) eq 'ARRAY', 'Commits is an array.') or diag explain $commits;
ok(exists($commits->[0]{'mod'}), 'Commit has mod attribute.')
  or diag explain $commits;
ok(exists($commits->[0]{'auth'}), 'Commit has auth attribute.')
  or diag explain $commits;
ok(exists($commits->[0]{'msg'}), 'Commit has msg attribute.')
  or diag explain $commits;
ok(exists($commits->[0]{'cmtr'}), 'Commit has cmtr attribute.')
  or diag explain $commits;
ok(exists($commits->[0]{'time'}), 'Commit has time attribute.')
  or diag explain $commits;
ok(exists($commits->[0]{'id'}), 'Commit has id attribute.')
  or diag explain $commits;

$log = $tool->git_log('test.project');
ok(grep(/^\[Tools::Git\] Getting Git log for /, @{$log}),
  "Log has Getting log.")
  or diag explain $log;
ok(-e "projects/test.project/input/test.project_git_log.txt",
  "Log file has been created in input directory.")
    or diag explain $log;

done_testing();
