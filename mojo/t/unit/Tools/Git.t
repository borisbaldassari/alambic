#! perl -I../../lib/

use strict;
use warnings;

use Test::More;
use Data::Dumper;
use File::Path qw( remove_tree );

BEGIN { use_ok( 'Alambic::Tools::Git' ); }

my $tool = Alambic::Tools::Git->new();
isa_ok( $tool, 'Alambic::Tools::Git' );

my $version = $tool->version();
ok( $version =~ /^git version/, "Tool version returns git version xxx" ) or diag explain $version;

note( "Executing module self-test." );
my $log = $tool->test();
ok( grep( !/^ERROR/, @{$log} ), "Tool test() returns no ERROR" ) or diag explain $log;
ok( grep( /^OK: Git exec found/, @{$log} ), "Git bin is in path" ) or diag explain $log;

# Create repo for test project 
note( "Cloning Alambic." );
my $exec_cloning = 0;
my $dir_src = "projects/test.project/";
# Remove existing src directory
if (-d $dir_src && $exec_cloning) {
    my $removed_count = remove_tree( $dir_src, {error => \my $err} );
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
    $log = $tool->git_clone( 'Test', 'test.project', 
			     'https://BorisBaldassari@bitbucket.org/BorisBaldassari/alambic.git' );
    ok( grep( /^\[Tools::Git\] Cloning /, @{$log} ), "Log has Ok cloning." ) or diag explain $log;
    ok( -e $dir_src, "Source directory exists after cloning." ) or diag explain $log;
}
#diag explain $log;

$log = $tool->git_log( 'Test', 'test.project' );
print "log " . Dumper($log);

#$log = $tool->git_update( 'Test', 'test.project' );
#print "update " . Dumper($log);

# Knit documents from the EclipseIts plugin
##note( "Executing EclipseIts Rmd figure file." );#
#$log = $tool->knit_rmarkdown_html( 'EclipseIts', 'tools.cdt', 'its_evol_changed.rmd' );
#ok( grep( /^\[Tools::R\] Exec \[Rscript/, @{$log} ), "Rscript is called in log." ) or diag explain $log;
#ok( -e 'projects/tools.cdt/output/its_evol_changed.html', "its_evol_changed.html file is generated." ) or diag explain $log;
#diag explain $log;


    
done_testing(9);
