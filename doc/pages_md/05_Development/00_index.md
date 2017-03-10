title: Alambic Development
navi_name: Development


## Developing Alambic

Mojolicious has a special feature to help developers write code. By executing the `morbo` command instead of hypnotoad, the application is restarted every time a file is modified. Go to the mojo directory and open a terminal (or command) and type in:

    morbo script/alambic

This will start the Mojolicious 'development' server.

For production use Hypnotoad is recommended for its prefork ability. Learn more about the [development and production environments of Mojolicious](http://mojolicio.us/perldoc/Mojolicious/Guides/Cookbook#Morbo).

    hypnotoad script/alambic

The hypnotoad server can be reloaded by re-executing the same launch command, and can be stopped using the -s flag:

    hypnotoad -s script/alambic

From there everything can be done from the web interface. The dashboard is served by default on http://localhost:3010 if run under hypnotoad, and http://localhost:3000 if run under morbo. You can go to the Admin Panel and start creating projects, attach data source plugins to them, and run the analysis.

## Minion

[http://mojolicious.org/perldoc/Minion](Minion) is a queue management system finely integrated into Mojolicious. It uses a Postgresql database to store information about the jobs, and can be commanded directly [http://search.cpan.org/~sri/Minion-4.02/lib/Minion.pm](from the command line).

You need to start a worker for minion to manage the queue and actually do the work. This is achieved by issuing in a command line:

    script/alambic minion worker

# Updates

Any running instance of Alambic can be updated from the Alambic project repository without losing any information. Of course, it is recommended to make a backup prior to any update.

To do the update go to the alambic directory and issue a git pull command:

    boris@camp ~/alambic$ git pull
    remote: Counting objects: 6, done.
    remote: Compressing objects: 100% (6/6), done.
    remote: Total 6 (delta 3), reused 0 (delta 0)
    Unpacking objects: 100% (6/6), done.
    From bitbucket.org:BorisBaldassari/alambic
       709aae9..eef3c49  master     -> origin/master
    Updating 709aae9..eef3c49
    Fast-forward
     mojo/public/images/alambic_presentation_data.jpg |  Bin 0 -> 110023 bytes
     1 file changed, 0 insertions(+), 0 deletions(-)
     create mode 100644 mojo/public/images/alambic_presentation_data.jpg

Then restart hypnotoad if needed and the instance should have been updated. If anything goes wrong, you can still restore the last backup file. Check the [documentation on backup](Backups) for more information.
