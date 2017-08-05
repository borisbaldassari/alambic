title: Administration pages
navi_name: AdminPages

# Administration pages

The administration pages are restricted to Alambic administrators (i.e. users with role Admin).

# Instance information

Every instance has to set some parameters:

* **Name**: the name of this very instance, is displayed in the title, on the top left corner, and on the main page.
* **Description**: a text describing why this setup was installed, and a bit of context for people to better understand what is done here. Description is displayed on the main page of the instance.
* **Google tracking code**: a google analytics tracking code that will be inserted in all generated pages. If no code is provided then the tracking mechanism is disabled (and the script is not integrated into the generated pages).

## Summary

A page to show brief insights of all admin tasks.

![Alambic Admin Web UI](/images/alambic_admin_summary.png)

## Database

All information pertaining to the connected databases:

* `alambic_db` is used to store project data,
* `minion_db` is used for the jobs management (see [Mojo::Minion](http://mojolicious.org/perldoc/Minion) for more information)

The button on the right directly starts a backup of the instance and stores it in the default backup directory.

The page also lists backups stored on the instance. Individual backup files can be restored (note: this deletes and replaces all data stored on the instance, use with caution!), downloaded and deleted from the list.

## Models

## Jobs

## Projects

## Users
