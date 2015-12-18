package Alambic::Plugins::StackOverflow;
use base 'Mojolicious::Plugin';

use Mojo::JSON qw( decode_json encode_json );
use Mojo::UserAgent;
use Data::Dumper;


my %conf = (
    "id" => "stack_overflow",
    "name" => "Stack Overflow metrics",
    "desc" => "Retrieves data from Stack Overflow.",
    "ability" => [
        "metrics",
        "viz",
    ],
    "requires" => {
        "bin_r" => "",
        "so_keyword" => "",
    },
    "provides_metrics" => {
    },
    "provides_files" => [
    ],
    "provides_viz" => [
        "stack_overflow",
    ],
);

my $app;

sub register {
    my $self = shift;
    $app = shift;

}

sub get_conf() {
    return \%conf;
}

sub check_plugin() {

}

sub check_project() {

}

sub retrieve_data() {
    my $self = shift;
    my $project_id = shift;
    
    my @log;

    my $url = 'https://api.stackexchange.com/2.2/';

    my $content_json;
    my %final_json;
    
    my ( $quota_max, $quota_remaining );
    
    my $continue = 10;
    my $page = 1;
    
    while ($continue) {
        my $url_question = $url . "questions?order=desc&sort=activity&site=stackoverflow&tagged=" . 
            $tag . "&pagesize=100&page=" . $page;
        
        $app->log->info( "Fetching $url_question." );
        
        # Fetch JSON data from SO
        my $ua = Mojo::UserAgent->new;
        $content_json = $ua->get($url_question)->res->body;
        
        # Check if there are other pages.
        my $content = decode_json( $content_json );
        
        foreach my $item ( @{$content->{'items'} } ) {
            $final_json{'items'}{ $item->{'question_id'} } = $item;
        }
        
        $page++;
        
        # Check if there are other pages.
        if ( $content->{'has_more'} ) {
            $continue--;
        } else {
            $continue = 0;
        }
        
        $quota_max = $content->{'quota_max'};
        $quota_remaining = $content->{'quota_remaining'};
    }
    
    my $json_out = encode_json( \%final_json );
    
    my $file_out = $app->config->{'dir_input'} . "/" . $project_id . "/" . $project_id . "_so.json";
    $app->log->info( "Writing Final json to $file_out." );
    open my $fh, ">$file_out" or die "Could not open $file_out.\n";
    print $fh $json_out;
    close $fh;
    
    $app->log->info( "Quota: remaining $quota_remaining out of $quota_max." );

    return \@log;
}

sub compute_data() {

    return ["Done."];
}

1;
