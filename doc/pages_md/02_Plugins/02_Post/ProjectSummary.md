title: Project Summary
navi_name: ProjectSummary


# Project Summary

This plugin creates

-----

# Basic information

* **ID**: Hudson
* **Abilities**: metrics, figs, recs, viz
* **Description**:
  Retrieves information from a Hudson continuous integration engine, displays a summary of its status, and provides recommendations to better use CI.
* **Parameters**:
    * hudson_url The base URL for the Hudson instance. In other words, the URL one would point to to get the main page of the project's Hudson, with the list of jobs.

-----

# Provides

## Metrics

JOBS, JOBS_GREEN, JOBS_YELLOW, JOBS_RED, JOBS_FAILED_1W

## Figures

* hudson_pie.html A pie chart of the status of jobs.
* hudson_hist.html A history of jobs statuses over past days/weeks. The history range is defined by the remaining jobs, i.e. if jobs are deleted after some time history is lost.

## Recommendations

CI_FAILING_JOBS

## Visualisation

Hudson CI

-----

# Screenshot

![hudson_ci.png](/images/hudson_ci.png)
