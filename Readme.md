# Welcome to the Alambic project

Alambic is an open-source platform for the management and visualisation of software engineering data.

It basically retrieves metrics from many various repositories (code metrics, scm, its, mailing lists, stack overflow questions, etc.) and makes them available for custom plugins to produce analysis, numbers, graphics, and data sets. 

A flexible plugin system allows to easily add new data sources (e.g. git or svn logs, bugzilla queries), analysis tools (including R scripts), visualisation and reporting (e.g. knitr or plotly graphs). Examples of plugins ready to use include PMD Results Analysis, StackOverflow questions and PMI Checks for Eclipse projects.

Measures can also be aggregated in a tree-like quality model structure to better organise and understand the information. The [[Quality model]] can be entirely customised, and almost any type of data source can be added through plugins. The result is best explained by the following picture of a project: [alambic_project_qm.png](images/alambic_project_qm.png).

Alambic is notably used by (and is actually derived from) the [PolarSys dashboard](http://dashboard.polarsys.org).

# Alambic main features

* Retrieves data from any source, aggregates and displays them in a custom dashboard.
* Alambic is entirely Web-based, althought it is very easy to understand how files are organised. 
* Plugins can be used to add new automatic data sources, custom data sources and visualisation units.
* Custom Data plugins allow to enter manual data (e.g. surveys) and compute custom metrics from them.

# More information

The project is hosted at [BitBucket](http://bitbucket.org): https://bitbucket.org/BorisBaldassari/alambic

* Bug tracking can be done at https://bitbucket.org/BorisBaldassari/alambic/issues
* Wiki and documentation can be found at https://bitbucket.org/BorisBaldassari/alambic/wiki/
* Source can be viewed (and pull requests generated) at https://bitbucket.org/BorisBaldassari/alambic/overview

The [Castalia Camp web site](http://castalia.camp/alambic) provides a few more information and examples, along with links to existing instances of Alambic for known forges.