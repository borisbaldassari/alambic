title: Eclipse ITS
navi_name: EclipseIts


# Eclipse ITS

This plugins retrieves issue tracking information from the [Eclipse Dashboard's server](http://dashboard.eclipse.org) and produces evolution graphics and various analyses.

All data from the Eclipse dashboard can be downloaded from the server in JSON format at the following url:

* All files: http://dashboard.eclipse.org/data/json/
* Project-specific file (last metrics): http://dashboard.eclipse.org/data//json/modeling.sirius-its-prj-static.json
* Project-specific file (evolution metrics): http://dashboard.eclipse.org/data//json/modeling.sirius-its-prj-evolutionary.json

-----

# Basic information

* **ID**: EclipseIts
* **Abilities**:   metrics   data   recs   figs   viz
* **Description**:
  Eclipse ITS retrieves bug tracking system data from the Eclipse dashboard repository. This plugin will look for a file named project-its-prj-static.json on the Eclipse dashboard.
  See the project's wiki for more information.
* **Parameters**:
    * project_grim The project ID used to identify the project on the dashboard server. Note that it may be different from the id used in the PMI.

-----

# Provides

## Information

## Metrics

ITS_CHANGED, ITS_CHANGERS, ITS_CLOSED, ITS_CLOSED_30, ITS_CLOSED_365, ITS_CLOSED_7, ITS_CLOSERS, ITS_CLOSERS_30, ITS_CLOSERS_365, ITS_CLOSERS_7, ITS_DIFF_NETCLOSED_30, ITS_DIFF_NETCLOSED_365, ITS_DIFF_NETCLOSED_7, ITS_DIFF_NETCLOSERS_30, ITS_DIFF_NETCLOSERS_365, ITS_DIFF_NETCLOSERS_7, ITS_OPENED, ITS_OPENERS, ITS_PERCENTAGE_CLOSED_30, ITS_PERCENTAGE_CLOSED_365, ITS_PERCENTAGE_CLOSED_7, ITS_PERCENTAGE_CLOSERS_30, ITS_PERCENTAGE_CLOSERS_365, ITS_PERCENTAGE_CLOSERS_7, ITS_TRACKERS

## Figures

its_evol_changed.html, its_evol_opened.html, its_evol_people.html, its_evol_summary.html

## Downloads

* import_its.json: The original file of current metrics downloaded from the Eclipse dashboard server (JSON).
* metrics_its.csv: Current metrics for the ITS plugin (CSV).
* metrics_its.json: Current metrics for the ITS plugin (JSON).
* metrics_its_evol.csv: Evolution metrics for the ITS plugin (CSV).
* metrics_its_evol.json: Evolution metrics for the ITS plugin (JSON).

## Recommendations

ITS_CLOSERS, ITS_OPEN_BUGS

## Visualisation

Eclipse ITS

-----

# Screenshot

![eclipse_its.png](https://bitbucket.org/repo/b48zyo/images/4088138325-eclipse_its.png)
