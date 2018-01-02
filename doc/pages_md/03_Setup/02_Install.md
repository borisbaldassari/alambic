title: Installing Alambic
navi_name: Install


# Installing Alambic

<span class="label label-warning">Warning</span> &nbsp; Check first that the [prerequisites](/Setup/Prerequisites.html) have been installed.

-----

# Download and setup the application

## Download Alambic

Once Mojolicious and all the dependencies are installed, clone the Alambic repository into a local directory.

    boris@camp ~$ git clone git@bitbucket.org:BorisBaldassari/alambic.git
    Cloning into 'alambic'...
    remote: Counting objects: 1589, done.
    remote: Compressing objects: 100% (910/910), done.
    remote: Total 1589 (delta 836), reused 1320 (delta 651)
    Receiving objects: 100% (1589/1589), 3.04 MiB | 2.81 MiB/s, done.
    Resolving deltas: 100% (836/836), done.
    boris@camp ~$ cd alambic/mojo/

You can also download the

## Setup Postgresql

You have to create a Postgresql database for Alambic. Database name is `alambic_db`, user is `alambic` and default password is `pass4alambic`. These can be changed in the `data/alambic_conf.json` configuration file. The basic setup for this can be achieved through the following commands:

    postgres=# CREATE USER alambic WITH PASSWORD 'pass4alambic';
    CREATE ROLE
    postgres=# CREATE DATABASE alambic_db OWNER alambic;
    CREATE DATABASE
    postgres=# CREATE DATABASE minion_db OWNER alambic;
    CREATE DATABASE


-----

# Initialise the application

## Edit the main configuration file

Edit the file `mojo/alambic.conf` to fill in the database parameters and optionally set the port for the application.

    # Low-level configuration for mojo Alambic: hypnotoad conf, etc.
    {
        "conf_pg_minion" => "postgresql://alambic:pass4alambic@postgres/minion_db",
        "conf_pg_alambic" => "postgresql://alambic:pass4alambic@postgres/alambic_db",

        "conf_pg_minion_test" => "postgresql://alambic:pass4alambic@/minion_db",
        "conf_pg_alambic_test" => "postgresql://alambic:pass4alambic@/alambic_db",

        "alambic_version" => "3.2",

        # Hypnotoad configuration
        "hypnotoad" => {
            listen => ['http://*:3010'],
        },
    }

The Hypnotoad configuration section can use any setting recognised by the Hypnotoad server. See the full list of options on [its official page](http://mojolicious.org/perldoc/Mojo/Server/Hypnotoad).

## Initialise the application

To initialise the database and create an administrator account use the `init` command from Alambic:

```
boris@castalia mojo $ bin/alambic init
```

----

# Start the application

You're all set.
The application can be started by issuing the following command:

    boris@castalia alambic $ cd mojo/
    boris@castalia mojo $ hypnotoad bin/alambic
    boris@castalia mojo $ bin/alambic minion worker

The first command (`hypnotoad`) starts the UI engine, and the second command (`minion worker`) starts a pool of workers to take care of jobs (i.e. project runs). See the page about [Running Alambic](/Setup/Run.html) for more details.
