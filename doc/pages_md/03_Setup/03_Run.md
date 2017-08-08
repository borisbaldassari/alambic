title: Running Alambic
navi_name: Run


# Running Alambic


## Starting the UI

### For production use

For production use Hypnotoad is recommended for its prefork ability. Learn more about the [development and production environments of Mojolicious](http://mojolicio.us/perldoc/Mojolicious/Guides/Cookbook#Morbo).

    hypnotoad bin/alambic

The hypnotoad server can be reloaded by re-executing the same launch command.

It can be stopped gracefully using the -s flag:

    hypnotoad -s bin/alambic

Note: this is the same as using the prefork command within Alambic:

    bin/alambic prefork

### For development

For development, it is easier to use `morbo`. [Morbo](http://mojolicious.org/perldoc/morbo) is Mojolicious' single-thread web server for development. It notably has a auto-reload feature when files change.

    morbo bin/alambic

Note: this is the same as using the prefork command within Alambic:

    bin/alambic daemon

## Minion job queueing

The above commands start the UI daemon, but all long-running operations (e.g. project analyses) use a job queueing system, [Minion](http://mojolicious.org/perldoc/Minion). One needs to start a minion worker to actually do the work:

    bin/alambic minion worker

## Post tasks

From there everything can be done from the web interface. The dashboard is served by default on [http://localhost:3010](http://localhost:3010) if run under hypnotoad, and [http://localhost:3000](http://localhost:3000) if run under morbo. You can go to the Admin Panel and start creating projects, attach data source plugins to them, and run the analysis.
