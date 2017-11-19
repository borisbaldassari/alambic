title: GitLab ITS
navi_name: GitLabIts


# GitLab ITS

This plugin retrieves information from a [GitLab](https://about.gitlab.com/) issue tracking system, displays a summary of its issues, and provides recommendations to better use the issue tracking system.

Check the [plugin Perl documentation](/perldoc/Alambic/Plugins/GitLabIts.pm.html) in the [perldoc](/perldoc/index.html) section.

> This plugin targets the GitLab API v3, i.e. GitLab 8.x (up to 9.4.x too). See the [official GitLab announcement](https://docs.gitlab.com/ce/api/v3_to_v4.html) for more details.


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
