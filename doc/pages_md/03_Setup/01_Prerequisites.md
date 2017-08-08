title: Prerequisites for installing Alambic
navi_name: Prerequisites


# Dependencies and requirements

Alambic is written in Perl and uses the [Mojolicious](https://mojolicio.us) web framework. It relies on a database to store configuration and projects information. As for now only PostgreSQL is supported as a back-end database.

Note: you may want to install [perlbrew](http://perlbrew.pl/) to have separate perl instances. Even better, perlbrew can be setup with a basic Unix user account.

The [docker image](/Setup/Docker) serves as a use case test for installation of Alambic. As such, the list of requirements used to build the `image_base_centos` in `$ALAMBIC_HOME/Alambic/docker/image_base_centos` can be used as a reference for the dependencies.

## Basic requirements

* **Perl** 5.x versions 5.22, 5.24 and 5.26 have been tested. See the development page for more details on testing.
* **PostgreSQL** 9.5 or later. Some bleeding edge features are used (like update on insert), both by Alambic and the Minion job queuing system.
* Alambic has been developed and tested on **Gnu/Linux systems** (CentOS, Ubuntu, Debian). It may work on Windows, but this is not tested and thus not supported.
* Some plugins use the **R software** for advanced visualisation and computations.

Installing Mojolicious: see instructions [here](https://github.com/kraih/mojo/wiki/Installation) or simply use the CPAN module:

    $ perl -MCPAN -e 'install Mojolicious'

## Perl Dependencies

The list of Perl requirements notably include the following modules from CPAN:

* `XML::LibXML` for analysis of PMD XML results.
* `List::Util` and `List::MoreUtils` for the uniq function.
* `File::chdir`, `File::Basename`, `File::Copy`, `File::Path` and `File::stat` for filesystem operations.
* `Net::IDN::Encode` and `IO::Socket::SSL` (version 1.94+) for https.
* `Minion` for the job queuing feature.
* `Mojo::Pg`, `Mojo::JSON`, `Mojo::UserAgent`, `Mojolicious::Plugin::InstallablePaths` and `Mojolicious::Plugin::Mail`
* `DateTime` and `Date::Parse`
* `Test::More`, `Test::Perl::Critic` for testing, and `Pod::ProjectDocs` for documentation generation.
* `Text::CSV` (which may import `Text::CSV_XS` too)
* `Digest::MD5` and `Crypt::PBKDF2` for password hashes
* `Git::Repository`, `JIRA::REST` for data source plugins.

One can install everything in one command using `cpanm`. Note the `POSTGRES_HOME` env var.

```
POSTGRES_HOME=/usr/pgsql-9.5 cpanm inc::Module::Install Digest::MD5 Crypt::PBKDF2 Date::Parse DateTime File::chdir File::Basename File::Copy File::Path File::stat List::Util List::MoreUtils Minion Mojolicious Mojo::JSON Mojo::UserAgent Mojo::Pg XML::LibXML Text::CSV Time::localtime Mojolicious::Plugin::Mail Test::More Test::Perl::Critic Net::IDN::Encode IO::Socket::SSL Git::Repository JIRA::REST Mojolicious::Plugin::InstallablePaths Pod::ProjectDocs
```

Note that plugins have different specific requirements. As an example the StackOverflow plugin requires a R installation and a few packages (knitr for the weaving, snowballc for the wordcloud, etc.). See the documentation of plugins for more information.

## R dependencies

Most plugins use the R engine for the computations and/or the visualisations. As of Alambic 3.3.2, the list of R modules required to run Alambic plugins notably includes:

* `ggplot2`, `googleVis` and `plotly` for visualisation,
* `markdown` and `jsonlite` for data formats,
* `knitr`, `xtable`, `htmltools`, `rmarkdown` for literate programing,
* `wordcloud`, `SnowballC`, `dygraphs` for specific graphics.

The complete list of of R modules can be installed with the following command:

```
Rscript -e 'install.packages(c("BH", "DBI", "NLP", "R6", "RColorBrewer", "Rcpp", "SnowballC", "assertthat", "backports", "base64enc", "bitops", "caTools", "colorspace", "curl", "dichromat", "digest", "dplyr", "dygraphs", "evaluate", "ggplot2", "ggthemes", "googleVis", "gtable", "hexbin", "highr", "htmltools", "htmlwidgets", "httr", "jsonlite", "knitr", "labeling", "lazyeval", "magrittr", "markdown", "mime", "munsell", "openssl", "packrat", "pander", "plotly", "plyr", "purrr", "reshape2", "rmarkdown", "rprojroot", "scales", "slam", "stringi", "stringr", "tibble", "tidyr", "tm", "viridisLite", "wordcloud", "xtable", "xts", "yaml", "zoo", "svglite"), repos="http://cran.r-project.org")'
```
