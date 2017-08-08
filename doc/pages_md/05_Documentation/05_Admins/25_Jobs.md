title: Jobs
navi_name: Jobs

# Jobs in Alambic


## Minion

[http://mojolicious.org/perldoc/Minion](Minion) is a queue management system finely integrated into Mojolicious. It uses a Postgresql database to store information about the jobs, and can be commanded directly [http://search.cpan.org/~sri/Minion-4.02/lib/Minion.pm](from the command line).

You need to start a worker for minion to manage the queue and actually do the work. This is achieved by issuing in a command line:

    boris@midkemia mojo $ bin/alambic minion worker

The list of jobs in queue can be obtained from the command line:

    boris@midkemia mojo $ bin/alambic minion job
    142  finished  default  run_project
    141  finished  default  run_project
