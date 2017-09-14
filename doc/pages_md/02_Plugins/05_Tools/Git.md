title: Git Tool
navi_name: Git


# Git

This Tool plugin provides an interface to Git features finely integrated within Alambic.

A number of functions are made available for common operations like:

* cloning or pulling from a Git reository,
* Get the repository's log,
* Utility functions to get a list of commits.

Check the [plugin Perl documentation](http://alambic.io/perldoc/Alambic/Tools/Git.pm.html) in the [perldoc](http://alambic.io/perldoc/index.html) section.

-----

# Basic information

* **ID**: git
* **Name**: Git Tool
* **Abilities**: methods.
* **Description**:
  Provides Git commands and features.
* **Parameters**:
  * `path_git` The absolute path of the git executable if it cannot be found in the `$PATH`.

-----

# Provides

## Methods

* `git_clone` Clone a project git repository locally.
* `git_pull` Pull from a remote repository.
* `git_clone_or_pull` Update a local git repository. If it exists it will be pulled, otherwise it will be cloned.
* `git_log` Get the log from a local git repository.
* `git_commits` Get a list of commits from a local git repository.
