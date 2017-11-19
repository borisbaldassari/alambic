title: GitLab CI
navi_name: GitLabCi


# GitLab CI

This plugin retrieves information from a [GitLab](https://about.gitlab.com/) continuous integration engine, displays a summary of its status, and provides recommendations to better use the Continuous Integration system.

Check the [plugin Perl documentation](/perldoc/Alambic/Plugins/GitLabCi.pm.html) in the [perldoc](/perldoc/index.html) section.

> This plugin targets the GitLab API v3, i.e. GitLab 8.x (up to 9.4.x too). See the [official GitLab announcement](https://docs.gitlab.com/ce/api/v3_to_v4.html) for more details.

> Note: terminology differs between CI engines. As a reminder, we considered the following mapping between Hudson/Jenkins and GitLab CI: Hudson Jobs are GitLab Pipelines, and Hudson Builds are GitLab Jobs. Yeah. Misleading.

-----

# Basic information

* **ID**: GitLabCi
* **Abilities**: info, data, metrics, figs, recs, viz
* **Description**:
  Retrieves information from a GitLab continuous integration engine, displays a summary of its status, and provides recommendations to better use CI.
* **Parameters**:
  * `hudson_url` The base URL for the Hudson instance. In other words, the URL one would point to to get the main page of the project's Hudson, with the list of jobs.

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
