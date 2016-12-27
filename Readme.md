# Welcome to the Alambic project

Alambic is an open-source platform and service for the management and visualisation of software engineering data.

[ ![Codeship Status for BorisBaldassari/alambic](https://app.codeship.com/projects/8f5ae970-a10d-0134-6d00-664a346b6816/status?branch=master)](https://app.codeship.com/projects/189806)

It basically retrieves metrics from many various repositories (code metrics, scm, its, mailing lists, stack overflow questions, etc.) and makes them available for custom plugins to produce analysis, numbers, graphics, and data sets. 

A flexible plugin system allows to easily add new data sources (e.g. git or svn logs, bugzilla queries), analysis tools (including R scripts), visualisation and reporting (e.g. knitr or plotly graphs). Examples of plugins ready to use include PMD Results Analysis, StackOverflow questions and PMI Checks for Eclipse projects.

Measures are also aggregated in a tree-like quality model structure to better organise and understand the information. The quality model can be entirely customised, and almost any type of data source can be added through plugins. 

Alambic is notably used by (and is actually derived from) the [PolarSys dashboard](http://dashboard.polarsys.org).

The project is hosted at [BitBucket](http://bitbucket.org): https://bitbucket.org/BorisBaldassari/alambic

* Bug tracking can be done at https://bitbucket.org/BorisBaldassari/alambic/issues
* Wiki and documentation can be found at https://bitbucket.org/BorisBaldassari/alambic/wiki/
* Source can be viewed (and pull requests generated) at https://bitbucket.org/BorisBaldassari/alambic/overview

The [Castalia Camp web site](http://castalia.camp/alambic) provides more information, examples, and links to existing instances of Alambic for known forges.

# Alambic main features

* Retrieves data from any source, aggregates and displays them in a custom dashboard.
* Alambic is entirely Web-based, althought it is very easy to understand how files are organised. 
* Plugins can be used to add new automatic data sources, custom data sources and visualisation units.
* Custom Data plugins allow to enter manual data (e.g. surveys) and compute custom metrics from them.


# More information

The analysis process is self-documented; most of the information available is directly integrated into this very web site. You should check the documentation page first. The next place to go is the project's wiki, which contains more in-depth documentation about the install process, plugins, administration, or how to reuse pictures on external web sites.

Since Alambic is a fork of the PolarSys dashboard, there is a lot of information (mostly historical by now, but still relevant) available on the PolarSys wiki, since the project started there. From the beginning the PolarSys dashboard has been driven by the PolarSys members: the definition of the quality model, attributes, metrics has been discussed on the public mailing list, and the full retrieval and analysis process has received a common agreement on the mailing list. The project and/or its features have also been presented a few times:

* EclipseCon France 2015 Unconference (working session).
* EclipseCon Europe 2014: https://www.eclipsecon.org/europe2014/session/assessing-project-quality-improvement-polarsys-maturity-assessment-initiative
* EclipseCon Europe 2014 Unconference: https://polarsys.org/wiki/EclipseConEurope2014
* EclipseCon France 2014 Unconference: https://wiki.eclipse.org/Eclipse_WG_Unconference_France_2014
* EclipseCon France 2013: http://www.eclipsecon.org/france2013/sessions/software-quality-eclipse-way-and-beyond

Acknowledgements

Like many projects, Alambic has a huge debt of gratitude to all the software that made it possible. Among them:

* [Perl](http://perl.org/), its [myriad of modules](http://www.ctan.org/), and the [Mojolicious team](http://mojolicious.org/).
* The [R project](https://www.r-project.org/), and its [myriad of packages](https://cran.r-project.org/). The guys at [RStudio](https://www.rstudio.com/) have contributed a lot of [cool packages](https://www.rstudio.com/products/rpackages/), including [ggplot2](http://ggplot2.org/), [knitr](http://yihui.name/knitr/) and [rmarkdown](http://rmarkdown.rstudio.com/).
* [Plot.ly](http://plot.ly/) for their open-source contributions, including the [plotly R package](https://plot.ly/r/) and the [javascript library](https://plot.ly/javascript/), and for their [free online service](https://plot.ly/plot) for data exploration and visualisation, which rocks!