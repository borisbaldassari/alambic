title: Scancode
navi_name: Scancode


# Scancode

# Purpose

This plugin runs the [Scancode](https://github.com/nexB/scancode-toolkit) software on the git repository defined for the project, and displays results in a user-friendly report

 ScanCode detects licenses, copyrights, package manifests and dependencies and more by scanning code to discover and inventory open source and third-party packages used in code.

Check the [plugin Perl documentation](/perldoc/Alambic/Plugins/Scancode.pm.html) in the [perldoc](/perldoc/index.html) section.

-----

# Basic information

* **ID**: Scancode
* **Abilities**:   metrics   data    figs   viz
* **Description**:
  The Scancode plugin enables users to easily scan their codebase for license issues. See [the project\'s wiki](https://alambic.io/Plugins/Pre/Scancode) for more information.
* **Parameters**:
  * `dir_bin` The full path to the binary, e.g. /opt/scancode/scancode.
  * `licence_regexp` A regular expression that describes the correct licence. Every licence that does not match this regexp will be considered wrong.

-----

# Provides

## Metrics

* SC_LICENSES_VOL
  Number of licences detected by Scancode in the code base.
* SC_LIC_CHECK
  Number of non-expected licences, as defined by the regular expression passed as parameter.
* SC_COPYRIGHTS_VOL
  Number of copyrights detected by Scancode in the code base.
* SC_HOLDERS_VOL
  Number of copyright holders detected in the code.
* SC_AUTHORS_VOL
  Number of authors detected in the code.
* SC_PROGS_VOL
  Number of programming languages detected in the code.
* SC_FILES_VOL
  Total number of files analysed (and documented) by Scancode. Metric is the number of files provided in the list of analysed files returned by Scancode.
* SC_FILES_COUNT
  Total number of files as detected by Scancode. Metric comes from the attribute in the returned data.
* SC_GENERATED_VOL
  Number of files tagged as automatically generated, as detected by Scancode.
* SC_SPECIAL_FILES
  Number of legal, license, readmes, manifests, copyright and other files for key, top-level files.
  Key files are top- level codebase files such as COPYING, README and package manifests as reported by the --classify option “is_legal”, “is_readme”, “is_manifest” and “is_top_level” flags.
* SC_HAS_LICENCE
  The number of files considered as legal (i.e. licences), as detected by Scancode.
* SC_HAS_CODEOFCONDUCT
  The number of files considered as code of conduct's, as detected by Scancode.
* SC_HAS_README
  The number of files considered as readme's, as detected by Scancode.
* SC_HAS_CONTRIBUTING
  The number of files considered as contributing guides, as detected by Scancode.

## Figures

* scancode_licences.html
  Pie chart of licences detected in the codebase. (HTML)
* scancode_copyrights.html
  Pie chart of copyrights detected in the codebase. (HTML)
* scancode_authors.html
  Pie chart of authors detected in the codebase. (HTML)
* scancode_holders.html
  Pie chart of holders detected in the codebase. (HTML)
* scancode_programming_languages.html
  Pie chart of programming languages detected in the codebase. (HTML)

## Downloads

* scancode.json: The JSON output of the Scancode execution (JSON).
* scancode_files.csv: The CSV list of all files analysed by Scancode (CSV).
* scancode_special_files.csv: The CSV list of all special files (JSCSVON).
* scancode_licences.csv: The CSV extract of all license expressions found in files (CSV).
* scancode_copyrights.csv: The CSV extract of all copyrights found in files (CSV).
* scancode_copyrights.csv: The CSV extract of all holders found in files (CSV).
* scancode_authors.csv: The CSV extract of all holders authors in files (CSV).
* scancode_programming_languages.csv: The CSV extract of all programming languages found in files (CSV).
* scancode_packages.csv: The CSV extract of all packages identified in sources (CSV).

## Recommendations

## Visualisation

Scancode

-----

# Screenshot

![sonarqube.png](/images/sonarqube_45.png)
