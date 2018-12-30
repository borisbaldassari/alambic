title: Alambic For research
navi_name: Research


# Introduction: Using Alambic for reproducible research

Alambic uses [R][r] to run analysis on metrics and project data, and to draw plots. The following R packages are available in the standard installation:

* Many plots are generated with [ggplot2][ggplot2]. Some history plots use the [dygraph][dygraph] library.
* [Knit][knit] is used to generate complete HTML and PDF documents that are either included in the project dashboard or available for download.
* Interactive graphics are plotted using [plot.ly][plotly] and its [R package][plotlyr].
* Users can easily run their own R markdown files by re-using the simple plugin structure.

A couple of other packages are available for various purposes:

* ts, zoo for time series,
* wordcloud, ggthemes, googleVis, SnowballC
* pander, dplyr, migrattr, reshpae2, xtable for manipulation.

The complete and up-to-date list of R packages required to install Alambic, and available for plugins, is available in the Docker installation script in `$ALAMBIC_HOME/docker/image_base_centos/alambic_install_r_deps.sh`.

[r]: https://www.r-project.org
[knit]: https://rmarkdown.rstudio.com/
[dygraph]: http://dygraphs.com/
[ggplot2]: http://ggplot2.org/
[plotly]: https://plot.ly
[plotlyr]: https://plot.ly/r/


# Building a new plugin for R markdown documents

Alambic offers an easy way to run custom R markdown file, with pre-loaded data sets (metrics, indicators, attributes). All the information retrieved and computed by pre-plugins is also available for computations.

Building a custom plugin to run your own R markdown file is straight-forward.

## Make a copy of the GenericR plugin

The plugin is composed of the main module file (`GenericR.pm`) and a directory (`GenericR/`) containing the R files. The adopted naming convention is to use the plugin ID, camel case, for both files.

Make a copy of the GenericR plugin, located in the `$MOJO/lib/Alambic/Plugins` directory.

    $ cd $MOJO/lib/Alambic/Plugins/
    $ cp GenericR.pm MyRMarkdown.pm
    $ cp -r GenericR/ MyRMarkdown/

Edit the main module file:

    $ emacs MyRMarkdown.pm

Edit the main configuration hash of the plugin and update the following fields:

* ID: a unique identifier (no blank, only ascii chars) for the plugin.
* Name: a human-readable name for the plugin, that will be displayed in the interface.
* Description: an arraw of strings to give information and help about the plugin. Each array item will be embedded in `<p>` tags, and HTML can be used (e.g. for links).
* Optionally, edit the description of the PDF document that will be generated.

For our example, the file would look like this:

    my %conf = (
      "id"   => "MyRMarkdown",
      "name" => "Generic R plugin",
      "desc" => [
          "The generic R plugin enables users to easily define their own R markdown files to automatically run analysis on projects.",
          'See <a href="http://alambic.io/Plugins/Pre/GenericR">the project\'s wiki</a> for more information.',
      ],
      "type"             => "post",
      "ability"          => ['data'],
      "params"           => {},
      "provides_cdata"   => [],
      "provides_info"    => [],
      "provides_data"    => {
          "generic_r.pdf" => "The PDF document generated from the R markdown file.",
        },
      "provides_metrics" => {},
      "provides_figs"    => {},
      "provides_recs" => [],
      "provides_viz"  => {},
    );

And you're done. Start the application again, and the plugin should appear in the list.

## Edit R files

This plugin uses the [RMarkdown](http://rmarkdown.rstudio.com/) syntax and engine to process the file. Edit the R file in the directory of the new plugin:

    $ cd MyRMarkdown/
    $ emacs generic_r.Rmd

The initialisation of the document is done in the first R chunk (named `init`). It loads the definition of metrics and attributes as data frames (resp. `metrics_ref` and `attrs_ref`) and the values of metrics and attributes for the current run (resp. `metrics` and `attrs`).

The actual implementation of the GenericR plugin can serve as a reference to understand how R code chunks work and how to display data or graphics in the document.

Depending on the configuration of the project, other data files can be loaded directly from the `input` and `output` directories. See the example of the Git analysis in the GenericR R markdown file.
