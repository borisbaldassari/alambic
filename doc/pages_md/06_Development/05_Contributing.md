title: Contributing to Alambic
navi_name: Contribute


# Developing Alambic

Contributions to Alambic are warmly welcome, and should take place on BitBucket:

* <a href="https://bitbucket.org/BorisBaldassari/alambic"><i class="fa fa-bitbucket fa-lg"></i> &nbsp; Project Development Home</a>

Issues and pull requests will be treated diligently.

GitHub is used for dissemination only, there should be no issue filled there. Pull requests however will be monitored and treated.


## Environment

Mojolicious has a special feature to help developers write code. By executing the `morbo` command instead of hypnotoad, the application is restarted every time a file is modified. Go to the mojo directory and open a terminal (or command) and type in:

    morbo bin/alambic

It is still required to run the minion job management system in order to run projects.

    bin/alambic minion worker

This will start the Mojolicious 'development' server and listen to port 3000, making all file changes instantly available in the running application. Note however that the minion plugin does not provide such a hot-reload mechanism, and the workers need to be restarted to see new changes.

## Conventions

Alambic follows Mojolicious' style rules for its code. You can check it out here:

* [http://mojolicious.org/perldoc/Mojolicious/Guides/Contributing](http://mojolicious.org/perldoc/Mojolicious/Guides/Contributing)

Main points:

* Code has to be run through [Perl::Tidy](http://search.cpan.org/~shancock/Perl-Tidy-20170521/) with the included [.perltidyrc](https://bitbucket.org/BorisBaldassari/alambic/src/53e12e36a356dcda1556261c28f4fff2b8281d63/resources/scripts/releng/perltidyrc?at=master), and everything should look like it was written by a single person.
* Code shoud come with tests and documentation.



## Testing

All tests should be placed into the `mojo/t/` directory, and use the `.t` extension. This way they are automatically run by Alambic (and the continuous integration system, btw).

To run all Alambic tests, simply execute the Alambic command:

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
    /home/boris/Projects/bb_alambic/mojo/bin/../t/unit/Tools/Git.t ........... ok
    /home/boris/Projects/bb_alambic/mojo/bin/../t/unit/Tools/R.t ............. ok
    All tests successful.
    Files=16, Tests=603, 160 wallclock secs ( 0.09 usr  0.05 sys +  9.34 cusr  0.90 csys = 10.38 CPU)
    Result: PASS

To execute single tests, use the `prove` command:

    boris@midkemia mojo $ prove -v -l lib t/unit/Model/Models.t
    t/unit/Model/Models.t ..
    ok 1 - use Alambic::Model::Models;
    ok 2 - An object of class 'Alambic::Model::Models' isa 'Alambic::Model::Models'
    ok 3 - Full QM children tree is conform.
    ok 4 - Full QM name is conform.
    ok 5 - Single metric retrieval is ok.
    ok 6 - Metrics retrieved are ok.
    ok 7 - Get full metrics children tree is conform on desc.
    ok 8 - Get full metrics children tree is conform on parents.
    ok 9 - Full metrics name is conform.
    ok 10 - Only one active metric is defined (METRIC1).
    ok 11 - get_metrics_repos is ok: one repository containing 1 metric.
    ok 12 - Single attribute retrieval is ok.
    ok 13 - Attributes retrieved are ok.
    ok 14 - Get full attributes children tree is conform on desc.
    ok 15 - Get full attributes children tree is conform on name.
    ok 16 - Full attributes name is conform.
    ok 17 - Quality model retrieval is ok.
    ok 18 - An object of class 'Alambic::Model::Models' isa 'Alambic::Model::Models'
    ok 19 - Attributes retrieved are ok.
    ok 20 - Single metric retrieved is ok.
    ok 21 - Metrics retrieved are ok.
    1..21
    ok
    All tests successful.
    Files=1, Tests=21,  0 wallclock secs ( 0.01 usr  0.00 sys +  0.03 cusr  0.01 csys =  0.05 CPU)
    Result: PASS

Using `perl` instead:

    boris@midkemia mojo $ perl -I lib t/unit/Model/Models.t
    ok 1 - use Alambic::Model::Models;
    ok 2 - An object of class 'Alambic::Model::Models' isa 'Alambic::Model::Models'
    ok 3 - Full QM children tree is conform.
    ok 4 - Full QM name is conform.
    ok 5 - Single metric retrieval is ok.
    ok 6 - Metrics retrieved are ok.
    ok 7 - Get full metrics children tree is conform on desc.
    ok 8 - Get full metrics children tree is conform on parents.
    ok 9 - Full metrics name is conform.
    ok 10 - Only one active metric is defined (METRIC1).
    ok 11 - get_metrics_repos is ok: one repository containing 1 metric.
    ok 12 - Single attribute retrieval is ok.
    ok 13 - Attributes retrieved are ok.
    ok 14 - Get full attributes children tree is conform on desc.
    ok 15 - Get full attributes children tree is conform on name.
    ok 16 - Full attributes name is conform.
    ok 17 - Quality model retrieval is ok.
    ok 18 - An object of class 'Alambic::Model::Models' isa 'Alambic::Model::Models'
    ok 19 - Attributes retrieved are ok.
    ok 20 - Single metric retrieved is ok.
    ok 21 - Metrics retrieved are ok.
    1..21
