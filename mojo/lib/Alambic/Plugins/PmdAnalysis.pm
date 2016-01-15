package Alambic::Plugins::PmdAnalysis;
use base 'Mojolicious::Plugin';

use strict;
use warnings;

use Mojo::JSON qw( decode_json encode_json );
use Mojo::UserAgent;
use Data::Dumper;
use File::Copy;
use File::Path qw(remove_tree);
use XML::LibXML;
use File::Basename;
use Mojo::Home;


my %conf = (
    "id" => "pmd_analysis",
    "name" => "PMD Analysis",
    "desc" => "Defines a pragmatic strategy to improve your code, based on the results of PMD.",
    "ability" => [
        "viz",
    ],
    "requires" => {
        "bin_r" => "/usr/bin/R",
        "url_pmd_xml" => "",
        "url_pmd_conf" => "",
    },
    "provides_metrics" => {
    },
    "provides_files" => [
    ],
    "provides_viz" => [
        "pmd_analysis",
    ],
);

my $home = Mojo::Home->new;
my $pmd_rules = $home->rel_dir( "lib" ) . "/Alambic/Plugins/PmdAnalysis/rules/";

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

    $app->log->info("[Plugins::PmdAnalysis] Starting retrieve data for [$project_id].");
    
    my $project_conf = $app->projects->get_project_info($project_id)->{'ds'}->{$self->get_conf->{'id'}};
    my $url_xml = $project_conf->{'url_pmd_xml'};
    my $url_conf = $project_conf->{'url_pmd_conf'};
    
    my @log;
    my $ua = Mojo::UserAgent->new;

    my $content_xml = $ua->get($url_xml)->res->body;    
    my $file_xml_out = $app->config->{'dir_input'} . "/" . $project_id . "/" . $project_id 
        . "_import_pmd_analysis_results.xml";
    $app->log->info("[Plugins::PmdAnalysis] Writing XML results file to [$file_xml_out].");
    open my $fh, ">", $file_xml_out;
    print $fh $content_xml;
    close $fh;
    push( @log, "Retrieved PMD XML file from [$url_xml]. Lenght is " . length($content_xml) . ".");

    my $content_conf = $ua->get($url_conf)->res->body;    
    my $file_conf_out = $app->config->{'dir_input'} . "/" . $project_id . "/" . $project_id 
        . "_import_pmd_analysis_conf.xml";
    $app->log->info("[Plugins::PmdAnalysis] Writing XML results file to [$file_conf_out].");
    open $fh, ">", $file_conf_out;
    print $fh $content_conf;
    close $fh;
    push( @log, "Retrieved PMD configuration file from [$url_conf]. Lenght is " . length($content_conf) . ".");

    return \@log;
}

sub compute_data() {
    my $self = shift;
    my $project_id = shift;

    $app->log->info("[Plugins::PmdAnalysis] Starting compute data for [$project_id].");

    my $debug = 0;
    my @data_files;
    my $dir_out = $app->config->{'dir_input'} . "/" . $project_id . "/";

    # Reading rules from [$pmd_rules].
    my $rules_def = &_read_pmd_rules();

    # Reading configuration file for project.
    my %rules = &_read_pmd_conf($project_id, $rules_def);
    
    my $vol_rules = scalar keys %rules;
    $app->log->info( "Selected a total of [$vol_rules] rules." );

    # Read violations from xml file
    my $total_ncc;
    my %ret = &_read_pmd_xml_files($project_id, \%rules);
    my %files = %{$ret{'files'}};
    my %rulesets = %{$ret{'rulesets'}};
    my %violations = %{$ret{'violations'}};
    my $pmd_version = $ret{'version'};
    my $pmd_timestamp = $ret{'timestamp'};

    # Loop over violations to find the total number of violations and 
    # number of rules broken.
    foreach my $rule (keys %violations) {
        $rules{$rule}{'nok'} = 1;
        $total_ncc += $violations{ $rule }{ 'vol'};
    }
    
    # Will be used to set the name of generated files.
    my $file_id = $app->home->rel_dir('lib') . "/Alambic/Plugins/PmdAnalysis/${project_id}_pmd";

    # Write rules to a csv file
    my $csv_name = $file_id . "_analysis_rules.csv";
    $app->log->info( "Writing rules to file [$csv_name]." );
    
    # Compute the rate of broken rules for each priority.
    my %rules_ok;
    foreach my $rule (keys %rules) {
        my $prio = $rules{$rule}{'pri'};
        if (exists($violations{$rule})) {
            $rules_ok{$prio}{'nok'}++;
        } else {
            $rules_ok{$prio}{'ok'}++;
        }
    }

    # Write the result to a csv file.
    my $csv_out = "Priority,ok,nok\n";
    foreach my $priority (sort keys %rules_ok) {
        my $ok = $rules_ok{$priority}{'ok'} || 0;
        my $nok = $rules_ok{$priority}{'nok'} || 0;
        $csv_out .= "$priority," . $ok . ", " . $nok . "\n";
    }    

    push(@data_files, $csv_name);
    open( FHCSV, ">$csv_name" ) or return [ "ERROR: Could not open $csv_name.\n" ];
    print FHCSV $csv_out;
    close FHCSV;

    # Compute number of broken rules.
    my $total_rko = scalar keys %violations;

   # Format, and write, violations to json and csv files.

   # Initialise headers.
    my $json_violations;
    $json_violations = "{\n";
    $json_violations .= "    \"name\": \"Project violations\",\n";
    $json_violations .= "    \"children\": [\n";
    
    $csv_out = "Mnemo,priority,ruleset,vol\n";

    # Loop over violations and add them to json/csv content.
    my $start = 1;
    foreach my $violation (keys %violations) {
        my $ruleset = $violations{$violation}->{'ruleset'};
        my $vol = $violations{$violation}->{'vol'};
        my $pri = $violations{$violation}->{'pri'};
        my $tmp_m = "        {\n";
        $tmp_m   .= "            \"name\": \"$violation\",\n";
        $tmp_m   .= "            \"priority\": \"$pri\",\n";
        $tmp_m   .= "            \"ruleset\": \"$ruleset\",\n";
        $tmp_m   .= "            \"value\": \"$vol\"\n";
        $tmp_m   .= "        }";
        $csv_out .= "$violation,$pri,$ruleset,$vol\n";
        if ($start) {
            $json_violations = join( "\n", $json_violations, $tmp_m);
            $start = 0;
        } else {
            $json_violations = join( ", \n", $json_violations, $tmp_m);
        }
    }
    $json_violations .= "    ]\n";
    $json_violations .= "}\n";

    # Write violations to JSON.
    my $out_violations_name = $file_id . "_analysis_violations.json";
    
    push(@data_files, $out_violations_name);
    open( FHV, ">$out_violations_name" ) or die "Could not open $out_violations_name.\n";
    print FHV $json_violations;
    close FHV;
    
    # Write violations to CSV.
    $csv_name = $file_id . "_analysis_violations.csv";
    $app->log->info( "Writing violations to file [$csv_name].." );
    
    push(@data_files, $csv_name);
    open( FHCSV, ">$csv_name" ) or die "Could not open $csv_name.\n";
    print FHCSV $csv_out;
    close FHCSV;

    # Format and write number of violations by file.
    my $csv_files_out = "File,NCC,NCC_1,NCC_2,NCC_3,NCC_4,RKO,ROK,ROKR\n";

    # Loop over files and compute rate of acquired practices, 
    # number of violations by priority and total number of violations.
    foreach my $file (keys %files) {	
        my $file_name = $files{$file}{'name'};
        my $rko = scalar keys %{$files{$file}{'rules'}};
        my $rok = $vol_rules - $rko;
        my $rokr = 100 * $rok / $vol_rules;
        my $ncc_1 = $files{$file}{'pri'}{1} || 0;
        my $ncc_2 = $files{$file}{'pri'}{2} || 0;
        my $ncc_3 = $files{$file}{'pri'}{3} || 0;
        my $ncc_4 = $files{$file}{'pri'}{4} || 0;
        
        if (defined($files{$file}{'vol'})) {
            $csv_files_out .= "$file_name," . $files{$file}{'vol'} . ",$ncc_1,$ncc_2,$ncc_3,$ncc_4,$rko,$rok,$rokr\n";
        }
    }
    
    # Write files to a csv file
    $csv_name = $file_id . "_analysis_files.csv";
    $app->log->info( "Writing files to file [$csv_name].." );

    push(@data_files, $csv_name);
    open( FHCSV, ">$csv_name" ) or die "Could not open $csv_name.\n";
    print FHCSV $csv_files_out;
    close FHCSV;

    # Write a summary of the run.
    $csv_name = $file_id . "_analysis_main.csv";
    $app->log->info( "Writing main pmd file [$csv_name].." );
    
    my $total_rok = $vol_rules - $total_rko;
    my $total_rokr = 100 * $total_rok / $vol_rules;
    
    my $csv_main_out = "PMD version,Timestamp,ConfFile,NCC,RULES,RKO,ROK,ROKR\n";
    $csv_main_out .= "$pmd_version,$pmd_timestamp,,$total_ncc,$vol_rules,$total_rko,$total_rok,$total_rokr\n";
    
    push(@data_files, $csv_name);
    open( FHCSV, ">$csv_name" ) or die "Could not open $csv_name.\n";
    print FHCSV $csv_main_out;
    close FHCSV;

    my $r_dir = $app->home->rel_dir('lib') . "/Alambic/Plugins/PmdAnalysis/";
    my $r_html = "PmdAnalysis.Rhtml";
    my $r_html_out = "${project_id}_pmd_analysis.inc";

    chdir $r_dir;
    $app->log->info( "Executing R script [$r_html] in [$r_dir] with [$project_id]." );
    $app->log->info( "Result to be stored in [$r_html_out]." );

    # TODO Use $app->projects->get_project_info($project_id)->{'ds'}->{'pmd_analysis'}->{'r_bin'};
    # to get r bin path.
    my $r_cmd = "Rscript -e \"library(knitr); " 
        . "project.id <- '${project_id}'; plugin.id <- 'pmd_analysis'; "
        . "knit('${r_html}', output='${r_html_out}')\"";

    $app->log->info( "Exec [$r_cmd]." );
    my @out = `$r_cmd`;
    $app->log->debug( @out );

    # Now move files to data/project
    move( "${r_html_out}", $dir_out );
    # Move all data files to target dir.
    foreach my $file (@data_files) {
        $app->log->info( "Moving $file to $dir_out." );
        my $ret = move($file, $dir_out);
    }

    # Create dir for figures.
    if (! -d "${dir_out}/figures/" ) {
        $app->log->info( "Creating directory [${dir_out}/figures/]." );
        mkdir "${dir_out}/figures/";
    }

    # Now move figures to data/project
    my $dir_out_fig = $dir_out . "/figures/pmd_analysis/";
    if ( -e $dir_out_fig ) {
        $app->log->info( "Target directory [$dir_out_fig] exists. Removing it." );
        my $ret = remove_tree($dir_out_fig, {verbose => 1});
    }
    my $ret = move('figures/pmd_analysis/' . $project_id . '/', $dir_out_fig);
    $app->log->info( "Moved figures from ${r_dir}/figures to $dir_out_fig. ret $ret." );

    return ["Done."];
}


#
# Read the rules definition files for PMD. These are stored in a directory within 
# the plugin dir. Returns a hash of rules.
#
sub _read_pmd_rules() {

    my %rules_def;

    $app->log->info( "[PmdAnalysis] Reading rules definition from [$pmd_rules]." );

    my @rules_files = <$pmd_rules/*.xml>;

    # For each file, read, parse and store it in %rules_def.
    foreach my $file_rules (@rules_files) {
	my $ruleset = basename($file_rules);
	
	my $parser = XML::LibXML->new;
	my $doc = $parser->parse_file($file_rules);
	
	my @ruleset_node = $doc->getElementsByTagName("ruleset");
	my $rules_name = $ruleset_node[0]->getAttribute("name");
	
	my @rule_nodes = $ruleset_node[0]->getElementsByTagName("rule");
	
	foreach my $rule_child ( @rule_nodes ) {
	    my $rule_disabled = $rule_child->getAttribute("ref");
	    if (defined($rule_disabled)) { next; }
	    
	    my $rule_name = $rule_child->getAttribute("name");	    
	    my $rule_desc = $rule_child->getAttribute("message");
	    my @rule_priority = $rule_child->getChildrenByTagName("priority");
	    my $priority = $rule_priority[0]->textContent();
            $rules_def{ $ruleset }{ $rule_name }{ 'desc' } = $rule_desc;
	    $rules_def{ $ruleset }{ $rule_name }{ 'pri' } = $priority;
	}
    }

    return \%rules_def;    
}


#
# Read the XML file used for PMD configuration. Returns a hash of 
# rules used for this run, providing some info about each rule.
#
sub _read_pmd_conf($) {
    my $project_id = shift;
    my $rules_def = shift;
    
    my $debug = 0;
    
    my $pmd_conf = $app->config->{'dir_input'} . "/" . $project_id . "/" . $project_id 
        . "_import_pmd_analysis_conf.xml";
    $app->log->info( "[PmdAnalysis] Reading PMD configuration from [$pmd_conf]." );

    # Read pmd xml results file.
    my $parser = XML::LibXML->new;
    my $doc = $parser->parse_file($pmd_conf);
    
    my %rules;

    my @ruleset_node = $doc->getElementsByTagName("ruleset");
    my $rules_name = $ruleset_node[0]->getAttribute("name");
    my @rule_nodes = $ruleset_node[0]->getElementsByTagName("rule");    
    
    my $vol_rules;
    foreach my $rule_child ( @rule_nodes ) {
	my $rule_ref = $rule_child->getAttribute("ref");
	my $ruleset_name = "undefined";
	my $file_vol_rules = 0;
	
	my @included_rules;
	
	if ($rule_ref =~ m!^(.*\.xml)(/(.*))?$!) {
	    $ruleset_name = basename($1);
	    if (defined($2)) {
		push( @included_rules, $3);
	    } else {
		@included_rules = keys %{ $rules_def->{ $ruleset_name } };   
	    }
	} else {
	    $app->log->warn( "[PmdAnalysis] ERR could not parse rule ref [$rule_ref]." );
	}
	
	my @excluded_rules = $rule_child->getElementsByTagName("exclude");
	my %excluded;
	foreach my $excluded_rule (@excluded_rules) {
	    my $name = $excluded_rule->getAttribute("name");
	    $excluded{$name}++;
	}
	
	foreach my $rule ( @included_rules ) {
	    if ( exists($excluded{$rule}) ) {
		next;
	    } else {
		$rules{ $rule } = $rules_def->{ $ruleset_name }{ $rule };
		$file_vol_rules++;
	    }
	}
	$vol_rules += $file_vol_rules;
	
	$app->log->info( "[PmdAnalysis] Imported [$file_vol_rules] rules from ruleset [$ruleset_name]." );
    }

    return %rules;
}


#
# Read the XML results file the PMD run. Returns a hash of 
# information about the files and violations of this run.
# %ret = {
#   'version' => 'pmd version',
#   'timestamp' => 'pmd run timestamp',
#   'violations' => hash of information about violations.
#   'files' => hash of information about faulty files.
# }
#
sub _read_pmd_xml_files($) {
    my $project_id = shift;
    my $rules = shift;
    
    my %ret;

    my $pmd_xml = $app->config->{'dir_input'} . "/" . $project_id . "/" . $project_id 
        . "_import_pmd_analysis_results.xml";
    
    my $parser = XML::LibXML->new;
    my $doc = $parser->parse_file($pmd_xml);

    my $pmd_node = $doc->findnodes("/pmd");
    $ret{'version'} = $pmd_node->[0]->getAttribute("version");
    $ret{'timestamp'} = $pmd_node->[0]->getAttribute("timestamp");

    # XML results file is organised as follows: 
    # <file name="file_name.java">
    #   <violation rule="UncommentedEmptyConstructor" ruleset="Design"></violation>
    # </file>
    my @files_nodes = $doc->findnodes("//file");
    foreach my $file (@files_nodes) {
        my $file_name = $file->getAttribute('name');
        my @violations = $file->findnodes("violation");
	
        foreach my $violation (@violations) {
            # Take care of violations
            my $rule = $violation->getAttribute('rule');
            my $ruleset = $violation->getAttribute('ruleset');
            if (exists($rules->{$rule})) {
                my $pri = $violation->getAttribute('priority');

                $ret{'violations'}{ $rule }{ 'vol' }++;
                $ret{'violations'}{ $rule }{ 'pri' } = $violation->getAttribute('priority');
                $ret{'violations'}{ $rule }{ 'ruleset' } = $violation->getAttribute('ruleset');
        	$ret{'files'}{$file_name}{'name'} = $file_name;
        	$ret{'files'}{$file_name}{'vol'}++;
        	$ret{'files'}{$file_name}{'rules'}{$rule}{'vol'}++;
        	$ret{'files'}{$file_name}{'rules'}{$rule}{'pri'} = $pri;
        	$ret{'files'}{$file_name}{'pri'}{$pri}++;
        	$ret{'rulesets'}{$ruleset}{$pri}++;
            } else {
        	$app->log->info( "[PmdAnalysis] WARN Could not find rule [$rule] from ruleset [$ruleset] in rules definition." );
            }
        }
	
    }

    return %ret;
}

1;
