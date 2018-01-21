title: GitLab ITS
navi_name: GitLabIts


# GitLab ITS

This plugin retrieves information from a [GitLab](https://about.gitlab.com/) issue tracking system, displays a summary of its issues, and provides recommendations to better use the issue tracking system.

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

* ITS_AUTHORS 	
* ITS_AUTHORS_1M 	
* ITS_AUTHORS_1W 	
* ITS_AUTHORS_1Y 	
* ITS_CHANGED_1M 	
* ITS_CHANGED_1W 	
* ITS_CHANGED_1Y 	
* ITS_CREATED_1M 	
* ITS_CREATED_1W 	
* ITS_CREATED_1Y 	
* ITS_ISSUES_ALL 	
* ITS_ISSUES_CLOSED 	
* ITS_ISSUES_LATE 	
* ITS_ISSUES_OPEN 	
* ITS_ISSUES_UNASSIGNED 	
* ITS_ISSUES_UNASSIGNED_OPEN 	
* ITS_PEOPLE 	
* ITS_TOTAL_DOWNVOTES 	
* ITS_TOTAL_UPVOTES

## Information

* ITS_URL

## Figures

* `hudson_pie.html` A pie chart of the status of jobs.
* `hudson_hist.html` A history of jobs statuses over past days/weeks. The history range is defined by the remaining jobs, i.e. if jobs are deleted after some time history is lost.

## Recommendations

* ITS_LONG_STANDING_OPEN
Issues that have not been updated during the last year and are still open. Long-standing bugs have a negative impact on people's perception. You should either close the bug or add some more information to revive it.

## Visualisation

* GitLab ITS

-----

# Screenshot

![gitlab_its_ui.png](/images/gitlab_its_ui.png)
