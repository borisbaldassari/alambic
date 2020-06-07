title: Scancode Tool
navi_name: Scancode


# Scancode

This Tool plugin provides an interface to the [Scancode](https://github.com/nexB/scancode-toolkit) finely integrated within Alambic.

A number of functions are made available for common operations like:

* Execute a scancode scan with options: copyright, package, licence, info, summary, classify, generated, with output set to CSV.
* Execute a scancode scan with options: copyright, package, licence, info, summary, classify, generated, with output set to JSON.

Check the [plugin Perl documentation](http://alambic.io/perldoc/Alambic/Tools/Scancode.pm.html) in the [perldoc](http://alambic.io/perldoc/index.html) section.

The Scancode documentation sits at [scancode-toolkit.readthedocs.io](https://scancode-toolkit.readthedocs.io).

-----

# Basic information

* **ID**: scancode
* **Name**: Scancode Tool
* **Abilities**: methods.
* **Description**: Scancode scans files and fetch information about licences and copyrights..
* **Parameters**:
  * `path_r` The absolute path or command to the `scancode` executable to use.
  * `path_scancode` The path to the directory to be analysed, relative to the root of the repository. Defaults to the root.

-----

# Provides

## Methods

* `scancode_scan_csv` Function to execute a Scancode and provide a CSV output file.
* `scancode_scan_json` Function to execute a Scancode and provide a CSV output file.
