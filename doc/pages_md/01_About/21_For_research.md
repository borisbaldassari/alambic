title: For research
navi_name: Reproducible research


# Using Alambic for reproducible research

Alambic uses [R][r] to run analysis on metrics and project data, and to draw plots. The following R packages are available in the standard installation:

* Many plots are generated with [ggplot2][ggplot2]. Some history plots use the [dygraph][dygraph] library.
* [Knit][knit] is used to generate complete HTML and PDF documents that are either included in the project dashboard or available for download.
* Interactive graphics are plotted using [plot.ly][plotly] and its [R package][plotlyr].

A couple of other packages are available for various purposes:

* ts, zoo for time series,
* wordcloud, ggthemes, googleVis, SnowballC
* pander, dplyr, migrattr, reshpae2, xtable for manipulation.

The complete and up-to-date list of R packages required to install Alambic, and available for plugins, is available in the Docker installation script in `$ALAMBIC_HOME/docker/image_base_centos/alambic_install_r_deps.sh`.

[r]: https://www.r-project.org
[knit]: http://rmarkdown.rstudio.com/
[ggplot2]: http://ggplot2.org/
[plotly]: http://plot.ly
[plotlyr]: https://plot.ly/r/


# Building a new plugin for R markdown documents

In order to execute a custom R markdown file, one has to build a new plugin






# An example implementation

mlj
