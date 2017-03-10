title: Backups
navi_name: Backups

# Backups in Alambic

In Alambic all important data is stored in the database. It means that all file system files can be regenerated with a single run from the information stored in database, with the only exception of the main configuration file `alambic.conf`, which stores database information.

Data preserved in database includes:

* The instance configuration: name, description.
* Users configuration (with hashes as passwords).
* Models attributes, metrics and quality models.
* Projects configuration, information, custom data, and runs.

It is recommended to backup the Alambic instance regularly, and before any heavy administration operation (e.g. update).

# Executing backups from the UI

The admin section has its own system for backups and restore.

![alambic_backups.png](/images/alambic_backups.png)

The backup basically generates a SQL file which can be fed to another (or the same, btw) server, using interfaces like psql or pgAdmin. Backup files are stored on the file system (in `$MOJO_HOME`/backups) and can be downloaded from the web interface. Administrators can restore a backup file by clicking on the upload icon next to the file -- note however that this will erase all current values and replace them with the restored data.

# Executing backups from the CLI

There is an Alambic command for backups:

    $ script/alambic alambic backup
    Database has been backed up in [backups/alambic_backup_201612271112.sql].
