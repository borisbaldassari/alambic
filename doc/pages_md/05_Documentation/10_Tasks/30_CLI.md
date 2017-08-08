title: CLI commands
navi_name: CLI

# Alambic Command Line Interface

Alambic offers a command line interface for some of its features:

* `about` Shows help and exit.
* `init` Initialisation of the database and instance.
* `backup` Backup the database.
* `password` resets the password of an Alambic user.

## Using the Alambic CLI:

On the file system, go to the `mojo` directory and issue the following commands:
```
bin/alambic alambic <command> <options>
```

## about

Prints usage and exit.

    $ bin/alambic about

    Welcome to the Alambic application.

    See http://alambic.io for more information about the project.

    Usage: alambic <command>

    Alambic commands:
    * alambic about                 Display this help text.
    * alambic init                  Initialise the database.
    * alambic backup                Backup the database.
    * alambic password user mypass  Reset password for user.

    Other Mojolicious commands:
    * alambic minion                Manage job queuing system.
    * alambic daemon                Run application in development mode.
    * alambic prefork               Run application in production (multithreaded) mode.

## init

Initialise the database and set basic settings for Alambic (name, description), and create a administrator password with default values.

    boris@midkemia mojo $ bin/alambic init
    Database is nok or is empty.
    Initialising database.
    Initialising instance parameters.
    Creating administrator account.

Default values for administrator account are:

* login: `administrator`,
* name:`Administrator`,
* email: `alambic@castalia.solutions`,
* password: `password`,
* roles: ['Admin']

For safety, if the database is already populated then the init command fails. In this case remove tables manually (or re-create the database) and re-execute the command.

## backup

Start a complete backup of the Alambic database.

    $ bin/alambic backup
    Starting database backup.
    Database has been backed up in [backups/alambic_backup_201707281338.sql].

## password

Reset the password of an Alambic user.

    $ alambic password administrator newpassword
    Successfully changed password for user [Administrator].

## test

Run the complete Alambic test suite.

<span class="label label-danger">Danger</span> &nbsp; This will erase the test database. Double check that your configuration is correct.

    boris@midkemia mojo $ bin/alambic test
    Running tests from "/home/boris/Projects/bb_alambic/mojo/bin/../t".
    /home/boris/Projects/bb_alambic/mojo/bin/../t/ui/001_basic.t ............. ok
    /home/boris/Projects/bb_alambic/mojo/bin/../t/ui/002_documentation.t ..... ok
    /home/boris/Projects/bb_alambic/mojo/bin/../t/ui/010_admin.t ............. ok
    /home/boris/Projects/bb_alambic/mojo/bin/../t/ui/011_auth.t .............. ok
    /home/boris/Projects/bb_alambic/mojo/bin/../t/unit/Model/Alambic.t ....... ok
    /home/boris/Projects/bb_alambic/mojo/bin/../t/unit/Model/Models.t ........ ok
    /home/boris/Projects/bb_alambic/mojo/bin/../t/unit/Model/Plugins.t ....... ok
    /home/boris/Projects/bb_alambic/mojo/bin/../t/unit/Model/Project.t ....... ok
    /home/boris/Projects/bb_alambic/mojo/bin/../t/unit/Model/RepoDB.t ........ ok
    /home/boris/Projects/bb_alambic/mojo/bin/../t/unit/Model/RepoFS.t ........ ok
    /home/boris/Projects/bb_alambic/mojo/bin/../t/unit/Model/Tools.t ......... ok
    /home/boris/Projects/bb_alambic/mojo/bin/../t/unit/Model/Users.t ......... ok
    /home/boris/Projects/bb_alambic/mojo/bin/../t/unit/Model/Wizards.t ....... ok
    /home/boris/Projects/bb_alambic/mojo/bin/../t/unit/Plugins/EclipsePmi.t .. ok
    /home/boris/Projects/bb_alambic/mojo/bin/../t/unit/Tools/Git.t ........... 1/? Clonage dans 'projects/test.project/src'... at /home/boris/Projects/bb_alambic/mojo/bin/../lib/Alambic/Tools/Git.pm line 183.
    /home/boris/Projects/bb_alambic/mojo/bin/../t/unit/Tools/Git.t ........... ok
    /home/boris/Projects/bb_alambic/mojo/bin/../t/unit/Tools/R.t ............. ok
    All tests successful.
    Files=16, Tests=603, 160 wallclock secs ( 0.09 usr  0.05 sys +  9.34 cusr  0.90 csys = 10.38 CPU)
    Result: PASS
