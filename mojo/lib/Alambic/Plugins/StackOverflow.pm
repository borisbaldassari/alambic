package Alambic::Plugins::StackOverflow;
use base 'Mojolicious::Plugin';

my %conf = (
    "id" => "stack_overflow",
    "name" => "Stack Overflow metrics",
    "desc" => "Retrieves data from Stack Overflow.",
    "ability" => [
        "metrics",
        "viz",
    ],
    "requires" => {
        "so_url" => "",
        "project_id" => "",
    },
    "provides_metrics" => [
        "SO_PLAN_3M"
    ],
    "provides_files" => [
    ],
    "provides_info" => [
        "name",
        "desc", 
    ]
);

sub register {
    my ($self, $app) = @_;

#    $app->helper(mypluginhelper =>
#                 sub { return 'I am your helper and I live in a plugin!'; });
    
}

sub get_conf() {
    return \%conf;
}

sub check_plugin_data() {

}

sub retrieve_data() {

}

sub compute_data() {

}

1;
