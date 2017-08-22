title: Admin Summary
navi_name: Summary

# Admin > Summary

![Alambic Admin Web UI](/images/alambic_admin_summary.png)

## Instance information

Every instance has to set some parameters:

* **Name**: the name of this very instance, is displayed in the title, on the top left corner, and on the main page.
* **Description**: a text describing why this setup was installed, and a bit of context for people to better understand what is done here. Description is displayed on the main page of the instance.
* **Google tracking code**: a google analytics tracking code that will be inserted in all generated pages. If no code is provided then the tracking mechanism is disabled (and the script is not integrated into the generated pages).

## Databases

Details about the PostgreSQL databases defined for the instance -- check the [Database page](/Documentation/Admins/Database.html) to know more about databases.

The icon on the left of the postgresql URLs indicates if the connection could be established.

## Models

Show the number of metrics and attributes defined in the instance, and the name of the quality model.

## Projects

The list of projects defined on the host, with links to:

* the project's page,
* run a full analysis on the project,
* delete projects.
