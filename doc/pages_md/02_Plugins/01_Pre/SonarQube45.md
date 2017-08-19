title: SonarQube 4.5.x
navi_name: SonarQube45


# SonarQube 4.5.x

# Purpose

This plugin retrieves information from a Sonarueb 4.5.x instance.

Please note that SonarQube changes its API at a unusual high rate. As a consequence different versions of SonarQube may not work with this plugin.

-----

# Basic information

* **ID**: SonarQube45
* **Abilities**:   metrics   info data    figs   viz
* **Description**:
  Retrieves information from a SonarQube 4.5.x instance (i.e. metrics and violations), and visualises them.",
  Check the documentation for this plugin on the project wiki: [http://alambic.io/Plugins/Pre/SonarQube45.html](http://alambic.io/Plugins/Pre/SonarQube45.html).
* **Parameters**:
  * `sonar_url` The base URL of the SonarQube 4.5.x instance.
  * `sonar_project` The ID of the project within the SonarQube instance.

-----

# Provides

## Information

* SQ_URL
  The URL of the project within the SonarQube instance.

## Metrics

* SQ_NCLOC
  Number of physical lines that contain at least one character which is neither a whitespace or a tabulation or part of a comment.
  For Cobol, generated lines of code and pre-processing instructions (SKIP1, SKIP2, SKIP3, COPY, EJECT, REPLACE) are not counted as lines of code.
* SQ_FILES
  The total number of files analysed.
* SQ_FUNCS
  Number of functions. Depending on the language, a function is either a function or a method or a paragraph.
  For Java, constructors are considered as methods and accessors are considered as methods if the sonar.squid.analyse.property.accessors property is set to false.
  For Cobol, it is the number of paragraphs.

## Figures

pmd_analysis_files_ncc1.svg, pmd_analysis_pie.html, pmd_analysis_top_5_rules.svg, pmd_configuration_rulesets_repartition.svg, pmd_configuration_summary_pie.html, pmd_configuration_violations_rules.svg

## Downloads

* import_sq_issues_blocker.json: The original list of blocker issues as sent out by SonarQube (JSON).
* import_sq_issues_critical.json: The original list of critical issues as sent out by SonarQube (JSON).
* import_sq_issues_major.json: The original list of major issues as sent out by SonarQube (JSON).
* sq_issues_blocker.csv: A list of all blocker issues for the project (CSV).
* sq_issues_critical.csv: A list of all critical issues for the project (CSV).
* sq_issues_major.csv: A list of all major issues for the project (CSV).
* sq_metrics.csv: A list of all metrics with their values (CSV).

## Recommendations

PMD_FIX_FILE, PMD_FIX_RULE, PMD_RULE_DEL

## Visualisation

PMD Analysis, PMD Configuration

-----

# Screenshot

![pmd_analysis.png](/images/pmd_analysis.png)
