package Alambic::Plugins::PmiChecks;
use base 'Mojolicious::Plugin';

use strict;
use warnings;

use Mojo::JSON qw( decode_json encode_json );
use Mojo::UserAgent;
use Data::Dumper;
use File::Path qw(remove_tree);
use Date::Parse;
use Mojolicious::Renderer;

my %conf = (
    "id" => "pmi_checks",
    "name" => "PMI Checks",
    "desc" => "Retrieves PMI information and applies a series of test to make sure that the repository is correctly filled.",
    "ability" => [
        "viz",
    ],
    "requires" => {
        "project_id" => "",
    },
    "provides_metrics" => {
    },
    "provides_files" => [
    ],
    "provides_viz" => [
        "pmi_checks",
    ],
);

my $eclipse_url = "http://projects.eclipse.org/json/project/";
my $polarsys_url = "http://polarsys.org/json/project/";

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
    
    my $project_conf = $app->projects->get_project_info($project_id)->{'ds'}->{$self->get_conf->{'id'}};
    my $project_pmi = $project_conf->{'project_id'};
    
    my @log;

    my $ua = Mojo::UserAgent->new;

    # Fetch json file from projects.eclipse.org
    my ($url, $content);
    if ($project_pmi =~ m!^polarsys!) {
        $url = $polarsys_url . $project_pmi;
        push( @log, "Using PolarSys PMI infra at [$url]." );
        $content = $ua->get($url)->res->body;
    } else {
        $url = $eclipse_url . $project_pmi;
        push( @log, "Using Eclipse PMI infra at [$url]." );
        $content = $ua->get($url)->res->body;
    }

    my $pmi = decode_json($content);
    my $custom_pmi;
    if ( defined($pmi->{'projects'}->{$project_pmi}) ) {
        $custom_pmi = $pmi->{'projects'}->{$project_pmi};
    } else {
        my $msg_failed = [ "ERROR: Could not get [$url]!" ];
        return $msg_failed unless defined $content;
    }
    
    my $file_json_out = $app->config->{'dir_input'} . "/" . $project_id . "/" . $project_id . "_import_pmi_checks.json";

    $app->log->debug("[Plugins::PmiChecks] Writing PMI json file to [$file_json_out].");
    open my $fh, ">", $file_json_out;
    print $fh encode_json($custom_pmi);
    close $fh;

    return \@log;
}

sub compute_data() {
    my $self = shift;
    my $project_id = shift;
    
    my $project_conf = $app->projects->get_project_info($project_id)->{'ds'}->{$self->get_conf->{'id'}};
    my $project_pmi = $project_conf->{'project_id'};

    # Fetch json file from projects.eclipse.org
    my $url;
    if ($project_pmi =~ m!^polarsys!) {
        $url = $polarsys_url . $project_pmi;
    } else {
        $url = $eclipse_url . $project_pmi;
    }

    # Read data from pmi file in $data_input
    my $json; 
    my $file = $app->config->{'dir_input'} . "/" . $project_id . "/" . $project_id . "_import_pmi_checks.json";
    my $msg_failed = [ "Could not open data file [$file]." ];
    do { 
        local $/;
        open my $fh, '<', $file or return $msg_failed;
        $json = <$fh>;
        close $fh;
    };

    # Decode the entire JSON
    my $raw_project = decode_json( $json );
    $raw_project->{'pmi_url'} = $url;
    my $ret_checks = &_check_pmi($project_id, $raw_project);

    my $renderer = Mojolicious::Renderer->new;
    my ($output, $format) = $renderer->render(Mojolicious::Controller->new, {
        template => 'alambic/plugins/pmi_checks',
        project => $ret_checks
    });

    # Write data to file.
    $json = encode_json($ret_checks);
    my $file_project = $app->config->{'dir_input'} . "/" . $project_id . "/" . $project_id . "_pmi_checks.json";
    open( my $fh, '>', $file_project) or die "Cannot open file [$file_project] to add/write project.\n";
    print $fh $json;
    close $fh;
    
    return ["Done."];
}

sub _check_pmi() {
    my $project_id = shift;
    my $raw_project = shift;
        
    my $ret_check;
    $ret_check->{'pmi'} = $raw_project;
    $ret_check->{'id'} = $project_id;
    $ret_check->{'pmi_url'} = $raw_project->{'pmi_url'};
    $ret_check->{'name'} = $raw_project->{'title'};
    $ret_check->{'last_update'} = time();
    
    my $ua = Mojo::UserAgent->new;
    
    # Test title
    my $proj_name = $raw_project->{'title'};
    my $check;
    $check->{'value'} = $proj_name;
    $check->{'result'} = ($proj_name !~ m!^\s*$!) ? 'OK' : 'Failed: no title defined.'; 
    $check->{'desc'} = 'Checks if a name is defined for the project: !~ m!^\s*$!';
    $ret_check->{'checks'}->{'title'} = $check;
    
    # Test Web site
    $check = {};
    $check->{'results'} = [];
    $check->{'desc'} = 'Checks if the URL can be fetched using a simple get query.';
    my $url;
    if ( exists($raw_project->{'website_url'}->[0]->{'url'}) ) {
        $url = $raw_project->{'website_url'}->[0]->{"url"};
        $check->{'value'} = $url;
        push( @{$check->{'results'}}, &_check_url($url, 'Website') );
    } else {
        push( @{$check->{'results'}}, "Failed: no URL defined for website_url.");
    }
    $ret_check->{'checks'}->{'website_url'} = $check;
    
    # Test Wiki
    $check = {};
    $check->{'results'} = [];
    $check->{'desc'} = "Sends a get request to the project wiki URL and looks at the headers in the response (200, 404..).";
    if ( exists($raw_project->{'wiki_url'}->[0]->{'url'}) ) {
        $url = $raw_project->{'wiki_url'}->[0]->{'url'};
        $check->{'value'} = $url;
        push( @{$check->{'results'}}, &_check_url($url, 'Wiki') );
    } else {
        push( @{$check->{'results'}}, "Failed: no URL defined for wiki_url.");
    }
    $ret_check->{'checks'}->{'wiki_url'} = $check;
    
    # Test Bugzilla create url
    $check = {};
    $check->{'results'} = [];
    $check->{'desc'} = 'Checks if the URL can be fetched using a simple get query.';
    if ( exists($raw_project->{'bugzilla'}->[0]->{'create_url'}) ) {
        $url = $raw_project->{'bugzilla'}->[0]->{'create_url'};
        $check->{'value'} = $url;
        push( @{$check->{'results'}}, &_check_url($url, 'Create') );
    } else {
        push( @{$check->{'results'}}, "Failed: no URL defined for create_url.");
    }
    $ret_check->{'checks'}->{'bugzilla_create_url'} = $check;
    
    # Test Bugzilla query url
    $check = {};
    $check->{'results'} = [];
    $check->{'desc'} = 'Checks if the URL can be fetched using a simple get query.';
    if ( exists($raw_project->{'bugzilla'}->[0]->{'query_url'}) ) {
        $url = $raw_project->{'bugzilla'}->[0]->{'query_url'};
        $check->{'value'} = $url;
        push( @{$check->{'results'}}, &_check_url($url, 'Query') );
    } else {
        push( @{$check->{'results'}}, "Failed: no URL defined for query_url.");
    }
    $ret_check->{'checks'}->{'bugzilla_query_url'} = $check;
    
    # Test Download url
    $check = {};
    $check->{'results'} = [];
    $check->{'desc'} = 'Checks if the URL can be fetched using a simple get query.';
    if ( exists($raw_project->{'download_url'}->[0]->{'url'}) ) {
        $url = $raw_project->{'download_url'}->[0]->{'url'};
        $check->{'value'} = $url;
        push( @{$check->{'results'}}, &_check_url($url, 'Download') );
    } else {
        push( @{$check->{'results'}}, "Failed: no URL defined for download_url.");
    }
    $ret_check->{'checks'}->{'download_url'} = $check;
    
    # Test Getting started url
    $check = {};
    $check->{'results'} = [];
    $check->{'desc'} = 'Checks if the URL can be fetched using a simple get query.';
    if ( exists($raw_project->{'gettingstarted_url'}->[0]->{'url'}) ) {
        $url = $raw_project->{'gettingstarted_url'}->[0]->{'url'};
        $check->{'value'} = $url;
        push( @{$check->{'results'}}, &_check_url($url, 'Documentation') );
    } else {
        push( @{$check->{'results'}}, "Failed: no URL defined for gettingstarted_url.");
    }
    $ret_check->{'checks'}->{'gettingstarted_url'} = $check;
    
    # Test Documentation url
    $check = {};
    $check->{'results'} = [];
    $check->{'desc'} = 'Checks if the URL can be fetched using a simple get query.';
    if ( exists($raw_project->{'documentation_url'}->[0]->{'url'}) ) {
        $url = $raw_project->{'documentation_url'}->[0]->{'url'};
        $check->{'value'} = $url;
        push( @{$check->{'results'}}, &_check_url($url, 'Documentation') );
    } else {
        push( @{$check->{'results'}}, "Failed: no URL defined for documentation_url.");
    }
    $ret_check->{'checks'}->{'documentation_url'} = $check;
    
    # Test plan url
    $check = {};
    $check->{'results'} = [];
    $check->{'desc'} = 'Checks if the URL can be fetched using a simple get query.';
    if ( exists($raw_project->{'plan_url'}->[0]->{'url'}) ) {
        $url = $raw_project->{'plan_url'}->[0]->{'url'};
        $check->{'value'} = $url;
        push( @{$check->{'results'}}, &_check_url($url, 'Plan') );
    } else {
        push( @{$check->{'results'}}, "Failed: no URL defined for plan.");
    }
    $ret_check->{'checks'}->{'plan_url'} = $check;
    
    # Test proposal url
    $check = {};
    $check->{'results'} = [];
    $check->{'desc'} = 'Checks if the URL can be fetched using a simple get query.';
    if ( exists($raw_project->{'proposal_url'}->[0]->{'url'}) ) {
        $url = $raw_project->{'proposal_url'}->[0]->{'url'};
        $check->{'value'} = $url;
        push( @{$check->{'results'}}, &_check_url($url, 'Proposal') );
    } else {
        push( @{$check->{'results'}}, "Failed: no URL defined for proposal.");
    }
    $ret_check->{'checks'}->{'proposal_url'} = $check;
    
    # Test dev_list url
    $check = {};
    $check->{'results'} = [];
    $check->{'desc'} = 'Checks if the Dev ML URL can be fetched using a simple get query.';
    if ( ref($raw_project->{'dev_list'}) =~ m!HASH! ) {
        $url = $raw_project->{'dev_list'}->{'url'};
        $check->{'value'} = $url;
        push( @{$check->{'results'}}, &_check_url($url, 'Dev ML') );
    } else {
        push( @{$check->{'results'}}, 'Failed: no dev mailing list defined.' );
    }
    $ret_check->{'checks'}->{'dev_list'} = $check;
    
    # Test mailing_lists
    $check = {};
    $check->{'results'} = [];
    $check->{'desc'} = 'Checks if the Dev ML URL can be fetched using a simple get query.';
    my @mls = @{$raw_project->{'mailing_lists'}};
    if (scalar @mls > 0) {
        foreach my $ml (@mls) {
            $url = $ml->{'url'};
            my $name = $ml->{'name'};
            my $email = $ml->{'email'};
            $check->{'value'} = $url;
            if ($email =~ m!.+@.+!) {
                push( @{$check->{'results'}}, "OK. [$name] ML correctly defined with email." );
            } else {
                push( @{$check->{'results'}}, "Failed: no email defined on [$name] ML .")
            }
            push( @{$check->{'results'}}, &_check_url($url, "[$name] ML") );
        }
    } else {
        push( @{$check->{'results'}}, 'Failed: no mailing list defined.' );
    }
    $ret_check->{'checks'}->{'mailing_lists'} = $check;
    
    # Test forums
    $check = {};
    $check->{'results'} = [];
    $check->{'desc'} = 'Checks if the Forums URL can be fetched using a simple get query.';
    @mls = @{$raw_project->{'forums'}};
    if (scalar @mls > 0) {
        foreach my $ml (@mls) {
            $url = $ml->{'url'};
            my $name = $ml->{'name'};
            $check->{'value'} = $url;
            if ($name =~ m!\S+!) {
                push( @{$check->{'results'}}, "OK. Forum [$name] correctly defined." );
            } else {
                push( @{$check->{'results'}}, "Failed: no name defined on forum.")
            }
            push( @{$check->{'results'}}, &_check_url($url, "Forum [$name]") );
        }
    } else {
        push( @{$check->{'results'}}, 'Failed: no forums defined.' );
    }
    $ret_check->{'checks'}->{'forums'} = $check;
    
    # Test source_repos
    $check = {};
    $check->{'results'} = [];
    $check->{'desc'} = 'Checks if the Source repositories are filled and can be fetched using a simple get query.';
    my @src = @{$raw_project->{'source_repo'}};
    if (scalar @src > 0) {
        foreach my $ml (@src) {
            $url = $ml->{'url'};
            my $name = $ml->{'name'};
            my $path = $ml->{'path'};
            my $type = $ml->{'type'};
            $check->{'value'} = $url;
            if ($path =~ m!.+$! ) {
                push( @{$check->{'results'}}, "OK. Source repo [$name] type [$type] path [$path]." );
            } else {
                push( @{$check->{'results'}}, "Failed. Source repo [$name] bad type [$type] or path [$path].");
            }
            push( @{$check->{'results'}}, &_check_url($url, "Source repo [$name]") );
        }
    } else {
        push( @{$check->{'results'}}, 'Failed. No source repo defined.' );
    }
    $ret_check->{'checks'}->{'source_repo'} = $check;
    
    # Test update_sites
    $check = {};
    $check->{'results'} = [];
    $check->{'desc'} = 'Checks if the update sites can be fetched using a simple get query.';
    my @ups = @{$raw_project->{'update_sites'}};
    if (scalar @ups > 0) {
        foreach my $us (@ups) {
            $url = $us->{'url'};
            my $title = $us->{'title'};
            $check->{'value'} = $url;
            if ($title =~ m!\S+! ) {
                push( @{$check->{'results'}}, "OK. Update site [$title] has title." );
            } else {
                push( @{$check->{'results'}}, "Failed. Update site has no title.");
            }
            push( @{$check->{'results'}}, &_check_url($url, "Update site [$title]") );
        }
    } else {
        push( @{$check->{'results'}}, 'Failed. No update site defined.' );
    }
    $ret_check->{'checks'}->{'update_sites'} = $check;
    
    
    # Test CI
    my $proj_ci = $raw_project->{'build_url'}->[0]->{'url'};
    $check = {};
    $check->{'results'} = [];
    $check->{'value'} = $proj_ci;
    $check->{'desc'} = "Sends a get request to the given CI URL and looks at the headers in the response (200, 404..). Also checks if the URL is really a Hudson instance (through a call to its API).";
    if ($proj_ci =~ m!\S+! && $ua->get($proj_ci)) {
        push( @{$check->{'results'}}, "OK. Fetched CI URL."); 
        
        my $url = $proj_ci . '/api/json?depth=1';

        my $json_str = $ua->get($url)->res->body;
        if ($json_str =~ m!^\s*{!) { 
            my $content_tmp = decode_json($json_str);
            my $name = $content_tmp->{'assignedLabels'}->[0]->{'name'};
            
            if (defined($name)) {
                push( @{$check->{'results'}}, "OK. CI URL is a Hudson instance. Title is [$name]");
            } else { 
                push( @{$check->{'results'}}, 'Failed: CI URL is not the root of a Hudson instance.'); 
            }
        } else {
            push( @{$check->{'results'}}, "Failed: could not decode Hudson JSON."); 
        }
    } else { 
        push( @{$check->{'results'}}, "Failed: could not get CI URL [$proj_ci]."); 
    }
    $ret_check->{'checks'}->{'build_url'} = $check;
    
    # Test releases
    $check = {};
    $check->{'results'} = [];
    $check->{'desc'} = 'Checks if the releases have been correctly filled.';
    if ( exists($raw_project->{'releases'}) ) {
        my @rels = @{$raw_project->{'releases'}};
        if (scalar @rels > 0) {
            foreach my $rel (@rels) {
                my $title = $rel->{'title'};
                my $dateval = $rel->{'date'}->[0]->{'value'};
                my $date = str2time($dateval);
                my $milestones = scalar @{$rel->{'milestones'}};
                my $review_state = $rel->{'review'}->{'state'}->[0]->{'value'} || 'none';
                my $rel_type = $rel->{'type'}->[0]->{'value'} || 1;
                if ( $rel_type < 3 && $date < time() ) {
                    if ( $review_state =~ m!success! ) {
                        push( @{$check->{'results'}}, "OK. Review for [$title] is 'success'." );
                    } else {
                        push( @{$check->{'results'}}, "Failed. Review for [$title] type [$rel_type] is [$review_state] on [$dateval].");
                    }
                }
            }
        } else {
            push( @{$check->{'results'}}, 'Failed. No release defined.' );
        }
    } else {
        push( @{$check->{'results'}}, 'Failed. No release defined.' );
    }
    $ret_check->{'checks'}->{'releases'} = $check;

    return $ret_check;
}

sub _check_url($$) {
    my $url = shift;
    my $str = shift || '';
    
    my $ua = Mojo::UserAgent->new;
    my $fetch_result;
    if ($ua->get($url)) {
        $fetch_result = "OK: $str <a href=\"$url\">URL</a> could be successfully fetched.";
    } else { 
        $fetch_result = 'Failed: could not get $str URL [$proj_web].'; 
    }
    return $fetch_result;
}

1;
