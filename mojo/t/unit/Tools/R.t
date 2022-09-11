#! perl -I../../lib/
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


use strict;
use warnings;

use Data::Dumper;

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
make_path('projects/modeling.sirius/output/');

# Knit documents from the Git plugin
note("Executing Git Rmd file.");
copy "t/resources/modeling.sirius_metrics.csv", "projects/modeling.sirius/output/"
  or die "Cannot copy modeling.sirius_metrics.csv.";
copy "t/resources/modeling.sirius_git_commits.csv", "projects/modeling.sirius/output/"
  or die "Cannot copy modeling.sirius_git_commits.csv.";
$log = $tool->knit_rmarkdown_inc('Git', 'modeling.sirius', 'git_scm.Rmd');
ok(grep(/^\[Tools::R\] Exec \[Rscript/, @{$log}), "Rscript is called in log.")
  or diag explain $log;
ok(-e 'projects/modeling.sirius/output/modeling.sirius_git_scm.inc',
  "modeling.sirius_git_scm.inc file is generated.")
  or diag explain $log;
unlink "projects/modeling.sirius/output/modeling.sirius_git_scm.inc";

# Knit documents from the Git plugin
note("Executing Git Rmd figure files.");
$log = $tool->knit_rmarkdown_html('Git', 'modeling.sirius', 'git_evol_commits.rmd');
ok(grep(/^\[Tools::R\] Exec \[Rscript/, @{$log}), "Rscript is called in log.")
  or diag explain $log;
ok(-e 'projects/modeling.sirius/output/modeling.sirius_git_evol_commits.html',
  "modeling.sirius_git_evol_commits.html file is generated.") or diag explain $log;
unlink "projects/modeling.sirius/output/modeling.sirius_git_evol_commits.html";

$log = $tool->knit_rmarkdown_html('Git', 'modeling.sirius', 'git_evol_authors.rmd');
ok(grep(/^\[Tools::R\] Exec \[Rscript/, @{$log}), "Rscript is called in log.")
  or diag explain $log;
ok(-e 'projects/modeling.sirius/output/modeling.sirius_git_evol_authors.html',
  "modeling.sirius_git_evol_authors.html file is generated.") or diag explain $log;
unlink "projects/modeling.sirius/output/modeling.sirius_git_evol_authors.html";

$log = $tool->knit_rmarkdown_html('Git', 'modeling.sirius', 'git_evol_summary.rmd');
ok(grep(/^\[Tools::R\] Exec \[Rscript/, @{$log}), "Rscript is called in log.")
  or diag explain $log;
ok(-e 'projects/modeling.sirius/output/modeling.sirius_git_evol_summary.html',
  "modeling.sirius_git_evol_summary.html file is generated.") or diag explain $log;
unlink "projects/modeling.sirius/output/modeling.sirius_git_evol_summary.html";

# Remove files that were copied to tests
unlink "projects/modeling.sirius/output/modeling.sirius_metrics.csv";
unlink "projects/modeling.sirius/output/modeling.sirius_git_commits.csv";


done_testing();
