package Alambic::Plugins::PmdConfiguration;
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


my %conf = (
    "id" => "pmd_configuration",
    "name" => "PMD Configuration",
    "desc" => "Uses a PMD XML result file to provide advice on a better configuration of the tool.",
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
        "pmd_configuration",
    ],
);

my $pmd_rules = "lib/Alambic/Plugins/PmdConfiguration/rules/";

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
    my $url_xml = $project_conf->{'url_pmd_xml'};
    my $url_conf = $project_conf->{'url_pmd_conf'};
    
    my @log;
    my $ua = Mojo::UserAgent->new;

    my $content_xml = $ua->get($url_xml)->res->body;    
    my $file_xml_out = $app->config->{'dir_input'} . "/" . $project_id . "/" . $project_id . "_import_pmd_results.xml";
    $app->log->debug("[Plugins::PmdConfiguration] Writing XML results file to [$file_xml_out].");
    open my $fh, ">", $file_xml_out;
    print $fh $content_xml;
    close $fh;
    push( @log, "Retrieved PMD XML file from [$url_xml].");

    my $content_conf = $ua->get($url_conf)->res->body;    
    my $file_conf_out = $app->config->{'dir_input'} . "/" . $project_id . "/" . $project_id 
        . "_import_pmd_conf.xml";
    $app->log->debug("[Plugins::PmdConfiguration] Writing XML results file to [$file_conf_out].");
    open $fh, ">", $file_conf_out;
    print $fh $content_conf;
    close $fh;
    push( @log, "Retrieved PMD configuration file from [$url_conf].");

    return \@log;
}

sub compute_data() {
    my $self = shift;
    my $project_id = shift;

    my $debug = 0;
    my @data_files;
    my $dir_out = $app->config->{'dir_input'} . "/" . $project_id . "/";

    print "Reading rules from [$pmd_rules].\n";
    my %rules_def = &_read_pmd_rules();

    print "Reading configuration file for project.\n";
    my %rules = &_read_pmd_conf($project_id, \%rules_def);
#    print Dumper(%rules);
    
    my $vol_rules = scalar keys %rules;
    print "Selected a total of [$vol_rules] rules.\n\n";

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
    my $file_id = $app->home->rel_dir('lib') . "/Alambic/Plugins/PmdConfiguration/${project_id}_pmd";

    # Write rules to a csv file
    my $csv_name = $file_id . "_conf_rules.csv";
    print "\nWriting rules to file [$csv_name]..\n";
    
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
    open( FHCSV, ">$csv_name" ) or die "Could not open $csv_name.\n";
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
        print "Working on $violation: $vol.\n" if ($debug);
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
    my $out_violations_name = $file_id . "_conf_violations.json";
    
    push(@data_files, $out_violations_name);
    open( FHV, ">$out_violations_name" ) or die "Could not open $out_violations_name.\n";
    print FHV $json_violations;
    close FHV;
    
    # Write violations to CSV.
    $csv_name = $file_id . "_conf_violations.csv";
    print "\nWriting violations to file [$csv_name]..\n";
    
    push(@data_files, $csv_name);
    open( FHCSV, ">$csv_name" ) or die "Could not open $csv_name.\n";
    print FHCSV $csv_out;
    close FHCSV;

    # Format and write number of violations by file.
    print "Computing NCC by file.\n";
    my $csv_files_out = "File,NCC,NCC_1,NCC_2,NCC_3,NCC_4,RKO,ROK,ROKR\n";

    # Loop over files and compute rate of acquired practices, 
    # number of violations by priority and total number of violations.
    foreach my $file (keys %files) {	
        my $file_name = $files{$file}{'name'};
        my $rko = scalar keys %{$files{$file}{'rules'}};
        my $rok = $vol_rules - $rko;
        my $rokr = 100 * $rok / $vol_rules;
        print " rokr $rokr.\n" if ($debug);
        my $ncc_1 = $files{$file}{'pri'}{1} || 0;
        my $ncc_2 = $files{$file}{'pri'}{2} || 0;
        my $ncc_3 = $files{$file}{'pri'}{3} || 0;
        my $ncc_4 = $files{$file}{'pri'}{4} || 0;
        
        if (defined($files{$file}{'vol'})) {
            $csv_files_out .= "$file_name," . $files{$file}{'vol'} . ",$ncc_1,$ncc_2,$ncc_3,$ncc_4,$rko,$rok,$rokr\n";
        }
    }
    
    # Write files to a csv file
    $csv_name = $file_id . "_conf_files.csv";
    print "Writing files to file [$csv_name]..\n";

    push(@data_files, $csv_name);
    open( FHCSV, ">$csv_name" ) or die "Could not open $csv_name.\n";
    print FHCSV $csv_files_out;
    close FHCSV;

    # Compute violations by ruleset. Two formats are provided for different purposes.
    my $csv_rulesets_out = "Ruleset,NCC_1,NCC_2,NCC_3,NCC_4\n";
    my $csv_rulesets2_out = "ruleset,priority,ncc\n";
    
    # Compute number of violations by priority and by rulesets.
    foreach my $ruleset (sort keys %rulesets) {
        my $ncc_1 = $rulesets{$ruleset}{1} || 0;
        my $ncc_2 = $rulesets{$ruleset}{2} || 0;
        my $ncc_3 = $rulesets{$ruleset}{3} || 0;
        my $ncc_4 = $rulesets{$ruleset}{4} || 0;
        $csv_rulesets_out .= "$ruleset,$ncc_1,$ncc_2,$ncc_3,$ncc_4\n";
    }
    
    # Summarise number of violations by priority by ruleset.
    foreach my $ruleset (sort keys %rulesets) {
        foreach my $priority (sort keys %{$rulesets{$ruleset}}) {
            my $vol = $rulesets{$ruleset}{$priority};
            $csv_rulesets2_out .= "$ruleset,$priority,$vol\n";
        }
    }
    
    # Write rulesets to CSV (first format).
    $csv_name = $file_id . "_conf_rulesets.csv";
    print "Writing rulesets to file [$csv_name]..\n";
    
    push(@data_files, $csv_name);
    open( FHCSV, ">$csv_name" ) or die "Could not open $csv_name.\n";
    print FHCSV $csv_rulesets_out;
    close FHCSV;
    
    # Write rulesets to CSV (second format).
    $csv_name = $file_id . "_conf_rulesets2.csv";
    print "Writing rulesets to file [$csv_name]..\n";
    
    push(@data_files, $csv_name);
    open( FHCSV, ">$csv_name" ) or die "Could not open $csv_name.\n";
    print FHCSV $csv_rulesets2_out;
    close FHCSV;

    # Write a summary of the run.
    $csv_name = $file_id . "_conf_main.csv";
    print "Writing main pmd file [$csv_name]..\n";
    
    my $total_rok = $vol_rules - $total_rko;
    print "DBG total_rok = $total_rok. vol_rules = $vol_rules.\n";
    my $total_rokr = 100 * $total_rok / $vol_rules;
    print "DBG total_rokr = $total_rokr.\n";
    
    my $csv_main_out = "PMD version,Timestamp,ConfFile,NCC,RULES,RKO,ROK,ROKR\n";
    $csv_main_out .= "$pmd_version,$pmd_timestamp,$total_ncc,$vol_rules,$total_rko,$total_rok,$total_rokr\n";
    
    push(@data_files, $csv_name);
    open( FHCSV, ">$csv_name" ) or die "Could not open $csv_name.\n";
    print FHCSV $csv_main_out;
    close FHCSV;

    my $r_dir = $app->home->rel_dir('lib') . "/Alambic/Plugins/PmdConfiguration/";
    my $r_html = "PmdConfiguration.Rhtml";
    my $r_html_out = "${project_id}_pmd_configuration.inc";

    chdir $r_dir;
    $app->log->info( "Executing R script [$r_html] in [$r_dir] with [$project_id]." );
    $app->log->info( "Result to be stored in [$r_html_out]." );

    # TODO Use $app->projects->get_project_info($project_id)->{'ds'}->{'pmd_configuration'}->{'r_bin'};
    # to get r bin path.
    my $r_cmd = "Rscript -e \"library(knitr); " 
        . "project.id <- '${project_id}'; plugin.id <- 'pmd_configuration'; "
        . "knit('${r_html}', output='${r_html_out}')\"";

    $app->log->info( "Exec [$r_cmd]." );
    my @out = `$r_cmd`;
    print @out;

    # Now move files to data/project
    move( "${r_html_out}", $dir_out );
    # Move all data files to target dir.
    foreach my $file (@data_files) {
        print "Moving $file to $dir_out.\n";
        my $ret = move($file, $dir_out);
        print "DBG $ret $!.\n" if ($debug);
    }

    # Create dir for figures.
    if (! -d "${dir_out}/figures/" ) {
        print "Creating directory [${dir_out}/figures/].\n";
        mkdir "${dir_out}/figures/";
    }

    # Now move figures to data/project
    my $dir_out_fig = $dir_out . "/figures/pmd_configuration/";
    if ( -e $dir_out_fig ) {
        print "Target directory [$dir_out_fig] exists. Removing it.\n";
        my $ret = remove_tree($dir_out_fig, {verbose => 1});
    }
    my $ret = move('figures/pmd_configuration/' . $project_id . '/', $dir_out_fig);
    print "Moved figures from ${r_dir}/figures to $dir_out_fig. ret $ret.\n";

    return ["Done."];
}

sub _read_pmd_rules() {

    my %rules_def;
    my $debug = 0;

    print "[PMD.pm] Reading rules definition from [$pmd_rules]. \n";

    my @rules_files = <$pmd_rules/*.xml>;

    foreach my $file_rules (@rules_files) {
	my $ruleset = basename($file_rules);
#    $rulesets_def{$ruleset}++;
	
#	print "[PMD.pm] Name of ruleset is [$file_rules]. \n" if ($debug);
	
	my $parser = XML::LibXML->new;
	my $doc = $parser->parse_file($file_rules);
	
	my @ruleset_node = $doc->getElementsByTagName("ruleset");
	my $rules_name = $ruleset_node[0]->getAttribute("name");
	
	print "[PMD.pm] Ruleset name: ", $rules_name, "\n";
	
	# my $file_vol_rules;
	my @rule_nodes = $ruleset_node[0]->getElementsByTagName("rule");
	
	print "[PMD.pm] DBG Size of ruleset " . scalar @rule_nodes . "\n" if ($debug);
	
	foreach my $rule_child ( @rule_nodes ) {
	    my $rule_disabled = $rule_child->getAttribute("ref");
	    if (defined($rule_disabled)) { print "[PMD.pm] DBG obsolete!\n" if ($debug); next; }
	    
	    my $rule_name = $rule_child->getAttribute("name");
	    print "[PMD.pm] DBG reading rule def [$rule_name]." if ($debug);
	    
	    my $rule_desc = $rule_child->getAttribute("message");
	    my @rule_priority = $rule_child->getChildrenByTagName("priority");
	    my $priority = $rule_priority[0]->textContent();
	    print "priority [$priority].\n" if ($debug);
	    
	    $rules_def{ $ruleset }{ $rule_name }{ 'desc' } = $rule_desc;
	    $rules_def{ $ruleset }{ $rule_name }{ 'pri' } = $priority;
	}
    }
    
    return %rules_def;
    
}


sub _read_pmd_conf($) {
    my $project_id = shift;
    my $rules_def = shift;
    
    my $debug = 0;
    
    my $pmd_conf = $app->config->{'dir_input'} . "/" . $project_id . "/" . $project_id 
        . "_import_pmd_conf.xml";

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
	my $file_vol_rules;
	
	my @included_rules;
	
	if ($rule_ref =~ m!^(.*\.xml)(/(.*))?$!) {
	    $ruleset_name = basename($1);
	    print "[PMD.pm] Selecting ruleset [$ruleset_name].";
	    if (defined($2)) {
		print "[PMD.pm]   Including rule $3.\n";
		push( @included_rules, $3);
	    } else {
		print "[PMD.pm]   Whole ruleset selected $ruleset_name.\n";
		@included_rules = keys %{ $rules_def->{ $ruleset_name } };   
	    }
	} else {
	    print "[PMD.pm] ERR could not parse rule ref [$rule_ref].\n";
	}
	
	my @excluded_rules = $rule_child->getElementsByTagName("exclude");
	my %excluded;
	foreach my $excluded_rule (@excluded_rules) {
	    my $name = $excluded_rule->getAttribute("name");
	    $excluded{$name}++;
	}
	
	print "[PMD.pm] Adding rules from ruleset [$ruleset_name].\n" if ($debug);
	
	foreach my $rule ( @included_rules ) {
	    if ( exists($excluded{$rule}) ) {
		next;
	    } else {
		print "  Adding rule [$rule].\n" if ($debug);
		$rules{ $rule } = $rules_def->{ $ruleset_name }{ $rule };
		$file_vol_rules++;
	    }
	}
	$vol_rules += $file_vol_rules;
	
	print "[PMD.pm] Imported [$file_vol_rules] rules from ruleset [$ruleset_name].\n\n";
    }

    return %rules;
}
    
sub _read_pmd_xml_violations($) {
    my $project_id = shift;
    my $rules = shift;
    
    my %ret;
    
    my $pmd_xml = $app->config->{'dir_input'} . "/" . $project_id . "/" . $project_id 
        . "_import_pmd_results.xml";
    
    my $parser = XML::LibXML->new;
    my $doc = $parser->parse_file($pmd_xml);

    my $pmd_node = $doc->findnodes("/pmd");
    $ret{'version'} = $pmd_node->[0]->getAttribute("version");
    $ret{'timestamp'} = $pmd_node->[0]->getAttribute("timestamp");

    my @violations_nodes = $doc->findnodes("//violation");
    foreach my $violation (@violations_nodes) {
	my $violation_name = $violation->getAttribute('rule');
	
	if (exists($rules->{$violation_name})) {
	    $ret{'violations'}{ $violation_name }{ 'vol' }++;
	    $ret{'violations'}{ $violation_name }{ 'pri' } = $violation->getAttribute('priority');
	    $ret{'violations'}{ $violation_name }{ 'ruleset' } = $violation->getAttribute('ruleset');
	}
    }

    return %ret;

}

sub _read_pmd_xml_files($) {
    my $project_id = shift;
    my $rules = shift;
    
    my %ret;

    my $pmd_xml = $app->config->{'dir_input'} . "/" . $project_id . "/" . $project_id 
        . "_import_pmd_results.xml";
    
    my $parser = XML::LibXML->new;
    my $doc = $parser->parse_file($pmd_xml);

    my $pmd_node = $doc->findnodes("/pmd");
    $ret{'version'} = $pmd_node->[0]->getAttribute("version");
    $ret{'timestamp'} = $pmd_node->[0]->getAttribute("timestamp");

    my @files_nodes = $doc->findnodes("//file");
    foreach my $file (@files_nodes) {
        my $file_name = $file->getAttribute('name');
        my @violations = $file->findnodes("violation");
	
        foreach my $violation (@violations) {
            # Take care of violations
            my $violation_name = $violation->getAttribute('rule');
            if (exists($rules->{$violation_name})) {
                $ret{'violations'}{ $violation_name }{ 'vol' }++;
                $ret{'violations'}{ $violation_name }{ 'pri' } = $violation->getAttribute('priority');
                $ret{'violations'}{ $violation_name }{ 'ruleset' } = $violation->getAttribute('ruleset');
            }
            
            # Take care of files.
            my $rule = $violation->getAttribute('rule');
            my $pri = $violation->getAttribute('priority');
            my $ruleset = $violation->getAttribute('ruleset');
	    
            if (exists($rules->{$rule})) {
        	$ret{'files'}{$file}{'name'} = $file_name;
        	$ret{'files'}{$file}{'vol'}++;
        	$ret{'files'}{$file}{'rules'}{$rule}{'vol'}++;
        	$ret{'files'}{$file}{'rules'}{$rule}{'pri'} = $pri;
        	$ret{'files'}{$file}{'pri'}{$pri}++;
        	$ret{'rulesets'}{$ruleset}{$pri}++;
            } else {
        	print "WARN Could not find rule [$rule] from ruleset [$ruleset] in rules definition.\n";
            }
        }
	
    }

    return %ret;

}

1;
