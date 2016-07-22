#! perl -I../../lib/

use strict;
use warnings;

use Test::More;

BEGIN { use_ok( 'Alambic::Tools::R' ); }

my $tool = Alambic::Tools::R->new();
isa_ok( $tool, 'Alambic::Tools::R' );

note( "Executing module self-test." );
my $log = $tool->test();
ok( grep( !/^ERROR/, @{$log} ), "Tool test() returns no ERROR" ) or diag explain $log;
ok( grep( /^OK: R exec found in PATH/, @{$log} ), "R bin is in path" ) or diag explain $log;
ok( grep( /^OK: Rscript exec found in PATH/, @{$log} ), "Rscript bin is in path" ) or diag explain $log;

# Knit documents from the EclipseIts plugin
note( "Executing EclipseIts Rmd file." );
$log = $tool->knit_rmarkdown_inc( 'EclipseIts', 'tools.cdt', 'EclipseIts.Rmd' );
ok( grep( /^\[Tools::R\] Exec \[Rscript/, @{$log} ), "Rscript is called in log." ) or diag explain $log;
ok( -e 'projects/tools.cdt/output/EclipseIts.inc', "EclipseIts.inc file is generated." ) or diag explain $log;
#diag explain $log;

# Knit documents from the EclipseIts plugin
note( "Executing EclipseIts Rmd figure file." );
$log = $tool->knit_rmarkdown_html( 'EclipseIts', 'tools.cdt', 'its_evol_changed.rmd' );
ok( grep( /^\[Tools::R\] Exec \[Rscript/, @{$log} ), "Rscript is called in log." ) or diag explain $log;
ok( -e 'projects/tools.cdt/output/its_evol_changed.html', "its_evol_changed.html file is generated." ) or diag explain $log;
#diag explain $log;


    
done_testing(9);
