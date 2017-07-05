title: Running Alambic
navi_name: Run


# Running Alambic

For production use Hypnotoad is recommended for its prefork ability. Learn more about the [development and production environments of Mojolicious](http://mojolicio.us/perldoc/Mojolicious/Guides/Cookbook#Morbo).

    hypnotoad bin/alambic

The hypnotoad server can be reloaded by re-executing the same launch command, and can be stopped using the -s flag:

    hypnotoad -s bin/alambic

From there everything can be done from the web interface. The dashboard is served by default on http://localhost:3010 if run under hypnotoad, and http://localhost:3000 if run under morbo. You can go to the Admin Panel and start creating projects, attach data source plugins to them, and run the analysis.

## Minion

[http://mojolicious.org/perldoc/Minion](Minion) is a queue management system finely integrated into Mojolicious. It uses a Postgresql database to store information about the jobs, and can be commanded directly [http://search.cpan.org/~sri/Minion-4.02/lib/Minion.pm](from the command line).

You need to start a worker for minion to manage the queue and actually do the work. This is achieved by issuing in a command line:

    bin/alambic minion worker
