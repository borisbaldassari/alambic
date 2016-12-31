package Alambic::Plugins::EclipseReport;

use strict; 
use warnings;

use Alambic::Model::Project;
use Alambic::Model::RepoFS;
use Alambic::Tools::R;

use Mojo::JSON qw( decode_json encode_json );
use Data::Dumper;

# Main configuration hash for the plugin
my %conf = (
    "id" => "EclipseReport",
    "name" => "Eclipse Project Report",
    "desc" => [ 
	"Eclipse Project Report provides a PDF report on the project.",
    ],
    "type" => "post",
    "ability" => [ 'data', 'viz' ],
    "params" => {
    },
    "provides_cdata" => [
    ],
    "provides_info" => [
    ],
    "provides_data" => {
        "EclipseReport.pdf" => "A PDF report on the project's current status.",
    },
    "provides_metrics" => {
    },
    "provides_figs" => {
    },
    "provides_recs" => [
    ],
    "provides_viz" => {
    },
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
sub run_post($$) {
    my ($self, $project_id, $conf) = @_;

    my @log;
    # Write csv files for R report.
    my $repofs = Alambic::Model::RepoFS->new();
    my $project = $conf->{'project'};
    
    # Write main information for the project
    my $csv_out = "Mnemo,Value\n"; 
    $csv_out .= "last_run," . ( $project->{'main'}{'last_run'} || '' ) . "\n";
    foreach my $p ( sort keys %{$project->get_plugins()} ) {
	$csv_out .= "plugin," . $p . "\n";
    }
    push( @log, "[Plugins::EclipseReport] Writing main csv file to plugins and output directories." );
    $repofs->write_plugin( 'EclipseReport', $project_id . "_main.csv", $csv_out );
    $repofs->write_output( $project_id, "main.csv", $csv_out );

    # Write info information for the project
    $csv_out = "Mnemo,Value\n";
    foreach my $d (sort keys %{$project->info()} ) {
	$csv_out .= $d . "," . ( $project->info()->{$d} || '' ) . "\n";
    }
    push( @log, "[Plugins::EclipseReport] Writing info csv file to plugins and output directories." );
    $repofs->write_plugin( 'EclipseReport', $project_id . "_info.csv", $csv_out );
    $repofs->write_output( $project_id, "info.csv", $csv_out );

    # Write metrics information for the project
    $csv_out = "Mnemo,Value\n";
    foreach my $m (sort keys %{$project->metrics()} ) {
	$csv_out .= $m . "," . $project->metrics()->{$m} . "\n";
    }
    push( @log, "[Plugins::EclipseReport] Writing metrics csv file to plugins and output directories." );
    $repofs->write_plugin( 'EclipseReport', $project_id . "_metrics.csv", $csv_out );
    $repofs->write_output( $project_id, "metrics.csv", $csv_out );

    # Write attributes information for the project
    $csv_out = "Mnemo,Value\n";
    foreach my $m (sort keys %{$project->attributes()} ) {
	$csv_out .= $m . "," . $project->attributes()->{$m} . "\n";
    }
    push( @log, "[Plugins::EclipseReport] Writing attributes csv file to plugins and output directories." );
    $repofs->write_plugin( 'EclipseReport', $project_id . "_attributes.csv", $csv_out );
    $repofs->write_output($project_id,  "attributes.csv", $csv_out );

    # Write recs information for the project
    $csv_out = "Mnemo,Severity,Description\n";
    print "# EclipseReport " . Dumper($project->recs());
    foreach my $m (sort @{$project->recs()} ) {
	$csv_out .= $m->{'rid'} . "," . ( $m->{'severity'} || 0 )
	. ",\"" . ( $m->{'desc'} || '' ) . "\"\n";
    }
    push( @log, "[Plugins::EclipseReport] Writing recs csv file to plugins and output directories." );
    $repofs->write_plugin( 'EclipseReport', $project_id . "_recs.csv", $csv_out );
    $repofs->write_output( $project_id, "recs.csv", $csv_out );

    # Now execute the main R script.
    push( @log, "[Plugins::EclipseReport] Executing R report." );
    my $r = Alambic::Tools::R->new();
    @log = ( @log, @{$r->knit_rmarkdown_pdf( 'EclipseReport', $project_id, 'EclipseReport.Rmd' )} );
    
    return \@log;
}


1;
