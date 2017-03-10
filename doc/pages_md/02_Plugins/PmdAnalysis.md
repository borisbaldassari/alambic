title: PMD Analysis
navi_name: PmdAnalysis


# PMD Analysis and Configuration

This plugin summarises the output of a PMD run, provides hints to better understand and user it, and defines a pragmatic strategy to fix violations in an efficient way. It also provides guidance on how to configure PMD and select rules for a better, more focused analysis.
Please note that this plugin only reads the XML configuration and output files of a PMD run. One has to execute it on a regular basis &em; ideally in a continuous integration job &em; and provide the XML files URLs to the plugin.

-----

# Basic information

* **ID**: PmdAnalysis
* **Abilities**:   metrics   data   recs   figs   viz
* **Description**:
  Eclipse ITS retrieves bug tracking system data from the Eclipse dashboard repository. This plugin will look for a file named project-its-prj-static.json on the Eclipse dashboard.
  See the project's wiki for more information.
* **Parameters**:
    * url_pmd_conf The URL to the XML configuration file used to run PMD.
    * url_pmd_xml The URL to the XML PMD results for the project.

-----

# Provides

## Information

## Metrics

## Figures

pmd_analysis_files_ncc1.svg, pmd_analysis_pie.html, pmd_analysis_top_5_rules.svg, pmd_configuration_rulesets_repartition.svg, pmd_configuration_summary_pie.html, pmd_configuration_violations_rules.svg

## Downloads

* import_pmd_analysis_conf.xml: The PMD configuration file retrieved for the analysis (XML).
* import_pmd_analysis_results.xml: The PMD results file retrieved for the analysis (XML).
* pmd_analysis_files.csv: Files: for each non-conform file, its name, total number of non-conformities, number of non-conformities for each priority, number of broken and clean rules, and the rate of acquired practices (CSV).
* pmd_analysis_main_csv: Generic information about the project : PMD version, timestamp of analysis, number of non-conformities, number of rules checked, number of rules violated, number of clean rules, rate of acquired practices (CSV).
* pmd_analysis_rules.csv: Rules: number of non-conformities for each category of rules and priority (CSV).
* pmd_analysis_rulesets.csv: Rulesets detected in analysis output, with number of violations for each priority, in long format (CSV).
* pmd_analysis_rulesets2.csv: Rulesets detected in analysis output, with number of violations for each priority, in wide format (CSV).
* pmd_analysis_violations.csv: Violations: foreach violated rule, its priority, the ruleset it belongs to, and the volume of violations (CSV).
* pmd_analysis_violations.json: Violations: foreach violated rule, its priority, the ruleset it belongs to, and the volume of violations (JSON).

## Recommendations

PMD_FIX_FILE, PMD_FIX_RULE, PMD_RULE_DEL

## Visualisation

PMD Analysis, PMD Configuration

-----

# Screenshot

![pmd_analysis.png](/images/pmd_analysis.png)