title: Bugzilla
navi_name: Bugzilla

# Bugzilla ITS

This plugin retrieves information from a [JIRA](https://www.atlassian.com/software/jira) instance repository and runs a basic analysis on its log. It notably displays graphics about commits and authors.

The list of attributes that can be retrieved from a Bugzilla instance is described in the [Bugzilla REST API documentation](http://bugzilla.readthedocs.io/en/latest/api/core/v1/bug.html#search-bugs).

Check the [plugin Perl documentation](/perldoc/Alambic/Plugins/Jira.pm.html) in the [perldoc](/perldoc/index.html) section.

-----

# Basic information

* **ID**: JiraIts
* **Abilities**: metrics, info, data, recs, viz, users
* **Description**:
  The Jira plugin retrieves issue information from an Atlassian Jira server, using the [Jira REST API](https://developer.atlassian.com/jiradev/jira-apis/jira-rest-apis).
* **Parameters**:
  * `jira_url` The URL of the Jira server, e.g. http://myserver.
  * `jira_user` The user for authentication on the Jira server.
  * `jira_passwd` The password for authentication on the Jira server.
  * `jira_project` The project ID to be requested on the Jira server.
  * `jira_open_states` The states names considered to be open, as a coma-separated list.
  * `proxy` If a proxy is required to access the remote resource of this plugin, please provide its URL here. A blank field means no proxy, and the `default` keyword uses the proxy from environment variables, see <a href="https://alambic.io/Documentation/Admin/Projects.html">the online documentation about proxies</a> for more details. Example: <code>https://user:pass@proxy.mycorp:3777</code>.

-----

# Provides

## Downloads

* `import_jira.json`: The original file of current information, downloaded from the Jira server (JSON).
* `jira_evol.csv`: The evolution of issues created and authors by day (CSV).
* `jira_issues.csv`: The list of issues, with fields 'id, summary, status, assignee, reporter, due_date, created_at, updated_at' (CSV).
* `jira_issues_late.csv`: The list of late issues (i.e. their due_date has past), with fields `id,summary,type,status,priority,assignee,reporter,due_date,created_at,updated_at,votes,watches` (CSV).
* `jira_issues_open.csv`: The list of open issues, with fields `id,summary,type,status,priority,assignee,reporter,due_date,created_at,updated_at,votes,watches` (CSV).
* `jira_issues_open_unassigned.csv`: The list of open and unassigned issues, with fields `id,summary,type,status,priority,assignee,reporter,due_date,created_at,updated_at,votes,watches` (CSV).
* `metrics_jira.json`: The list of metrics computed by the plugin (JSON).

## Figures

* `jira_summary.html`
  HTML summary of Jira issues main metrics (HTML)
* `jira_evol_summary.html`
  Evolution of Jira main metrics (HTML)
* `jira_evol_authors.html`
  Evolution of Jira issues authors (HTML)
* `jira_evol_created.html`
  Evolution of Jira issues creation (HTML)

## Information

* JIRA_URL
  The URL of the project on the Jira server.

## Metrics

* JIRA_VOL,
  Total number of issues for project in Jira.
* JIRA_AUTHORS,
  Total number of identities found as creators of issues.
* JIRA_AUTHORS_1W
  Total number of identities found as creators of issues created during the last week.
* JIRA_AUTHORS_1M
  Total number of identities found as creators of issues created during the last month.
* JIRA_AUTHORS_1Y
  Total number of identities found as creators of issues created during the last year.

* JIRA_CREATED_1W
  Total number of issues created during the last week.
* JIRA_CREATED_1M
  Total number of issues created during the last month.
* JIRA_CREATED_1Y
  Total number of issues created during the last year.

* JIRA_UPDATED_1W
  Total number of issues updated during the last week.
* JIRA_UPDATED_1M
  Total number of issues updated during the last month.
* JIRA_UPDATED_1Y
  Total number of issues updated during the last year.

* JIRA_OPEN
  Total number of issues currently in an open state (as defined by the list of open states in the plugin parameters).
* JIRA_OPEN_PERCENT
  Percentage of issues currently in an open state (as defined by the list of open states in the plugin parameters), compared to the total volume of issues.
* JIRA_LATE
  Number of issues with a due date past the current time.
* JIRA_OPEN_UNASSIGNED
  Number of issues 1. not assigned and 2. in an open state (as defined by the list of open states in the plugin parameters).

## Recommendations

* JIRA_LATE_ISSUES
  Emit a recommendation if there are issues with a due date past the current date.

## Visualisation

* Jira ITS


-----

# Screenshot

![eclipse_git.png](/images/jira_its.png)
