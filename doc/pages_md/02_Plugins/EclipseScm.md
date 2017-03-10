title: Eclipse SCM
navi_name: EclipseScm


# Eclipse SCM

This plugins retrieves software configuration management information from the [Eclipse Dashboard's server](http://dashboard.eclipse.org) and produces evolution graphics and various analyses.

All data from the Eclipse dashboard can be downloaded from the server in JSON format at the following url:

* All files: http://dashboard.eclipse.org/data/json/
* Project-specific file (last metrics): http://dashboard.eclipse.org/data/json/modeling.sirius-scm-prj-static.json
* Project-specific file (evolution metrics): http://dashboard.eclipse.org/data/json/modeling.sirius-scm-prj-evolutionary.json

-----

# Basic information

* **ID**: EclipseScm
* **Abilities**:   metrics   data   recs   figs   viz
* **Description**:
  Eclipse ITS Retrieves configuration management data from the Eclipse dashboard repository. This plugin will look for a file named project-scm-prj-static.json on http://dashboard.eclipse.org/data/json/.
* **Parameters**:
    * project_grim The project ID used to identify the project on the dashboard server. Note that it may be different from the id used in the PMI.

-----

# Provides

## Information

## Metrics

SCM_AUTHORS, SCM_AUTHORS_30, SCM_AUTHORS_365, SCM_AUTHORS_7, SCM_AVG_COMMITS_AUTHOR, SCM_AVG_COMMITS_MONTH, SCM_COMMITS, SCM_COMMITS_30, SCM_COMMITS_365, SCM_COMMITS_7, SCM_COMMITTERS, SCM_DIFF_NETAUTHORS_30, SCM_DIFF_NETAUTHORS_365, SCM_DIFF_NETAUTHORS_7, SCM_DIFF_NETCOMMITS_30, SCM_DIFF_NETCOMMITS_365, SCM_DIFF_NETCOMMITS_7, SCM_FILES, SCM_PERCENTAGE_AUTHORS_30, SCM_PERCENTAGE_AUTHORS_365, SCM_PERCENTAGE_AUTHORS_7, SCM_PERCENTAGE_COMMITS_30, SCM_PERCENTAGE_COMMITS_365, SCM_PERCENTAGE_COMMITS_7, SCM_REPOSITORIES

## Figures
scm_evol_commits.html, scm_evol_lines.html, scm_evol_people.html, scm_evol_summary.html, scm_evol_summary_lines.html

## Downloads

* import_scm.json: The original file of current metrics downloaded from the Eclipse dashboard server (JSON).
* metrics_scm.csv: Current metrics for the SCM plugin (CSV).
* metrics_scm.json: Current metrics for the SCM plugin (JSON).
* metrics_scm_evol.csv: Evolution metrics for the SCM plugin (CSV).
* metrics_scm_evol.json: Evolution metrics for the SCM plugin (JSON).

## Recommendations

SCM_CLOSE_BUGS

## Visualisation

Eclipse SCM

-----

# Screenshot

![eclipse_scm.png](/images/eclipse_scm.png)
