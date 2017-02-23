package Alambic::Plugins::ProjectSummary;

use strict; 
use warnings;

use Alambic::Tools::R;

use Mojo::UserAgent;
use Mojo::JSON qw( decode_json encode_json );
use Data::Dumper;

# Main configuration hash for the plugin
my %conf = (
    "id" => "ProjectSummary",
    "name" => "Project summary",
    "desc" => [ 
	"The Project Summary plugin creates a bunch of exportable HTML snippets and a PDF document.",
    ],
    "type" => "post",
    "ability" => [ 'figs', 'viz' ],
    "params" => {
    },
    "provides_cdata" => [
    ],
    "provides_info" => [
    ],
    "provides_data" => {
    },
    "provides_metrics" => {
    },
    "provides_figs" => {
	"badge_attr_alambic.svg" => "A badge to display current value of main quality attribute on an external web site (uses shields.io)",
        "project_summary.html" => "A HTML snippet to display main quality attributes and their values.",
    },
    "provides_recs" => [
    ],
    "provides_viz" => {
        "ProjectSummary.pdf" => "Project Summary PDF export.",
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
    
    my $repofs = Alambic::Model::RepoFS->new();
    my $models = $conf->{'models'};
#    print "Models: " . Dumper($models);
    my $project = $conf->{'project'};
    my $qm = $project->get_qm($models->get_qm(), $models->get_attributes(), $models->get_metrics());
#    print "Projects: " . Dumper($qm);
    my $run = $conf->{'last_run'};
#    print "Last run: " . Dumper($run);
    
    my $params = {
	"root.name" => $qm->[0]{"name"},
	"root.value" => $qm->[0]{"ind"},
    };

    # Create badges in output for root attribute
    my $badge = &_create_badge( 'alambic', $qm->[0]{"ind"} );
    $repofs->write_output( $project_id, "badge_attr_alambic.svg", $badge );
    $badge = &_create_badge( $qm->[0]{'name'}, $qm->[0]{'ind'} );
    $repofs->write_output( $project_id, "badge_attr_root.svg", $badge );
    
    # Foreach child of root attribute create a badge.
    foreach my $attr ( @{$qm->[0]{'children'}} ) {
	$badge = &_create_badge( $attr->{'name'}, $attr->{'ind'} );
	$repofs->write_output( $project_id, "badge_attr_" . $attr->{'name'} . ".svg", $badge );
    }
    
    # Execute the figures R scripts.
    my $r = Alambic::Tools::R->new();
    push( @log, "[Plugins::ProjectSummary] Executing R snippet files." );
    @log = ( @log, @{$r->knit_rmarkdown_html( 'ProjectSummary', $project_id, 'project_summary.rmd',
					      [ ], $params )} );
    
    # Now generate the PDF document.
    # push( @log, "[Plugins::ProjectSummary] Executing R report." );
    # my $r = Alambic::Tools::R->new();
    # @log = ( @log, @{$r->knit_rmarkdown_pdf( 'ProjectSummary', $project_id, 'ProjectSummary.Rmd' )} );

    return {
	"metrics" => {},
	"recs" => [],
	"info" => {},
	"log" => \@log,
    };
}

sub _create_badge() {
    my $name = shift;
    my $value = shift;

    my @colours = ( "red", "oragne", "yellow", "green", "brightgreen" );
    
    my $url = 'https://img.shields.io/badge/' . $name . '-' . $value . '%20%2F%205-' . $colours[int($value)] . '.svg';
    my $ua = Mojo::UserAgent->new;
    my $svg = $ua->get($url)->res->body;

    return $svg;
}


1;
