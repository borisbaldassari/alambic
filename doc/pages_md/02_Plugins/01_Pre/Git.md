title: Git
navi_name: Git

# Git

This plugin retrieves information from a Git repository and runs a basic analysis on its log. It notably displays graphics about commits and authors.

Check the [plugin Perl documentation](/perldoc/Alambic/Plugins/Git.pm.html) in the [perldoc](/perldoc/index.html) section.

-----

# Basic information

* **ID**: Git
* **Abilities**: metrics, info, data, recs, viz
* **Description**:
  Retrieves configuration management data from a git local repository. This plugin uses the Git Tool in Alambic.
* **Parameters**:
  * `git_url` The URL of the Git repository to analyse. It can be either a https or ssh URL, e.g. https://BorisBaldassari@bitbucket.org/BorisBaldassari/alambic.git.

-----

# Provides

## Downloads

* `import_git.txt`: The original git log file as retrieved from git (TXT).
* `git_commits.csv`: Evolution of number of commits and authors by day (CSV).
* `metrics_git.csv`: Current metrics for the SCM Git plugin (CSV).
* `metrics_git.json`: Current metrics for the SCM Git plugin (JSON).

## Figures

* `git_summary.html`
  HTML export of Git main metrics.
* `git_evol_summary.html`
  HTML export of Git SCM evolution summary.
* `git_evol_authors.png`
  PNG export of Git SCM authors evolution.
* `git_evol_authors.svg`
  SVG export of Git SCM authors evolution.
* `git_evol_authors.html`
  HTML export of Git authors evolution.
* `git_evol_commits.png`
  PNG export of Git SCM commits evolution.
* `git_evol_commits.svg`
  SVG export of Git SCM commits evolution.
* `git_evol_commits.html`
  HTML export of Git commits evolution.

## Information

* GIT_URL
  The URL of the Git repository used for the analysis.

## Metrics

* SCM_AUTHORS,
  Total number of identities found as authors of commits in source code management repository.
* SCM_AUTHORS_1W
  Total number of identities found as authors of commits in source code management repositories dated during the last week.
* SCM_AUTHORS_1M
  Total number of identities found as authors of commits in source code management repositories dated during the last month.
* SCM_AUTHORS_1Y
  Total number of identities found as authors of commits in source code management repositories dated during the last year.
* SCM_COMMITS,
  Total number of commits in source code management repositories.
* SCM_COMMITS_1W
  Total number of commits in source code management repositories dated during the last week.
* SCM_COMMITS_1M
  Total number of commits in source code management repositories dated during the last month.
* SCM_COMMITS_1Y
  Total number of commits in source code management repositories dated during the last year.
* SCM_COMMITTERS,
  Total number of identities found as authors of commits in source code management repository.
* SCM_COMMITTERS_1W
  Total number of identities found as committers of commits in source code management repositories dated during the last week.
* SCM_COMMITTERS_1M
  Total number of identities found as committers of commits in source code management repositories dated during the last month.
* SCM_COMMITTERS_1Y
  Total number of identities found as committers of commits in source code management repositories dated during the last year.
* SCM_FILES
  Total number of files touched by commits in source code management repositories dated during the last three months.

## Recommendations

* SCM_LOW_ACTIVITY
  Emit a recommendation if there have been less than 12 commits during the last year.
* SCM_ZERO_ACTIVITY
  Emit a recommendation if there has been zero (0) commit during last year.
* SCM_LOW_DIVERSITY
  Emit a recommendation if there have been less than 2 authors during the last year.

## Visualisation

* Git SCM


-----

# Screenshot

![eclipse_git.png](/images/git_scm.png)
