title: R Sessions Tool
navi_name: R Sessions


# R

This Tool plugin provides an interface to the [R engine](https://www.r-project.org) finely integrated within Alambic.

A number of functions are made available for common operations like:

* knitting a rmarkdown document to html snippets (incs),
* knitting a rmarkdown document to a PDF file,
* knitting a rmarkdown document to a complete HTML file,
* knitting a r document to an image.

Check the [plugin Perl documentation](http://alambic.io/perldoc/Alambic/Tools/R.pm.html) in the [perldoc](http://alambic.io/perldoc/index.html) section.

-----

# Basic information

* **ID**: r_sessions
* **Name**: R sessions
* **Abilities**: methods.
* **Description**: Runs R for plugins, computes data and generates files.
* **Parameters**:
  * `path_r` The absolute path to the R executable if it cannot be found in the `$PATH`.

-----

# Provides

## Methods

* `knit_rmarkdown_inc` Function to knit a rmarkdown document to a html snippet (i.e. without `<html>` tags).
* `knit_rmarkdown_pdf` Function to knit a rmarkdown document to a pdf document.
* `knit_rmarkdown_html` Function to knit a rmarkdown document to a full html document (i.e. a complete HTML document including `<html>` tags).
* `knit_rmarkdown_images` Function to knit a r document to image(s).
