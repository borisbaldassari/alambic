package Alambic::Plugins::Comments;

use strict; 
use warnings;

#use Alambic::Model::RepoFS;
#use Alambic::Tools::R;

use Mojo::JSON qw( decode_json encode_json );
use Data::Dumper;


# Main configuration hash for the plugin
my %conf = (
    "id" => "Comments",
    "name" => "Comments",
    "desc" => [
	'The Comments plugin allows users to add free text comments to their projects.',
    ],
    "type" => "cdata",
    "ability" => [ 'metrics', 'viz' ],
    "params" => {
    },
    "provides_cdata" => {
	"COMMENTS" => "Add free text comments to the project.",
    },
    "provides_info" => [
    ],
    "provides_data" => {
	"comments.json" => "The list of comments for the project (JSON).",
    },
    "provides_metrics" => {
        "COMMENTS_RATE" => "COMMENTS_RATE", 
    },
    "provides_figs" => {
        'comments_pie.rmd' => "comments_pie.html",
    },
    "provides_recs" => [
    ],
    "provides_viz" => {
        "Comments" => "Comments",
    },
    "cdata" => [
      { 
        "id" => "licence",
        "name" => "Licence used",
        "type" => "select",
        "desc" => "What is the licence used for the project?",
        "choices" => [
          "GPL",
          "LGPL",
          "EPL",
        ],
      },
      # { 
      #   "id" => "team_size",
      #   "name" => "Size of the team",
      #   "type" => "number",
      #   "desc" => "Number of people in the team.",
      # }
    ]
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
sub run_plugin($$) {
    my ($self, $project_id, $conf) = @_;

    my %ret = (
#	'cdata' => 
	'metrics' => {},
	'info' => {},
	'recs' => {},
	'log' => [],
	);

    my $repofs = Alambic::Model::RepoFS->new();

    my $project_grim = $conf->{'project_grim'};

    push ( @{$ret{'log'}}, "TODO: Computing metrics for comments." );
        
    return \%ret;
}



1;
