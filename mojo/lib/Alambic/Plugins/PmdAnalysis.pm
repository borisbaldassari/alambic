package Alambic::Plugins::PmdAnalysis;

use strict;
use warnings;

use Alambic::Model::RepoFS;
use Alambic::Tools::R;

use Mojo::JSON qw( decode_json encode_json );
use Mojo::UserAgent;
use Data::Dumper;
use XML::LibXML;
use File::Copy;
use File::Basename;
use Text::CSV;


my %conf = (
  "id"   => "PmdAnalysis",
  "name" => "PMD Analysis",
  "desc" => [
    "This plugin summarises the output of a PMD run, provides hints to better understand and user it, and defines a pragmatic strategy to fix violations in an efficient way. It also provides guidance on how to configure PMD and select rules for a better, more focused analysis.",
    "Please note that this plugin only reads the XML configuration and output files of a PMD run. One has to execute it on a regular basis &em; ideally in a continuous integration job &em; and provide the XML files URLs to the plugin.",
    'Up-to-date documentation for the plugin is located on <a href="https://bitbucket.org/BorisBaldassari/alambic/wiki/Plugins/3.x/PMD%20Analysis">the project wiki</a>.',
  ],
  "type"    => "pre",
  "ability" => ['data', 'recs', 'figs', 'viz'],
  "params"  => {
    "url_pmd_xml"  => "The URL to the XML configuration file used to run PMD.",
    "url_pmd_conf" => "The URL to the XML PMD results for the project.",
  },
  "provides_cdata" => [],
  "provides_info"  => [],
  "provides_data"  => {
    "import_pmd_analysis_conf.xml" =>
      "The PMD configuration file retrieved for the analysis (XML).",
    "import_pmd_analysis_results.xml" =>
      "The PMD results file retrieved for the analysis (XML).",
    "pmd_analysis_main.csv" =>
      "Generic information about the project : PMD version, timestamp of analysis, number of non-conformities, number of rules checked, number of rules violated, number of clean rules, rate of acquired practices (CSV).",
    "pmd_analysis_files.csv" =>
      "Files: for each non-conform file, its name, total number of non-conformities, number of non-conformities for each priority, number of broken and clean rules, and the rate of acquired practices (CSV).",
    "pmd_analysis_rules.csv" =>
      "Rules: number of non-conformities for each category of rules and priority (CSV).",
    "pmd_analysis_violations.csv" =>
      "Violations: foreach violated rule, its priority, the ruleset it belongs to, and the volume of violations (CSV).",
    "pmd_analysis_violations.json" =>
      "Violations: foreach violated rule, its priority, the ruleset it belongs to, and the volume of violations (JSON).",
    "pmd_analysis_rulesets.csv" =>
      "Rulesets detected in analysis output, with number of violations for each priority, in long format (CSV).",
    "pmd_analysis_rulesets2.csv" =>
      "Rulesets detected in analysis output, with number of violations for each priority, in wide format (CSV).",
  },
  "provides_metrics" => {},
  "provides_figs"    => {
    'pmd_analysis_pie.html'       => 'Pie of PMD analysis results (HTML)',
    'pmd_analysis_files_ncc1.svg' => 'Non-conforimities by file (SVG)',
    'pmd_analysis_top_5_rules.svg' =>
      'Top 5 rules with most non-conformities (SVG)',
    'pmd_configuration_rulesets_repartition.svg' =>
      'Repartition of non-conformities across rulesets (SVG)',
    'pmd_configuration_summary_pie.html' =>
      'Pie of PMD configuration results (HTML)',
    'pmd_configuration_violations_rules.svg' =>
      'Non-conformities by rule (SVG)',
  },
  "provides_recs" => ["PMD_RULE_DEL", "PMD_FIX_RULE", "PMD_FIX_FILE",],
  "provides_viz"  => {
    "pmd_analysis.html"      => "PMD Analysis",
    "pmd_configuration.html" => "PMD Configuration",
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
sub run_plugin($$) {
  my ($self, $project_id, $conf) = @_;

  my %ret = ('metrics' => {}, 'info' => {}, 'recs' => [], 'log' => [],);

  # Create RepoFS object for writing and reading files on FS.
  my $repofs = Alambic::Model::RepoFS->new();

  my $url_xml  = $conf->{'url_pmd_xml'};
  my $url_conf = $conf->{'url_pmd_conf'};

  # Retrieve and store data from the remote repository.
  $ret{'log'} = &_retrieve_data($project_id, $url_xml, $url_conf, $repofs);

  # Analyse retrieved data, generate info, metrics, plots and visualisation.
  my $tmp_ret = &_compute_data($project_id, $repofs);

  $ret{'metrics'} = $tmp_ret->{'metrics'};
  $ret{'recs'}    = $tmp_ret->{'recs'};
  push(@{$ret{'log'}}, @{$tmp_ret->{'log'}});

  return \%ret;
}

sub _retrieve_data($$$$) {
  my ($project_id, $url_xml, $url_conf, $repofs) = @_;

  my @log;

  push(@log,
    "[Plugins::PmdAnalysis] Starting retrieve data for [$project_id].");

  my $ua          = Mojo::UserAgent->new;
  my $content_xml = $ua->get($url_xml)->res->body;
  if (length($content_xml) < 10) {
    push(@log, "[Plugins::PmdAnalysis] Cannot find [$url_xml].\n");
  }
  else {
    push(@log, "[Plugins::PmdAnalysis] Writing XML results file.");
    $repofs->write_input($project_id, "import_pmd_analysis_results.xml",
      $content_xml);
    $repofs->write_output($project_id, "import_pmd_analysis_results.xml",
      $content_xml);
  }

  my $content_conf = $ua->get($url_conf)->res->body;
  if (length($content_conf) < 10) {
    push(@log, "[Plugins::PmdAnalysis] Cannot find [$url_xml].\n");
  }
  else {
    push(@log, "[Plugins::PmdAnalysis] Writing XML conf file.");
    $repofs->write_input($project_id, "import_pmd_analysis_conf.xml",
      $content_conf);
    $repofs->write_output($project_id, "import_pmd_analysis_conf.xml",
      $content_conf);
  }

  return \@log;
}

sub _compute_data($$$) {
  my ($project_id, $repofs) = @_;

  my @recs;
  my @log;

  push(@log, "[Plugins::PmdAnalysis] Starting compute data for [$project_id].");

  my $debug = 0;

  # Reading rules from xml files.
  my $rules_def = &_read_pmd_rules();

  # Reading configuration file for project.
  my $ret = &_read_pmd_conf($project_id, $rules_def);
  my %rules = %{$ret->{'rules'}};
  @log = (@log, @{$ret->{'log'}});

  my $vol_rules = scalar keys %rules;
  push(@log, "Selected a total of [$vol_rules] rules.");

  # Read violations from xml file
  my $total_ncc;
  my %ret           = &_read_pmd_xml_files($project_id, \%rules);
  my %files         = %{$ret{'files'}};
  my %rulesets      = %{$ret{'rulesets'}};
  my %violations    = %{$ret{'violations'}};
  my $pmd_version   = $ret{'version'};
  my $pmd_timestamp = $ret{'timestamp'};

  # Loop over violations to find the total number of violations and
  # number of rules broken.
  foreach my $rule (keys %violations) {
    $rules{$rule}{'nok'} = 1;
    $total_ncc += $violations{$rule}{'vol'};
  }

  # Compute the rate of broken rules for each priority.
  my %rules_ok;
  foreach my $rule (keys %rules) {
    my $prio = $rules{$rule}{'pri'};
    if (exists($violations{$rule})) {
      $rules_ok{$prio}{'nok'}++;
    }
    else {
      $rules_ok{$prio}{'ok'}++;
    }
  }

  # Write the result to a csv file.
  my $csv_out = "Priority,ok,nok\n";
  foreach my $priority (sort keys %rules_ok) {
    my $ok  = $rules_ok{$priority}{'ok'}  || 0;
    my $nok = $rules_ok{$priority}{'nok'} || 0;
    $csv_out .= "$priority," . $ok . ", " . $nok . "\n";
  }

  # Write rules to a csv file
  $repofs->write_plugin('PmdAnalysis', $project_id . "_pmd_analysis_rules.csv",
    $csv_out);
  $repofs->write_output($project_id, "pmd_analysis_rules.csv", $csv_out);
  push(@log,
        "[PmdAnalysis] Writing rules to file ["
      . $project_id
      . "_pmd_analysis_rules.csv].");

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
    my $vol     = $violations{$violation}->{'vol'};
    my $pri     = $violations{$violation}->{'pri'};
    my $tmp_m   = "        {\n";
    $tmp_m   .= "            \"name\": \"$violation\",\n";
    $tmp_m   .= "            \"priority\": \"$pri\",\n";
    $tmp_m   .= "            \"ruleset\": \"$ruleset\",\n";
    $tmp_m   .= "            \"value\": \"$vol\"\n";
    $tmp_m   .= "        }";
    $csv_out .= "$violation,$pri,$ruleset,$vol\n";
    if ($start) {
      $json_violations = join("\n", $json_violations, $tmp_m);
      $start = 0;
    }
    else {
      $json_violations = join(", \n", $json_violations, $tmp_m);
    }
  }
  $json_violations .= "    ]\n";
  $json_violations .= "}\n";

  # Write violations to JSON.
  $repofs->write_plugin('PmdAnalysis',
    $project_id . "_pmd_analysis_violations.json",
    $json_violations);
  $repofs->write_output($project_id, "pmd_analysis_violations.json",
    $json_violations);

  # Write violations to CSV.
  $repofs->write_plugin('PmdAnalysis',
    $project_id . "_pmd_analysis_violations.csv", $csv_out);
  $repofs->write_output($project_id, "pmd_analysis_violations.csv", $csv_out);

  # Format and write number of violations by file.
  my $csv_files_out = "File,NCC,NCC_1,NCC_2,NCC_3,NCC_4,RKO,ROK,ROKR\n";

  # Loop over files and compute rate of acquired practices,
  # number of violations by priority and total number of violations.
  foreach my $file (keys %files) {
    my $file_name = $files{$file}{'name'};
    my $rko       = scalar keys %{$files{$file}{'rules'}};
    my $rok       = $vol_rules - $rko;
    my $rokr      = 100 * $rok / $vol_rules;
    my $ncc_1     = $files{$file}{'pri'}{1} || 0;
    my $ncc_2     = $files{$file}{'pri'}{2} || 0;
    my $ncc_3     = $files{$file}{'pri'}{3} || 0;
    my $ncc_4     = $files{$file}{'pri'}{4} || 0;

    if (defined($files{$file}{'vol'})) {
      $csv_files_out
        .= "$file_name,"
        . $files{$file}{'vol'}
        . ",$ncc_1,$ncc_2,$ncc_3,$ncc_4,$rko,$rok,$rokr\n";
    }
  }

  # Write files to a csv file
  push(@log,
        "[PmdAnalysis] Writing files to file ["
      . $project_id
      . "_pmd_analysis_files.csv]..");
  $repofs->write_plugin('PmdAnalysis', $project_id . "_pmd_analysis_files.csv",
    $csv_files_out);
  $repofs->write_output($project_id, "pmd_analysis_files.csv", $csv_files_out);

# Compute violations by ruleset. Two formats are provided for different purposes.
  my $csv_rulesets_out  = "Ruleset,NCC_1,NCC_2,NCC_3,NCC_4\n";
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
  push(@log,
        "[PmdAnalysis] Writing rulesets to file ["
      . $project_id
      . "_conf_rulesets.csv].");
  $repofs->write_plugin('PmdAnalysis',
    $project_id . "_pmd_analysis_rulesets.csv",
    $csv_rulesets_out);
  $repofs->write_output($project_id, "pmd_analysis_rulesets.csv",
    $csv_rulesets_out);

  # Write rulesets to CSV (second format).
  push(@log,
        "[PmdAnalysis] Writing rulesets2 to file ["
      . $project_id
      . "_conf_rulesets2.csv].");
  $repofs->write_plugin('PmdAnalysis',
    $project_id . "_pmd_analysis_rulesets2.csv",
    $csv_rulesets2_out);
  $repofs->write_output($project_id, "pmd_analysis_rulesets2.csv",
    $csv_rulesets2_out);

  # Write a summary of the run.
  my $total_rok  = $vol_rules - $total_rko;
  my $total_rokr = 100 * $total_rok / $vol_rules;

  my $csv_main_out = "PMD version,Timestamp,ConfFile,NCC,RULES,RKO,ROK,ROKR\n";
  $csv_main_out
    .= "$pmd_version,$pmd_timestamp,,$total_ncc,$vol_rules,$total_rko,$total_rok,$total_rokr\n";

  push(@log,
        "[PmdAnalysis] Writing main pmd file ["
      . $project_id
      . "_pmd_analysis_main.csv]..");
  $repofs->write_plugin('PmdAnalysis', $project_id . "_pmd_analysis_main.csv",
    $csv_main_out);
  $repofs->write_output($project_id, "pmd_analysis_main.csv", $csv_main_out);

  # Now execute the main R script.
  push(@log, "[Plugins::PmdAnalysis] Executing R main file for PMD Analysis.");
  my $r = Alambic::Tools::R->new();
  @log = (
    @log,
    @{$r->knit_rmarkdown_inc('PmdAnalysis', $project_id, "pmd_analysis.Rmd")}
  );

  push(@log,
    "[Plugins::PmdAnalysis] Executing R main file for PMD Configuration.");
  @log = (
    @log,
    @{
      $r->knit_rmarkdown_inc('PmdAnalysis', $project_id,
        "pmd_configuration.Rmd")
    }
  );

  # Read the recommendations from scv file.
  my $csv
    = Text::CSV->new(
    {sep_char => ',', binary => 1, quote_char => '"', auto_diag => 1})
    or die "" . Text::CSV->error_diag();

  my $recs_top_10_s = $repofs->read_plugin("PmdAnalysis",
    $project_id . "_pmd_analysis_exclude_rules.csv");
  my @lines = split(/\n/, $recs_top_10_s);

  # First line is for headers.
  shift(@lines);
  foreach my $line (@lines) {
    $csv->parse($line);
    my @cols = $csv->fields();
    push(
      @recs,
      {
        'rid'      => 'PMD_RULES_DEL',
        'severity' => 2,
        'src'      => 'PmdAnalysis',
        'desc'     => 'PMD rule '
          . $cols[0]
          . ' has too many violations ('
          . $cols[2]
          . ') and a low priority ('
          . $cols[1]
          . '). This will discourage '
          . 'people to act on it, and produces unnecessary noise. The rule should be '
          . 'disabled for a more pragmatic use of PMD results.',
      }
    );
  }

  my $recs_top_5_rules_s = $repofs->read_plugin("PmdAnalysis",
    $project_id . "_pmd_analysis_top_5_rules.csv");
  @lines = split(/\n/, $recs_top_5_rules_s);

  # First line is for headers.
  shift(@lines);
  foreach my $line (@lines) {
    $csv->parse($line);
    my @cols = $csv->fields();
    push(
      @recs,
      {
        'rid'      => 'PMD_FIX_RULES',
        'severity' => 1,
        'src'      => 'PmdAnalysis',
        'desc'     => 'PMD rule '
          . $cols[0]
          . ' has only a few violations ('
          . $cols[2]
          . ') and a high priority ('
          . $cols[1]
          . '). It would be easy '
          . 'to work on this rule and the associated good practice, both for the '
          . 'project and for the team experience, and fix all violations associated to '
          . 'this rule.',
      }
    );
  }

  my $recs_top_10_files_s = $repofs->read_plugin("PmdAnalysis",
    $project_id . "_pmd_analysis_top_10_files.csv");
  @lines = split(/\n/, $recs_top_10_files_s);

  # First line is for headers.
  shift(@lines);
  foreach my $line (@lines) {
    $csv->parse($line);
    my @cols = $csv->fields();
    push(
      @recs,
      {
        'rid'      => 'PMD_FIX_FILES',
        'severity' => 1,
        'src'      => 'PmdAnalysis',
        'desc'     => 'The file '
          . $cols[0]
          . ' has only '
          . $cols[1]
          . ' P1 violations and '
          . $cols[2] . ' P2 '
          . ' violations. It would be quite easy to fix these in one shot '
          . 'and seriously improve the file\'s quality.',
      }
    );
  }

  # And execute the figures R scripts.
  @log = (
    @log,
    @{
      $r->knit_rmarkdown_html('PmdAnalysis', $project_id,
        "pmd_analysis_pie.rmd")
    }
  );
  @log = (
    @log,
    @{
      $r->knit_rmarkdown_html('PmdAnalysis', $project_id,
        "pmd_configuration_summary_pie.rmd")
    }
  );
  my @files_r = (
    'pmd_analysis_files_ncc1',
    'pmd_analysis_top_5_rules',
    'pmd_configuration_rulesets_repartition',
    'pmd_configuration_violations_rules'
  );
  foreach my $file_r (@files_r) {
    @log = (
      @log,
      @{
        $r->knit_rmarkdown_images(
          'PmdAnalysis', $project_id,
          $file_r . '.r',
          [$file_r . '.svg']
        )
      }
    );
  }


  return {"recs" => \@recs, "log" => \@log,};
}


#
# Read the rules definition files for PMD. These are stored in a directory within
# the plugin dir. Returns a hash of rules.
#
sub _read_pmd_rules() {

  my %rules_def;

  my $pmd_rules = "lib/Alambic/Plugins/PmdAnalysis/rules/";

  my @rules_files = <$pmd_rules/*.xml>;
  my $rules_vol   = 0;

  # For each file, read, parse and store it in %rules_def.
  foreach my $file_rules (@rules_files) {
    my $ruleset = basename($file_rules);

    my $parser = XML::LibXML->new;
    my $doc    = $parser->parse_file($file_rules);

    my @ruleset_node = $doc->getElementsByTagName("ruleset");
    my $rules_name   = $ruleset_node[0]->getAttribute("name");

    my @rule_nodes = $ruleset_node[0]->getElementsByTagName("rule");

    foreach my $rule_child (@rule_nodes) {
      my $rule_disabled = $rule_child->getAttribute("ref");
      if (defined($rule_disabled)) { next; }

      my $rule_name     = $rule_child->getAttribute("name");
      my $rule_desc     = $rule_child->getAttribute("message");
      my @rule_priority = $rule_child->getChildrenByTagName("priority");
      my $priority      = $rule_priority[0]->textContent();
      $rules_def{$ruleset}{$rule_name}{'desc'} = $rule_desc;
      $rules_def{$ruleset}{$rule_name}{'pri'}  = $priority;
      $rules_vol++;
    }
  }

  return \%rules_def;
}


#
# Read the XML file used for PMD configuration. Returns a hash of
# rules used for this run, providing some info about each rule.
#
sub _read_pmd_conf($$) {
  my $project_id = shift;
  my $rules_def  = shift;

  my @log;
  my $debug = 0;

  my $pmd_conf
    = "projects/"
    . $project_id
    . "/input/"
    . $project_id
    . "_import_pmd_analysis_conf.xml";

  # Read pmd xml results file.
  my $parser = XML::LibXML->new;
  my $doc    = $parser->parse_file($pmd_conf);

  my %rules;

  my @ruleset_node = $doc->getElementsByTagName("ruleset");
  my $rules_name   = $ruleset_node[0]->getAttribute("name");
  my @rule_nodes   = $ruleset_node[0]->getElementsByTagName("rule");

  my $vol_rules;
  foreach my $rule_child (@rule_nodes) {
    my $rule_ref       = $rule_child->getAttribute("ref");
    my $ruleset_name   = "undefined";
    my $file_vol_rules = 0;

    my @included_rules;

    if ($rule_ref =~ m!^(.*\.xml)(/(.*))?$!) {
      $ruleset_name = basename($1);
      if (defined($2)) {
        push(@included_rules, $3);
      }
      else {
        @included_rules = keys %{$rules_def->{$ruleset_name}};
      }
    }
    else {
      push(@log, "[PmdAnalysis] ERR could not parse rule ref [$rule_ref].");
    }

    my @excluded_rules = $rule_child->getElementsByTagName("exclude");
    my %excluded;
    foreach my $excluded_rule (@excluded_rules) {
      my $name = $excluded_rule->getAttribute("name");
      $excluded{$name}++;
    }

    foreach my $rule (@included_rules) {
      if (exists($excluded{$rule})) {
        next;
      }
      else {
        $rules{$rule} = $rules_def->{$ruleset_name}{$rule};
        $file_vol_rules++;
      }
    }
    $vol_rules += $file_vol_rules;

    push(@log,
      "[PmdAnalysis] Imported [$file_vol_rules] rules from ruleset [$ruleset_name]."
    );
  }

  return {'rules' => \%rules, 'log' => \@log};
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
  my $rules      = shift;

  my %ret;

  my $pmd_xml
    = "projects/"
    . $project_id
    . "/input/"
    . $project_id
    . "_import_pmd_analysis_results.xml";

  if (not -e $pmd_xml) { print "### XML file does'nt exist!!\n" }

  my $parser = XML::LibXML->new;
  my $doc    = $parser->parse_file($pmd_xml);

  my $pmd_node = $doc->findnodes("/pmd");
  $ret{'version'}   = $pmd_node->[0]->getAttribute("version");
  $ret{'timestamp'} = $pmd_node->[0]->getAttribute("timestamp");

 # XML results file is organised as follows:
 # <file name="file_name.java">
 #   <violation rule="UncommentedEmptyConstructor" ruleset="Design"></violation>
 # </file>
  my @files_nodes = $doc->findnodes("//file");
  foreach my $file (@files_nodes) {
    my $file_name  = $file->getAttribute('name');
    my @violations = $file->findnodes("violation");

    foreach my $violation (@violations) {

      # Take care of violations
      my $rule    = $violation->getAttribute('rule');
      my $ruleset = $violation->getAttribute('ruleset');
      if (exists($rules->{$rule})) {
        my $pri = $violation->getAttribute('priority');

        $ret{'violations'}{$rule}{'vol'}++;
        $ret{'violations'}{$rule}{'pri'} = $violation->getAttribute('priority');
        $ret{'violations'}{$rule}{'ruleset'}
          = $violation->getAttribute('ruleset');
        $ret{'files'}{$file_name}{'name'} = $file_name;
        $ret{'files'}{$file_name}{'vol'}++;
        $ret{'files'}{$file_name}{'rules'}{$rule}{'vol'}++;
        $ret{'files'}{$file_name}{'rules'}{$rule}{'pri'} = $pri;
        $ret{'files'}{$file_name}{'pri'}{$pri}++;
        $ret{'rulesets'}{$ruleset}{$pri}++;
      }
      else {
#        	$app->log->info( "[PmdAnalysis] WARN Could not find rule [$rule] from ruleset [$ruleset] in rules definition." );
      }
    }

  }

  return %ret;
}

1;
