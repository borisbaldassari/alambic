title: Dashboard > Summary
navi_name: Summary

# Dashboard > Summary

![Alambic web UI](/images/users_summary.png)

The summary shows the main information and figures about the project.

* Main project information:
  * **ID** The unique identifier of the project.
  * **Name** The human name of the project.
  * **Description** A short description of the project.
  * **Last analysis** provides information on the last analysis: who started it, when, and how long it took.

## Main results

* **Quality Model** shows the value of main quality attributes, with links to the documentation.
* **Downloads** provides download links to information, metrics, attributes, recommendations and quality model in JSON format.
* **Data Providers** lists all Pre plugins defined for the project, with links to the documentation and the plugin's page. The abilities for each plugins (metrics, info, data, recommendations, visualisation, etc.) are also shown for each plugin.

## List of data

![Alambic web UI](/images/users_summary_recs.png)

Displays the list of items computed from the last analysis run, in collapsable panels:

* **Information** (e.g. `GIT_URL`, `PMI_MAIN_URL`)
* **Metrics** with their description and values
* **Attributes** with their description and values
* **Recommendations**
* **Downloads** with description and links to files
* **Figures** with description and links to figures
* **Visualisations** with links to the plugin pages.

The text snippet on the bottom of the page (`Last analysis was executed on 2017-08-22 09:43:10.`) displays the date of analysis for the computed data and values.
