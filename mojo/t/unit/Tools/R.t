#! perl -I../../lib/

use strict;
use warnings;

use File::Path qw(make_path remove_tree);
use Test::More;
use File::Copy;

BEGIN { use_ok('Alambic::Tools::R'); }

my $tool = Alambic::Tools::R->new();
isa_ok($tool, 'Alambic::Tools::R');

note("Executing module self-test.");
my $log = $tool->test();
ok(grep(!/^ERROR/, @{$log}), "Tool test() returns no ERROR")
  or diag explain $log;
ok(grep(/^OK: R exec found in PATH/, @{$log}), "R bin is in path")
  or diag explain $log;
ok(grep(/^OK: Rscript exec found in PATH/, @{$log}), "Rscript bin is in path")
  or diag explain $log;

# Create output dir for test.project
make_path('projects/test.project/output/');

# Knit documents from the Hudson plugin
note("Executing Hudson Rmd file.");
print Dumper(`ls t/resources/`); 
copy "t/resources/test.project_hudson_builds.csv", "lib/Alambic/Plugins/Hudson/"
  or die "Cannot copy project_hudson_builds.csv.";
copy "t/resources/test.project_hudson_jobs.csv", "lib/Alambic/Plugins/Hudson/"
  or die "Cannot copy project_hudson_jobs.csv.";
copy "t/resources/test.project_hudson_main.csv", "lib/Alambic/Plugins/Hudson/"
  or die "Cannot copy project_hudson_main.csv.";
copy "t/resources/test.project_hudson_metrics.csv", "lib/Alambic/Plugins/Hudson/"
  or die "Cannot copy project_hudson_metrics.csv.";
$log
  = $tool->knit_rmarkdown_inc('Hudson', 'test.project', 'hudson.Rmd');
ok(grep(/^\[Tools::R\] Exec \[Rscript/, @{$log}), "Rscript is called in log.")
  or diag explain $log;
ok(-e 'projects/test.project/output/test.project_hudson.inc',
  "test.project_hudson.inc file is generated.")
  or diag explain $log;

#diag explain $log;

# Knit documents from the Hudson plugin
note("Executing Hudson Rmd figure file.");
$log = $tool->knit_rmarkdown_html('Hudson', 'test.project',
  'hudson_hist.rmd');
ok(grep(/^\[Tools::R\] Exec \[Rscript/, @{$log}), "Rscript is called in log.")
  or diag explain $log;
ok(-e 'projects/test.project/output/test.project_hudson_hist.html',
  "test.project_hudson_hist.html file is generated.")
  or diag explain $log;

$log = $tool->knit_rmarkdown_html('Hudson', 'test.project',
  'hudson_pie.rmd');
ok(grep(/^\[Tools::R\] Exec \[Rscript/, @{$log}), "Rscript is called in log.")
  or diag explain $log;
ok(-e 'projects/test.project/output/test.project_hudson_pie.html',
  "test.project_hudson_pie.html file is generated.")
  or diag explain $log;

# Remove files that were copied to tests
unlink "lib/Alambic/Plugins/Hudson/test.project_hudson_builds.csv";
unlink "lib/Alambic/Plugins/Hudson/test.project_hudson_jobs.csv";
unlink "lib/Alambic/Plugins/Hudson/test.project_hudson_main.csv";
unlink "lib/Alambic/Plugins/Hudson/test.project_hudson_metrics.csv";

# Knit documents from the PmdAnalysis plugin
note("Executing PMD Analysis R figure file.");
copy "t/resources/test.project_pmd_analysis_files.csv",
  "lib/Alambic/Plugins/PmdAnalysis/"
  or die "Cannot copy project_pmd_analysis_files.csv.";
$log = $tool->knit_rmarkdown_images('PmdAnalysis', 'test.project',
  'pmd_analysis_files_ncc1.r', ["pmd_analysis_files_ncc1.svg"]);
ok(grep(/^\[Tools::R\] Exec \[Rscript/, @{$log}), "Rscript is called in log.")
  or diag explain $log;
ok(-e 'projects/test.project/output/test.project_pmd_analysis_files_ncc1.svg',
  "pmd_analysis_files_ncc1.svg file is generated.")
  or diag explain $log;
unlink "lib/Alambic/Plugins/PmdAnalysis/test.project_pmd_analysis_files.csv";


done_testing();
