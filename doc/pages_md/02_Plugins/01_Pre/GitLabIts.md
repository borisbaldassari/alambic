title: GitLab ITS
navi_name: GitLabIts


# GitLab CI

This plugin retrieves information from a [GitLab](https://about.gitlab.com/) continuous integration engine, displays a summary of its status, and provides recommendations to better use the Continuous Integration system.

Check the [plugin Perl documentation](/perldoc/Alambic/Plugins/GitLabIts.pm.html) in the [perldoc](/perldoc/index.html) section.

-----

# Basic information

* **ID**: GitLabIts
* **Abilities**: info, data, metrics, figs, recs, viz
* **Description**:
  Retrieves information from a GitLab Issue Tracking System, displays a summary of its status, and provides recommendations to better use it.
* **Parameters**:
  * `gitlab_url` The base URL for the GitLab instance, e.g. https://gitlab.com/
  * `gitlab_token` 

-----

# Provides

## Metrics

* JOBS,
* JOBS_GREEN,
* JOBS_YELLOW,
* JOBS_RED,
* JOBS_FAILED_1W

## Figures

* `hudson_pie.html` A pie chart of the status of jobs.
* `hudson_hist.html` A history of jobs statuses over past days/weeks. The history range is defined by the remaining jobs, i.e. if jobs are deleted after some time history is lost.

## Recommendations

* CI_FAILING_JOBS

## Visualisation

Hudson CI

-----

# Screenshot

![hudson_ci.png](/images/hudson_ci.png)
