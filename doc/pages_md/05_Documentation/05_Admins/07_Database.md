title: Admin Database
navi_name: Database

# Admin > Database

All information pertaining to the connected databases:

* `alambic_db` is used to store project data,
* `minion_db` is used for the jobs management (see [Mojo::Minion](http://mojolicious.org/perldoc/Minion) for more information)

The button on the right directly starts a backup of the instance and stores it in the default backup directory.

The page also lists backups stored on the instance. Individual backup files can be restored (note: this deletes and replaces all data stored on the instance, use with caution!), downloaded and deleted from the list.
