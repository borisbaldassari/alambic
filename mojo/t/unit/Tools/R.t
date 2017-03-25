#! perl -I../../lib/

use strict;
use warnings;

use File::Path qw(make_path remove_tree);
use Test::More;
use File::Copy;

BEGIN { use_ok( 'Alambic::Tools::R' ); }

my $tool = Alambic::Tools::R->new();
isa_ok( $tool, 'Alambic::Tools::R' );

note( "Executing module self-test." );
my $log = $tool->test();
ok( grep( !/^ERROR/, @{$log} ), "Tool test() returns no ERROR" ) or diag explain $log;
ok( grep( /^OK: R exec found in PATH/, @{$log} ), "R bin is in path" ) or diag explain $log;
ok( grep( /^OK: Rscript exec found in PATH/, @{$log} ), "Rscript bin is in path" ) or diag explain $log;

# Create output dir for test.project
make_path( 'projects/test.project/output/' );

# Knit documents from the EclipseIts plugin
note( "Executing EclipseIts Rmd file." );
copy "t/resources/test.project_its.csv", "lib/Alambic/Plugins/EclipseIts/" 
    or die "Cannot copy project_its.csv.";
copy "t/resources/test.project_its_evol.csv", "lib/Alambic/Plugins/EclipseIts/" 
    or die "Cannot copy project_its_evol.csv.";
$log = $tool->knit_rmarkdown_inc( 'EclipseIts', 'test.project', 'eclipse_its.Rmd' );
ok( grep( /^\[Tools::R\] Exec \[Rscript/, @{$log} ), "Rscript is called in log." ) or diag explain $log;
ok( -e 'projects/test.project/output/test.project_eclipse_its.inc', "eclipse_its.inc file is generated." ) or diag explain $log;
#diag explain $log;

# Knit documents from the EclipseIts plugin
note( "Executing EclipseIts Rmd figure file." );
$log = $tool->knit_rmarkdown_html( 'EclipseIts', 'test.project', 'its_evol_changed.rmd' );
ok( grep( /^\[Tools::R\] Exec \[Rscript/, @{$log} ), "Rscript is called in log." ) or diag explain $log;
ok( -e 'projects/test.project/output/test.project_its_evol_changed.html', "its_evol_changed.html file is generated." ) or diag explain $log;

$log = $tool->knit_rmarkdown_html( 'EclipseIts', 'test.project', 'its_evol_summary.rmd' );
ok( grep( /^\[Tools::R\] Exec \[Rscript/, @{$log} ), "Rscript is called in log." ) or diag explain $log;
ok( -e 'projects/test.project/output/test.project_its_evol_summary.html', "its_evol_summary.html file is generated." ) or diag explain $log;

# Remove files that were copied to tests
unlink "lib/Alambic/Plugins/EclipseIts/test.project_its.csv";
unlink "lib/Alambic/Plugins/EclipseIts/test.project_its_evol.csv";

# Knit documents from the EclipseIts plugin
note( "Executing PMD Analysis R figure file." );
copy "t/resources/test.project_pmd_analysis_files.csv", "lib/Alambic/Plugins/PmdAnalysis/" 
    or die "Cannot copy project_pmd_analysis_files.csv.";
$log = $tool->knit_rmarkdown_images( 'PmdAnalysis', 'test.project', 'pmd_analysis_files_ncc1.r', [ "pmd_analysis_files_ncc1.svg" ] );
ok( grep( /^\[Tools::R\] Exec \[Rscript/, @{$log} ), "Rscript is called in log." ) or diag explain $log;
ok( -e 'projects/test.project/output/test.project_pmd_analysis_files_ncc1.svg', "pmd_analysis_files_ncc1.svg file is generated." ) or diag explain $log;
unlink "lib/Alambic/Plugins/PmdAnalysis/test.project_pmd_analysis_files.csv";

    
done_testing();
