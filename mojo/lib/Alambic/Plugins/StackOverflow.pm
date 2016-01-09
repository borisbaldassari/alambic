package Alambic::Plugins::StackOverflow;
use base 'Mojolicious::Plugin';

use strict;
use warnings;

use Mojo::JSON qw( decode_json encode_json );
use Mojo::UserAgent;
use Data::Dumper;
use File::Copy;
use File::Path qw(remove_tree);
use DateTime;

my %conf = (
    "id" => "stack_overflow",
    "name" => "Stack Overflow metrics",
    "desc" => "Retrieves data from Stack Overflow by using a provided tag, during the last 5 years.",
    "ability" => [
        "metrics",
        "viz",
    ],
    "requires" => {
        "bin_r" => "/usr/bin/R",
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
    my $project_conf = $app->projects->get_project_info($project_id)->{'ds'}->{'stack_overflow'};
    my $tag = $project_conf->{'so_keyword'};

    my $date_now = DateTime->now( time_zone => 'local' );
    my $date_before = DateTime->now( time_zone => 'local' )->subtract( years => 5 );
    my $date_before_ok = $date_before->strftime("%Y-%m-%d");

    my $content_json;
    my %final_json;
    
    my ( $quota_max, $quota_remaining );
    
    my $continue = 50;
    my $page = 1;
    
    while ($continue) {
        my $url_question = $url . "questions?order=desc&sort=activity&site=stackoverflow" 
            . "&tagged=" . $tag . "&fromdate=${date_before_ok}"
            . "&pagesize=100&page=" . $page;
        
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
    my @items = keys %{$final_json{'items'}};
    push( @log, "Fetched data from SO. Got " . scalar @items . " items." );
    
    my $json_out = encode_json( \%final_json );
    
    my $file_out = $app->config->{'dir_input'} . "/" . $project_id . "/" . $project_id . "_so.json";
    $app->log->info( "Writing Final json to $file_out." );
    open my $fh, ">$file_out" or die "Could not open $file_out.\n";
    print $fh $json_out;
    close $fh;
    
    $app->log->info( "Quota: remaining $quota_remaining out of $quota_max." );
    push( @log, "Quota: remaining $quota_remaining out of $quota_max." );

    return \@log;
}

sub compute_data() {
    my $self = shift;
    my $project_id = shift;
    
    my $file_json = $app->config->{'dir_input'} . "/" . $project_id . "/" . $project_id . "_so.json";

    my $date_now = DateTime->now( time_zone => 'local' );
    my $date_before = DateTime->now( time_zone => 'local' )->subtract( years => 5 );
    my $date_before_ok = $date_before->strftime("%Y-%m-%d");
    my $project_conf = $app->projects->get_project_info($project_id)->{'ds'}->{'stack_overflow'};
    my $project_tag = $project_conf->{'so_keyword'};

    my $content_json;
    open( my $fh, '<', $file_json) or die "Could not open $file_json.\n";
    while (<$fh>) {
        $content_json .= $_;
    }
    my $content = decode_json( $content_json );

    my $csv_out = "id,views,score,creation_date,last_activity_date,answer_count,is_answered,title\n";;
    foreach my $id ( sort keys %{$content->{'items'}} ) {
        my $views = $content->{'items'}->{$id}->{'view_count'};
        my $score = $content->{'items'}->{$id}->{'score'};
        my $creation_date = $content->{'items'}->{$id}->{'creation_date'};
        my $last_activity_date = $content->{'items'}->{$id}->{'last_activity_date'};
        my $answer_count = $content->{'items'}->{$id}->{'answer_count'};
        my $is_answered = $content->{'items'}->{$id}->{'is_answered'};
        my $title = $content->{'items'}->{$id}->{'title'};
        $title =~ s!,!!g;    
        
        $csv_out .= "$id,$views,$score,$creation_date,$last_activity_date,$answer_count,$is_answered,$title\n";
    }

    my $file_csv = $app->home->rel_dir('lib') . "/Alambic/Plugins/StackOverflow/" . $project_id . "_so.csv";
        #$app->config->{'dir_input'} . "/" . $project_id . "/" . $project_id . "_so.csv";
    open($fh, '>', $file_csv) or die "Could not open file '$file_csv' $!";
    print $fh $csv_out;
    close $fh;
    
    my $r_dir = $app->home->rel_dir('lib') . "/Alambic/Plugins/StackOverflow/";
    my $r_html = "StackOverflow.Rhtml";
    my $r_html_out = "${project_id}_stack_overflow.inc";

    chdir $r_dir;
    $app->log->info( "Executing R script [$r_html] in [$r_dir] with [$project_id] [$file_csv]." );
    $app->log->info( "Result to be stored in [$r_html_out]." );

    # TODO Use $app->projects->get_project_info($project_id)->{'ds'}->{'stack_overflow'}->{'r_bin'};
    # to get r bin path.
    my $r_cmd = "Rscript -e \"library(knitr); " 
        . "project.id <- '${project_id}'; plugin.id <- 'stack_overflow'; file.csv <- '${project_id}_so.csv'; "
        . "project.tag <- '${project_tag}'; date.now <- '$date_now'; date.before <- '$date_before'; "
        . "knit('${r_html}', output='${r_html_out}')\"";

    $app->log->info( "Exec [$r_cmd]." );
    my @out = `$r_cmd`;
    print @out;

    my $dir_out = $app->config->{'dir_input'} . "/" . $project_id . "/";

    # Create dir for figures.
    if (! -d "${dir_out}/figures/" ) {
        print "Creating directory [${dir_out}/figures/].\n";
        mkdir "${dir_out}/figures/";
    }

    # Now move files to data/project
    move( "${r_html_out}", $dir_out );
    my $dir_out_fig = $app->config->{'dir_input'} . "/" . $project_id . "/figures/stack_overflow/";
    if ( -e $dir_out_fig ) {
        print "Target directory [$dir_out_fig] exists. Removing it.\n";
        my $ret = remove_tree($dir_out_fig, {verbose => 1});
    }
    my $ret = move('figures/stack_overflow/' . $project_id . '/', $dir_out_fig);
    $app->log->info( "Moved files from ${r_dir}/figures to $dir_out_fig. ret $ret." );
    
    # Remove csv file
#    unlink $file_csv;

    return ["Done."];
}

1;
