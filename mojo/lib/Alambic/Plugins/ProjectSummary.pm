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
        "psum_attrs.html" => "A HTML snippet to display main quality attributes and their values.",
    },
    "provides_recs" => [
    ],
    "provides_viz" => {
        "badges.html" => "Badges",
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
    my $project = $conf->{'project'};
    my $qm = $project->get_qm($models->get_qm(), $models->get_attributes(), $models->get_metrics());
    my $run = $conf->{'last_run'};
    
    my $params = {
	"root.name" => $qm->[0]{"name"},
	"root.value" => $qm->[0]{"ind"},
    };
    # Add value of direct children of main quality attribute
    # i.e. should be product/process/ecosystem
    foreach my $c ( @{$qm->[0]{'children'}} ) {
	$params->{ $c->{'mnemo'} } = $c->{'ind'};
	$params->{ "QMN_" . $c->{'mnemo'} } = $c->{'name'};
    }
    
    # Create badges in output for root attribute
    my $badge = &_create_badge( 'alambic', $qm->[0]{"ind"} );
    $repofs->write_output( $project_id, "badge_attr_alambic.svg", $badge );
    $badge = &_create_badge( $qm->[0]{'name'}, $qm->[0]{'ind'} );
    $repofs->write_output( $project_id, "badge_attr_root.svg", $badge );

    my $psum_attrs = &_create_psum_attrs( $params );
    $repofs->write_output( $project_id, "psum_attrs.html", $psum_attrs );
					  
    
    # Foreach child of root attribute create a badge.
    foreach my $attr ( @{$qm->[0]{'children'}} ) {
	$badge = &_create_badge( $attr->{'name'}, $attr->{'ind'} );
	$repofs->write_output( $project_id, "badge_attr_" . $attr->{'name'} . ".svg", $badge );
    }
    
    # Execute the figures R scripts.
    my $r = Alambic::Tools::R->new();
#    push( @log, "[Plugins::ProjectSummary] Executing R snippet files." );
#    @log = ( @log, @{$r->knit_rmarkdown_html( 'ProjectSummary', $project_id, 'psum_attrs.rmd',
#					      [ ], $params )} );
    
    # Now generate the main html document.
    push( @log, "[Plugins::ProjectSummary] Executing R report." );
    $r = Alambic::Tools::R->new();
    @log = ( @log, @{$r->knit_rmarkdown_inc( 'ProjectSummary', $project_id, 'badges.Rmd' )} );

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

sub _create_psum_attrs() {
    my ($params) = @_;

    my $html = '<!DOCTYPE html>
    <html xmlns="http://www.w3.org/1999/xhtml">
    <head>

    <meta charset="utf-8">
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <meta name="generator" content="pandoc" />
    <body style=\'font-family: "arial"; font-color: #3E3F3A\'>';

    my $attr_root_name = $params->{'root.name'};
    my $attr_root_value = $params->{'root.value'};
    $html .= '<p><b><span style="font-weight: bold; font-size: 150%">' 
	. $attr_root_name 
	. ' &nbsp; <span style="font-weight: bold; font-size: 300%">' 
	. $attr_root_value . "</span></p>\n<p>";

    my @subattrs = sort grep( /^QM_.*/, keys %$params );
    my $subatttrs;
    foreach my $s (@subattrs) {
	$html .= '<span style="font-weight: bold; font-size: 150%">' . $params->{"QMN_" . $s} 
	    . ' &nbsp; ' . $params->{$s} . "</span><br />";
    }
    $html .= "</p></body></html>";
    
    return $html;
}


1;
