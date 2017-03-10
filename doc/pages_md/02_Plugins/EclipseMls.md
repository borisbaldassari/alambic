title: Eclipse MLS
navi_name: EclipseMls


# Eclipse MLS

This plugin retrieves mailing lists and forums information from the [Eclipse Dashboard's server](http://dashboard.eclipse.org) and produces evolution graphics and various analyses.

All data from the Eclipse dashboard can be downloaded from the server in JSON format at the following url:

* All files: http://dashboard.eclipse.org/data/json/
* Project-specific file (last metrics): http://dashboard.eclipse.org/data//json/modeling.sirius-mls-prj-static.json
* Project-specific file (evolution metrics): http://dashboard.eclipse.org/data//json/modeling.sirius-mls-prj-evolutionary.json

-----

# Basic information

* **ID**: EclipseMls
* **Abilities**:   metrics   data   recs   figs   viz
* **Description**:
  Eclipse ITS Retrieves mailing list data from the Eclipse dashboard repository. This plugin will look for a file named project-mls-prj-static.json on http://dashboard.eclipse.org/data/json/.
* **Parameters**:
    * project_grim The project ID used to identify the project on the dashboard server. Note that it may be different from the id used in the PMI.

-----

# Provides

## Information

## Metrics

MLS_DIFF_NETSENDERS_30, MLS_DIFF_NETSENDERS_365, MLS_DIFF_NETSENDERS_7, MLS_DIFF_NETSENT_30, MLS_DIFF_NETSENT_365, MLS_DIFF_NETSENT_7, MLS_PERCENTAGE_SENDERS_30, MLS_PERCENTAGE_SENDERS_365, MLS_PERCENTAGE_SENDERS_7, MLS_PERCENTAGE_SENT_30, MLS_PERCENTAGE_SENT_365, MLS_PERCENTAGE_SENT_7, MLS_REPOSITORIES, MLS_SENDERS, MLS_SENDERS_30, MLS_SENDERS_365, MLS_SENDERS_7, MLS_SENDERS_RESPONSE, MLS_SENT, MLS_SENT_30, MLS_SENT_365, MLS_SENT_7, MLS_SENT_RESPONSE, MLS_THREADS

## Figures
mls_evol_people.html, mls_evol_sent.html, mls_evol_summary.html

## Downloads

* import_mls.json: The original file of current metrics from the Eclipse dashboard server (JSON).
* metrics_mls.csv: Current metrics for the MLS plugin (CSV).
* metrics_mls.json: Current metrics for the MLS plugin (JSON).
* metrics_mls_evol.csv: Evolution metrics for the MLS plugin (CSV).
* metrics_mls_evol.json: Evolution metrics for the MLS plugin (JSON).

## Recommendations

MLS_SENT

## Visualisation

Eclipse MLS

-----

# Screenshot

![eclipse_mls.png](https://bitbucket.org/repo/b48zyo/images/4252560111-eclipse_mls.png)
