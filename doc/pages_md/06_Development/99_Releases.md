title: Alambic Releases
navi_name: Releases


# Alambic releases

## Alambic 3.3.3

Date: 2017-12-05

Changelog:

* Minor [bug fixes](https://bitbucket.org/BorisBaldassari/alambic/issues?milestone=Alambic+3.3.3).
* New [Proxy feature](https://alambic.io/Documentation/Admins/Projects.html) for all plugins, contributed by [Thales Group](https://www.thalesgroup.com).
* Support for [Mojo::Minion](http://mojolicious.org/perldoc/Minion) 8 new API.
* Updated documentation, available on [https://alambic.io](https://alambic.io).

If one intends to run Alambic with a recent version of Minion (>= 8), then this release (or greater) is needed.

## Alambic 3.3.2

Date: 2017-09-15

Changelog:

* Minor [bug fixes](https://bitbucket.org/BorisBaldassari/alambic/issues?milestone=Alambic+3.3.2).
* New [Jira plugin](/Plugins/Pre/Jira.html), contributed by [Thales Group](https://www.thalesgroup.com).
* New [Git plugin](/Plugins/Pre/Git.html), contributed by [Thales Group](https://www.thalesgroup.com).
* New [SonarQube 4.5.x plugin](/Plugins/Pre/SonarQube45.html), contributed by [Thales Group](https://www.thalesgroup.com).
* New [Generic R plugin](/Plugins/Post/GenericR.html) for better [reproducible research](/Documentation/Research.html).

## Alambic 3.3.1

Date: 2017-04-22

Changelog:

* Security fix.
* Minor [bug fixes](https://bitbucket.org/BorisBaldassari/alambic/issues?milestone=Alambic+3.3.1).

## Alambic 3.3

Date: 2017-04-17

Changelog:

* Various [bug fixes](https://bitbucket.org/BorisBaldassari/alambic/issues?kind=bug&milestone=Alambic+3.3).
* More tests, documentation, reliability and usability improvements.
* Continuous integration through codeship and codefresh.
* Improved install process to easily setup Alambic. The docker image is still up-to-date!
* A new plugin for sharing: ProjectSummary.

## Alambic 3.2

Date: 2016-12-31

Changelog:

* Various [bug fixes](https://bitbucket.org/BorisBaldassari/alambic/issues?kind=bug&milestone=Alambic+3.2).
* The [StackOverflow](/Plugins/Pre/StackOverflow.html) plugin has been added to the list of plugins.
* More tests, documentation, reliability and usability improvements.
* Continuous integration through codeship.
* A docker image! Still in development, check the [docker hub repository](https://hub.docker.com/r/bbaldassari/alambic/)!


## Alambic 3.1

Date: 2016-08-11

Changelog:

* Various [bug fixes](https://bitbucket.org/BorisBaldassari/alambic/issues?kind=bug&milestone=Alambic+3.1).
* Documentation has been updated and improved: Install, Backups..
* Plugins documentation for Alambic 3.x
    * Eclipse ITS
    * Eclipse MLS
    * Eclipse PMI
    * Eclipse SCM
    * Hudson CI
    * PMD Analysis
* Add google analysis tracking code: [#70](https://bitbucket.org/BorisBaldassari/alambic/issues/70/add-google-tracking-edit)
* Add user and delay attributes on runs: [#69](https://bitbucket.org/BorisBaldassari/alambic/issues/69/add-delay-and-user-to-runs)
* Fix plots in PMD Analysis: [#47](https://bitbucket.org/BorisBaldassari/alambic/issues/47/plot-in-pmdanalysis-shows-wrong-values) [#62](https://bitbucket.org/BorisBaldassari/alambic/issues/62/404-in-plugin-pmdanalysis)
* Fix various typos and bugs in plugins: [#65](https://bitbucket.org/BorisBaldassari/alambic/issues/65/tidy-up-hudson-plugin) [#66](https://bitbucket.org/BorisBaldassari/alambic/issues/66/eclipse-scm-plugin-has-wrong-pluginid)
* Fix escape in backups: [#67](https://bitbucket.org/BorisBaldassari/alambic/issues/67/backups-are-incomplete)
* Improve UI: Fix links in home page ([#68](https://bitbucket.org/BorisBaldassari/alambic/issues/68/project-links-in-home-page-lead-to-admin)), add footer with date and alambic version ([#72](https://bitbucket.org/BorisBaldassari/alambic/issues/72/prepare-for-alambic-31-release)).
