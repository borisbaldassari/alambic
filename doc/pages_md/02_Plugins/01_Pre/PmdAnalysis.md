title: PMD Analysis
navi_name: PmdAnalysis


# PMD Analysis and Configuration

# Purpose

[PMD](https://pmd.github.io) is an open-source, well-known and widely used static analysis tool for Java.

This plugin summarises the output of a PMD run, provides hints to better understand and use it, and defines a pragmatic strategy to fix violations in an efficient way. It also provides guidance on how to configure PMD and select rules for a better, more focused analysis. More precisely, this document:

* Lists the rulesets used, with the associated number and priority of violations. It help users understand the scope of the different rulesets they use.
* Proposes to remove from the configuration a list of rules that have a huge number of violations associated with a low priority. Such rules are useless, because the project does not have the maturity to tackle it yet, and it clutters the results. Not to speak about the despair it induces in teams.
* Proposes steps for continuous improvement, once the former has been addressed.

Note on rules: There should be a rules directory where the plugin is, with the definition of the PMD rulesets to be analysed. You can extract them from the PMD jars (e.g. lib/pmd-java-5.2.3/rulesets/java*.xml) to match the version of PMD you are using.

Please note that this plugin only reads the XML configuration and output files of a PMD run. One has to execute it on a regular basis -- ideally in a continuous integration job -- and provide the XML files URLs to the plugin.

Check the [plugin Perl documentation](http://alambic.io/perldoc/Alambic/Plugins/PmdAnalysis.pm.html) in the [perldoc](http://alambic.io/perldoc/index.html) section.

-----

# Basic information

* **ID**: PmdAnalysis
* **Abilities**:   metrics   data   recs   figs   viz
* **Description**:
  This plugin summarises the output of a PMD run, provides hints to better understand and user it, and defines a pragmatic strategy to fix violations in an efficient way. It also provides guidance on how to configure PMD and select rules for a better, more focused analysis.
  Please note that this plugin only reads the XML configuration and output files of a PMD run. One has to execute it on a regular basis -- ideally in a continuous integration job -- and provide the XML files URLs to the plugin.
  Up-to-date documentation for the plugin is located on [the project wiki](http://alambic.io/Plugins/Pre/PmdAnalysis.html).',
* **Parameters**:
    * `url_pmd_conf` The URL to the XML configuration file used to run PMD.
    * `url_pmd_xml` The URL to the XML PMD results for the project.

-----

# Provides

## Information

## Metrics

## Figures

pmd_analysis_files_ncc1.svg, pmd_analysis_pie.html, pmd_analysis_top_5_rules.svg, pmd_configuration_rulesets_repartition.svg, pmd_configuration_summary_pie.html, pmd_configuration_violations_rules.svg

## Downloads

* `import_pmd_analysis_conf.xml`: The PMD configuration file retrieved for the analysis (XML).
* `import_pmd_analysis_results.xml`: The PMD results file retrieved for the analysis (XML).
* `pmd_analysis_files.csv`: Files: for each non-conform file, its name, total number of non-conformities, number of non-conformities for each priority, number of broken and clean rules, and the rate of acquired practices (CSV).
* `pmd_analysis_main_csv`: Generic information about the project : PMD version, timestamp of analysis, number of non-conformities, number of rules checked, number of rules violated, number of clean rules, rate of acquired practices (CSV).
* `pmd_analysis_rules.csv`: Rules: number of non-conformities for each category of rules and priority (CSV).
* `pmd_analysis_rulesets.csv`: Rulesets detected in analysis output, with number of violations for each priority, in long format (CSV).
* `pmd_analysis_rulesets2.csv`: Rulesets detected in analysis output, with number of violations for each priority, in wide format (CSV).
* `pmd_analysis_violations.csv`: Violations: foreach violated rule, its priority, the ruleset it belongs to, and the volume of violations (CSV).
* `pmd_analysis_violations.json`: Violations: foreach violated rule, its priority, the ruleset it belongs to, and the volume of violations (JSON).

## Recommendations

* PMD_FIX_FILE,
* PMD_FIX_RULE,
* PMD_RULE_DEL

## Visualisation

PMD Analysis, PMD Configuration

-----

# Screenshot

![pmd_analysis.png](/images/pmd_analysis.png)
