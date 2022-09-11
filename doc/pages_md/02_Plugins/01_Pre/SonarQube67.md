title: SonarQube 6.7.x
navi_name: SonarQube67


# SonarQube 6.7.x

# Purpose

This plugin retrieves information from a [SonarQube 6.7.x instance](https://sonarqube.org).

Please note that SonarQube changes its API at a unusual high rate. As a consequence different versions of SonarQube may not work with this plugin.

Check the [plugin Perl documentation](/perldoc/Alambic/Plugins/SonarQube.pm.html) in the [perldoc](/perldoc/index.html) section.

-----

# Basic information

* **ID**: SonarQube67
* **Abilities**:   metrics   info data    figs   viz
* **Description**:
  Retrieves information from a SonarQube 6.7.x instance (i.e. metrics and violations), and visualises them.
  Check the documentation for this plugin on the project wiki: [http://alambic.io/Plugins/Pre/SonarQube45.html](http://alambic.io/Plugins/Pre/SonarQube45.html).
* **Parameters**:
  * `sonar_url` The base URL of the SonarQube 4.5.x instance.
  * `sonar_project` The ID of the project within the SonarQube instance.
  * `proxy` If a proxy is required to access the remote resource of this plugin, please provide its URL here. A blank field means no proxy, and the `default` keyword uses the proxy from environment variables, see <a href="https://alambic.io/Documentation/Admin/Projects.html">the online documentation about proxies</a> for more details. Example: <code>https://user:pass@proxy.mycorp:3777</code>.

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
* SQ_STATEMENTS
  Number of statements.
  For Java, it is the number of statements as defined in the Java Language Specification but without block definitions. Statements counter gets incremented by one each time a following keyword is encountered: `if, else, while, do, for, switch, break, continue, return, throw, synchronized, catch, finally`.
  Statements counter is not incremented by a class, method, field, annotation definition, package declaration and import declaration.
  For Cobol, a statement is one of `move, if, accept, add, alter, call, cancel, close, compute, continue, delete, display, divide, entry, evaluate, exitProgram, goback, goto, initialize, inspect, merge, multiply, open, perform, read, release, return, rewrite, search, set, sort, start, stop, string, subtract, unstring, write, exec, ibmXmlParse, ibmXmlGenerate, readyReset, mfCommit, mfRollback`.
* SQ_COMMENT_LINES
  Number of lines containing either comment or commented-out code.
  Non-significant comment lines (empty comment lines, comment lines containing only special characters, etc.) do not increase the number of comment lines.
  For Java, file headers are not counted as comment lines (as they usually define the license).
  Lines containing the following instructions are counted both as comments and lines of code: AUTHOR, INSTALLATION, DATE-COMPILED, DATE-WRITTEN, SECURITY.
* SQ_COMR
  Density of comment lines = Comment lines / (Lines of code + Comment lines) * 100.
  With such a formula, 50% means that the number of lines of code equals the number of comment lines and 100% means that the file only contains comment lines
* SQ_CPX
  It is the complexity calculated based on the number of paths through the code. Whenever the control flow of a function splits, the complexity counter gets incremented by one. Each function has a minimum complexity of 1. This calculation varies slightly by language because keywords and functionalities do.
  For more information on line counting for each language, see [https://docs.sonarqube.org/display/SONAR/Metrics+-+Complexity](https://docs.sonarqube.org/display/SONAR/Metrics+-+Complexity).
* SQ_CPX_FILE_IDX
  Average complexity by file.
* SQ_CPX_CLASS_IDX
* SQ_CPX_FUNC_IDX
* SQ_COVERAGE
  Overall test coverage.
* SQ_PUBLIC_API
  Number of public Classes + number of public Functions + number of public Properties
* SQ_PUBLIC_API_DOC_DENSITY
  Density of public documented API = (Public API - Public undocumented API) / Public API * 100
* SQ_PUBLIC_UNDOC_API
* SQ_FILES_CYCLES
* SQ_PACKAGES_CYCLES
* SQ_PACKAGES_TANGLE_IDX
* SQ_COM_CODE
  Commented lines of code
  See more information about commented code on the [SonarQube doc web site](https://blog.sonarsource.com/commented-out-code-eradication-with-sonar/). There is a well-documented debate on [Stack Overflow](http://softwareengineering.stackexchange.com/questions/190096/can-commented-out-code-be-valuable-documentation) as well.
* SQ_TESTS
* SQ_TEST_SUCCESSFUL_DENSITY
* SQ_COVERAGE_LINE
  Line test coverage.
* SQ_COVERAGE_BRANCH
  Branch test coverage.
* SQ_DUPLICATED_LINES

* SQ_DUPLICATED_BLOCKS

* SQ_DUPLICATED_FILES

* SQ_DUPLICATED_LINES_DENSITY

* SQ_VIOLATIONS

* SQ_VIOLATIONS_BLOCKER
  The total number of issues (violations) found by SonarQube with a severity equal to BLOCKER.
* SQ_VIOLATIONS_CRITICAL
  The total number of issues (violations) found by SonarQube with a severity equal to CRITICAL.
* SQ_VIOLATIONS_MAJOR
  The total number of issues (violations) found by SonarQube with a severity equal to MAJOR.
* SQ_VIOLATIONS_MINOR
  The total number of issues (violations) found by SonarQube with a severity equal to MINOR.
* SQ_VIOLATIONS_INFO
  The total number of issues (violations) found by SonarQube with a severity equal to INFO.
* SQ_ISSUES_OPEN

* SQ_ISSUES_UNREVIEWED


## Figures

* sonarqube_violations_bar.svg
  Repartition of violations severity (SVG)
* sonarqube_violations_pie.html
  Pie chart of repartition of violations severity (HTML)
* sonarqube_summary.html
  Summary of main SonarQube metrics (HTML)
* sonarqube_violations.html
  Summary of SonarQube violations (HTML)

## Downloads

* import_sq_issues_blocker.json: The original list of blocker issues as sent out by SonarQube (JSON).
* import_sq_issues_critical.json: The original list of critical issues as sent out by SonarQube (JSON).
* import_sq_issues_major.json: The original list of major issues as sent out by SonarQube (JSON).
* sq_issues_blocker.csv: A list of all blocker issues for the project (CSV).
* sq_issues_critical.csv: A list of all critical issues for the project (CSV).
* sq_issues_major.csv: A list of all major issues for the project (CSV).
* sq_metrics.csv: A list of all metrics with their values (CSV).

## Recommendations

## Visualisation

SonarQube

-----

# Screenshot

![sonarqube.png](/images/sonarqube_45.png)
