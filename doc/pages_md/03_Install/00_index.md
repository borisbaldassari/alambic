title: Install Alambic
navi_name: Install


# Installing Alambic

Alambic is written in Perl and uses the [Mojolicious](http://mojolicio.us) web framework. It relies on a database to store configuration and projects information. As for now only PostgreSQL is supported as a back-end database.

-----

# Dependencies and requirements

Note: you may want to install [perlbrew](http://perlbrew.pl/) to have separate perl instances. Even better, perlbrew can be setup with a basic Unix user account.

## Basic requirements

* **Perl** 5.x versions 5.22 and 5.24 have been tested.
* **PostgreSQL** 9.5 or later. Some bleeding edge features are used (like update on insert), both by Alambic and the Minion job queuing system.
* Alambic has been developed and tested on **Gnu/Linux systems** (CentOS, Ubuntu, Debian). It may work on Windows, but this is not tested and thus not supported.
* Some plugins use the **R software** for advanced visualisation and computations.

Installing Mojolicious: see instructions [here](https://github.com/kraih/mojo/wiki/Installation) or simply use the CPAN module:

    $ perl -MCPAN -e 'install Mojolicious'

## Dependencies

You also need to install the following Perl modules from CPAN:

* `XML::LibXML` for PMD analysis.
* `List::MoreUtils` for the uniq function.
* `IO::Socket::SSL` (version 1.94+)
* `Minion` for the job queuing feature.
* `Mojo::Pg`
* `Mojolicious::Plugin::Mail`
* `DateTime` and `Date::Parse`
* `File::chdir`
* `Text::CSV` (which may import `Text::CSV_XS` too)
* `Crypt::PBKDF2` for password hashes

Note that plugins may have different specific requirements. As an example the StackOverflow plugin requires a R installation and a few packages (knitr for the weaving, snowballc for the wordcloud, etc.). See the documentation of plugins for more information.

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
        "conf_pg_minion" => "postgresql://alambic:pass4alambic@/minion_db",
        "conf_pg_alambic" => "postgresql://alambic:pass4alambic@/alambic_db",

        "alambic_version" => "3.2", # Usually don't touch that

        # Hypnotoad configuration
        "hypnotoad" => {
            listen => ['http://*:3010'],
        },
    }

## Start the application

The application can be started by issuing the following command:

    boris@castalia alambic $ cd mojo/
    boris@castalia mojo $ hypnotoad bin/alambic
    boris@castalia mojo $ bin/alambic minion worker

The first command (`hypnotoad`) starts the UI engine, and the second command (`minion worker`) starts a pool of workers to take care of jobs (i.e. project runs).

## Run the installer

If Alambic is not yet configured, it will automatically reroute all requests to an install page where various options (name and description of the instance, administrator login and password) are gathered. Once the information is filled, all threads are reset and the application is restarted with the correct values.
