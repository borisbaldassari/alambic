package Alambic::Plugins::EclipsePmi;

use strict; 
use warnings;

use Alambic::Model::RepoFS;

use Mojo::JSON qw( decode_json encode_json );
use Mojo::UserAgent;
use Date::Parse;
use Mojolicious::Controller;
use Mojolicious::Renderer;
use Data::Dumper;

# Main configuration hash for the plugin
my %conf = (
    "id" => "EclipsePmi",
    "name" => "Eclipse PMI",
    "desc" => [ 
	"Eclipse PMI Retrieves data from the Eclipse PMI infrastructure.",
	"<code>project_grim</code> is the identifier used for the project in the Eclipse dashboard. It may be different from the id used in the PMI.",
	'See <a href="https://bitbucket.org/BorisBaldassari/alambic/wiki/Plugins/3.x/EclipsePmi">the project\'s wiki</a> for more information.',
    ],
    "type" => "pre",
    "ability" => [ "metrics", "info", 'data', "recs", "viz" ],
    "params" => {
        "project_pmi" => "",
    },
    "provides_cdata" => [
    ],
    "provides_info" => [
        "MLS_DEV_URL", 
        "MLS_USR_URL", 
        "PMI_MAIN_URL", 
        "PMI_WIKI_URL", 
	"PMI_BUGZILLA_CREATE_URL", 
	"PMI_DOWNLOAD_URL", 
	"PMI_SCM_URL", 
	"PMI_BUGZILLA_COMPONENT", 
	"PMI_CI_URL", 
	"PMI_BUGZILLA_PRODUCT", 
	"PMI_BUGZILLA_QUERY_URL", 
	"PMI_DOCUMENTATION_URL", 
	"PMI_DESC", 
	"PMI_GETTINGSTARTED_URL", 
	"PMI_TITLE", 
	"PMI_ID", 
	"PMI_UPDATESITE_URL", 
    ],
    "provides_data" => {
        "pmi.json" => "The PMI file as returned by the Eclipse repository (JSON).",
        "pmi_checks.json" => "The list of PMI checks and their results (JSON).",
    },
    "provides_metrics" => {
	"PMI_ITS_INFO" => "PMI_ITS_INFO",
	"PMI_SCM_INFO" => "PMI_SCM_INFO",
        "PMI_OK" => "PMI_OK",
        "PMI_NOK" => "PMI_NOK",
    },
    "provides_figs" => {
    },
    "provides_recs" => [
        "PMI_ENTRY_NOT_SET",
        "PMI_ENTRY_WRONG",
    ],
    "provides_viz" => {
        "pmi_checks" => "Eclipse PMI Checks",
    },
);

my $eclipse_url = "https://projects.eclipse.org/json/project/";
my $polarsys_url = "https://polarsys.org/json/project/";


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

    my $project_pmi = $conf->{'project_pmi'} || $project_id;

    my %ret = (
	'metrics' => {},
	'info' => {},
	'recs' => [],
	'log' => [],
	);

    my $repofs = Alambic::Model::RepoFS->new();

    $ret{'log'} = &_retrieve_data( $project_id, $project_pmi, $repofs );
    
    my $tmp_ret = &_compute_data( $project_id, $project_pmi, $repofs );

    $ret{'metrics'} = $tmp_ret->{'metrics'};
    $ret{'info'} = $tmp_ret->{'info'};
    $ret{'recs'} = $tmp_ret->{'recs'};
    push( @{$ret{'log'}}, @{$tmp_ret->{'log'}} );
    
    return \%ret;
}


sub _retrieve_data($$$) {
    my ($project_id, $project_pmi, $repofs) = @_;

    my @log;

    my $ua = Mojo::UserAgent->new;
    $ua->max_redirects(10);
    $ua->inactivity_timeout(60);

    # Fetch json file from projects.eclipse.org
    my ($url, $content);
    if ($project_id =~ m!^polarsys!) {
        $url = $polarsys_url . $project_pmi;
        push( @log, "[Plugins::EclipsePmi] Using PolarSys PMI infra at [$url]." );
        $content = $ua->get($url)->res->body;
    } else {
        $url = $eclipse_url . $project_pmi;
        push( @log, "[Plugins::EclipsePmi] Using Eclipse PMI infra at [$url]." );
        $content = $ua->get($url)->res->body;
    }

    # Check if we actually get some results.
    my $pmi = decode_json($content);
    my $custom_pmi;
    if ( defined($pmi->{'projects'}{$project_pmi}) ) {
        $custom_pmi = $pmi->{'projects'}{$project_pmi};
    } else {
        push( @log, "ERROR: Could not get [$url]!" );
        return \@log unless defined $content;
    }
    $custom_pmi->{'pmi_url'} = $url;
    
    push( @log, "[Plugins::EclipsePmi] Writing PMI json file to input." );
    $repofs->write_input( $project_id, "import_pmi.json", encode_json($custom_pmi) );

    return \@log;
}

sub _compute_data($) {
    my ($project_id, $project_pmi, $repofs) = @_;

    my %info;
    my %metrics;
    my @recs;
    my @log;

    push( @log, "[Plugins::EclipsePmi] Starting compute data for [$project_id]." );

    my $ua = Mojo::UserAgent->new;
    $ua->max_redirects(10);

    # Read data from pmi file in $data_input
    my $json = $repofs->read_input( $project_id, "import_pmi.json" );

    # Decode the entire JSON
    my $raw_project = decode_json( $json ) or push( @log, "ERROR: Could not decode json: \n$json" );

    # Retrieve basic information about the project
    $info{"pmi_title"} = $raw_project->{"title"};
    $info{"pmi_desc"} = $raw_project->{"description"}->[0]->{"safe_value"};
    $info{"pmi_id"} = $raw_project->{"id"}->[0]->{"value"};

    # Retrieve information about Bugzilla
    my $pub_its_info = 0;
    if (scalar @{$raw_project->{"bugzilla"}} > 0) {

        $info{"pmi_bugzilla_product"} = $raw_project->{"bugzilla"}->[0]->{"product"};
        if ($info{"pmi_bugzilla_product"} =~ m!\S+!) { $pub_its_info++ };

        $info{"pmi_bugzilla_component"} = $raw_project->{"bugzilla"}->[0]->{"component"};
	
        $info{"pmi_bugzilla_create_url"} = $raw_project->{"bugzilla"}->[0]->{"create_url"};
        if ($info{"pmi_bugzilla_create_url"} =~ m!\S+!) { $pub_its_info++ };
        if ($ua->head($info{"pmi_bugzilla_create_url"})) {
            $pub_its_info++; 
        }

        $info{"pmi_bugzilla_query_url"} = $raw_project->{"bugzilla"}->[0]->{"query_url"};
        if ($info{"pmi_bugzilla_query_url"} =~ m!\S+!) { $pub_its_info++; }
        if ($ua->head($info{"pmi_bugzilla_query_url"})) {
            $pub_its_info++;
        }
    }	
    $metrics{"PMI_ITS_INFO"} = $pub_its_info;

    # Retrieve information about source repos
    my $pub_scm_info = 0;
    if (scalar @{$raw_project->{"source_repo"}} > 0) {
	if ($ua->head($info{"pmi_source_repo_url"})) {
	    $pub_scm_info++;
	}

    }
    $metrics{"PMI_SCM_INFO"} = $pub_scm_info;    
        
    my $ret_check;
    $ret_check->{'pmi'} = $raw_project;
    $ret_check->{'id_pmi'} = $project_pmi;
    $ret_check->{'pmi_url'} = $raw_project->{'pmi_url'};
    $ret_check->{'name'} = $raw_project->{'title'};
    $ret_check->{'last_update'} = time();
    
    $ua = Mojo::UserAgent->new;
    $ua->max_redirects(10);
    
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
	$info{"pmi_main_url"} = $raw_project->{'website_url'}->[0]->{'url'};
        $check->{'value'} = $info{"pmi_main_url"};
        my $results = &_check_url($info{"pmi_main_url"}, 'Website');
        push( @{$check->{'results'}}, $results );
	if ($results !~ /^OK/) {
	    push( @recs, { 'rid' => 'PMI_NOK', 'severity' => 3, 'desc' => 'Check the web site URL in PMI.' } );
	}
#	print "# In EclipsePmi::checks " . Dumper($results);
    } else {
        push( @{$check->{'results'}}, "Failed: no URL defined for website_url.");
	push( @recs, { 'rid' => 'PMI_NOK', 'severity' => 3, 'desc' => 'Fill in the web site URL in PMI.' } );
    }
    $ret_check->{'checks'}->{'website_url'} = $check;
    
    # Test Wiki
    $check = {};
    $check->{'results'} = [];
    $check->{'desc'} = "Sends a get request to the project wiki URL and looks at the headers in the response (200, 404..).";
    if ( exists($raw_project->{'wiki_url'}->[0]->{'url'}) ) {
	$info{"pmi_wiki_url"} = $raw_project->{'wiki_url'}->[0]->{'url'};
        $check->{'value'} = $info{"pmi_wiki_url"};
        my $results = &_check_url($url, 'Wiki');
        push( @{$check->{'results'}}, $results );
	if ($results !~ /^OK/) {
	    push( @recs, { 'rid' => 'PMI_NOK', 'severity' => 3, 'desc' => 'Check the wiki URL in PMI.' } );
	}
    } else {
        push( @{$check->{'results'}}, "Failed: no URL defined for wiki_url.");
	push( @recs, { 'rid' => 'PMI_NOK', 'severity' => 3, 'desc' => 'Fill in the wiki URL in PMI.' } );
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
	$info{"pmi_download_url"} = $raw_project->{'download_url'}->[0]->{'url'};
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
	$info{"pmi_gettingstarted_url"} = $raw_project->{'gettingstarted_url'}->[0]->{'url'};
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
	$info{"pmi_documentation_url"} = $raw_project->{'documentation_url'}->[0]->{'url'};
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
	$info{"pmi_plan_url"} = $raw_project->{'plan_url'}->[0]->{'url'};
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
	$info{"mls_dev_url"} = $raw_project->{'dev_list'}->{'url'};
        $url = $raw_project->{'dev_list'}->{'url'};
        $check->{'value'} = $url;
        my $results = &_check_url($url, 'Dev ML');
        push( @{$check->{'results'}}, $results );
	if ($results !~ /^OK/) {
	    push( @recs, { 'rid' => 'PMI_NOK', 'severity' => 3, 'desc' => 'Check the Developer mailing list URL in PMI.' } );
	}
    } else {
        push( @{$check->{'results'}}, 'Failed: no dev mailing list defined.' );
	push( @recs, { 'rid' => 'PMI_NOK', 'severity' => 3, 'desc' => 'Fill in the Developer mailing list URL in PMI.' } );
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
	    $info{"mls_usr_url"} = $url;
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
	    $info{"pmi_scm_url"} = $url;
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
	    $info{"pmi_updatesite_url"} = $url;
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
    my $proj_ci = $raw_project->{'build_url'}->[0]->{'url'} || '';
    $check = {};
    $check->{'results'} = [];
    $check->{'value'} = $proj_ci;
    $check->{'desc'} = "Sends a get request to the given CI URL and looks at the headers in the response (200, 404..). Also checks if the URL is really a Hudson instance (through a call to its API).";
    if ($proj_ci =~ m!\S+! && $ua->get($proj_ci)) {
	push( @{$check->{'results'}}, "OK. Fetched CI URL.");         
        my $url = $proj_ci . '/api/json?depth=1';
	$info{"pmi_ci_url"} = $proj_ci;
        my $json_str = $ua->get($url)->res->body;
        if ($json_str =~ m!^\s*{!) { 
            my $content_tmp = decode_json($json_str);
            my $name = $content_tmp->{'assignedLabels'}->[0]->{'name'};
            
            if (defined($name)) {
                push( @{$check->{'results'}}, "OK. CI URL is a Hudson instance. Title is [$name]");
            } else { 
                push( @{$check->{'results'}}, 'Failed: CI URL is not the root of a Hudson instance.'); 
		push( @recs, { 'rid' => 'PMI_NOK', 'severity' => 3, 'desc' => "Check the Hudson CI engine URL in PMI. [$url] is not detected as the root of a Hudson instance." } );
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

    # Write pmi checks json file to disk.
    push( @log, "[Plugins::EclipsePmi] Writing PMI checks json file to output dir." );
    $repofs->write_output( $project_id, "pmi_checks.json", encode_json($ret_check) );

    # Write pmi json file to disk.
    push( @log, "[Plugins::EclipsePmi] Writing updated PMI json file to output dir." );
    $repofs->write_output( $project_id, "pmi.json", encode_json($raw_project) );

    return {
	"info" => \%info,
	"metrics" => \%metrics,
	"recs" => \@recs,
	"log" => \@log,
    };
}


sub _check_url($$) {
    my $url = shift || '';
    my $str = shift || '';
    
    my $ua = Mojo::UserAgent->new;
    $ua->max_redirects(10);

    my $fetch_result;
    if ($ua->head($url)) {
        $fetch_result = "OK: $str <a href=\"$url\">URL</a> could be successfully fetched.";
    } else { 
        $fetch_result = 'Failed: could not get $str URL [$url].'; 
    }
    return $fetch_result;
}


1;
