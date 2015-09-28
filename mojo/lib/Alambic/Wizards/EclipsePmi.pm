package Alambic::Plugins::DataSources::EclipsePmi;
use base 'Mojolicious::Plugin';

my %conf = {
    "id" => "eclipse_pmi",
    "desc" => "Retrieves data from the Eclipse PMI infrastructure.",
    "requires" => [
        "pmi_url",
        "pmi_id"
    ],
    "provides_metrics" => [
        "PMI_PLAN_3M"
    ],
    "provides_files" => [
        "pmi", % produces file project_pmi.json
    ],
    "provides_info" => [
        "name",
        "desc", 
    ]
};

sub register {
    my ($self, $app) = @_;

#    $app->helper(mypluginhelper =>
#                 sub { return 'I am your helper and I live in a plugin!'; });
    
}

sub get_conf() {
    return \%conf;
}

sub check_plugin() {

}

sub retrieve_data() {

}

sub compute_data() {

}

1;
