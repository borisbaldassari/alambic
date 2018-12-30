title: Eclipse Pmi Wizard
navi_name: Eclipse


# Eclipse PMI Wizard

This Wizard plugin creates a new project in Alambic using the values defined in the [Eclipse PMI](https://projects.eclipse.org) repository.

The Project Management Infrastructure is described in the Eclipse wiki:

* [https://wiki.eclipse.org/Project_Management_Infrastructure](https://wiki.eclipse.org/Project_Management_Infrastructure)
* [https://wiki.eclipse.org/Project_Management_Infrastructure/Overview](https://wiki.eclipse.org/Project_Management_Infrastructure/Overview)
* [https://wiki.eclipse.org/Project_Management_Infrastructure/Development](https://wiki.eclipse.org/Project_Management_Infrastructure/Development)
* [https://wiki.eclipse.org/Project_Management_Infrastructure/Technology_Choices](https://wiki.eclipse.org/Project_Management_Infrastructure/Technology_Choices)
* [https://wiki.eclipse.org/Project_Management_Infrastructure/Overview_and_Design](https://wiki.eclipse.org/Project_Management_Infrastructure/Overview_and_Design)

Check the [plugin Perl documentation](http://alambic.io/perldoc/Alambic/Wizards/EclipsePmi.pm.html) in the [perldoc](http://alambic.io/perldoc/index.html) section.

-----

# Basic information

* **ID**: EclipsePmi
* **Name**: Eclipse PMI Wizard
* **Description**:
  The Eclipse PMI wizard creates a new project with all data source plugins needed to analyse a project from the Eclipse forge, including Eclipse ITS, Eclipse MLS, Eclipse PMI, Eclipse SCM and Hudson CI. It retrieves and uses values from the PMI repository to set the plugin parameters automatically.',
  This wizard only creates the plugins that should always be available. Depending on the project's configuration and data sources availability, other plugins may be needed and can manually be added to the configuration.
* **Parameters**:
  * `project_pmi` The project ID in the PMI repository (a.k.a. Eclipse project ID).
* **Plugins**:
  * [EclipsePmi](/Plugins/Pre/EclipsePmi.html)
  * [Hudson](/Plugins/Pre/Hudson.html)
  * [Git](/Plugins/Pre/Git.html)

-----

# Information retrieved

The following information is automatically retrieved from the PMI and used in the project's initialisation:

* Project name and description
* Git repository URL
* Hudson repository URL
