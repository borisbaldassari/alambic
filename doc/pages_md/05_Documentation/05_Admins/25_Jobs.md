title: Admin > Jobs
navi_name: Jobs

# Admin > Jobs

This section displays the list of jobs in the queue.

![Alambic Admin Web UI](/images/admins_jobs.png)

## Information

Information displayed for each job is:

* Job ID
* Task executed by the job, e.g. run_analysis, run_plugin.
* Status, one of `inactive`, `active`, `failed`, or `finished`.
* Dates of creation (and end, if the job has completed) of the job.
* Arguments provided to the Job for its execution.

For each job, administrators can (icons on the left, from left to right):
* Show details (including log) of the job.
* Restart the job with same set of arguments.
* Delete the jobs.

See the [documentation for Minion jobs](http://mojolicious.org/perldoc/Minion/Job) for more details.

Successful (i.e. in status `finished`) jobs are automatically deleted after one day.


## Minion

[Minion](http://mojolicious.org/perldoc/Minion) is a queue management system finely integrated into Mojolicious. It uses a Postgresql database to store information about the jobs, and can be commanded directly [from the command line](http://search.cpan.org/~sri/Minion-7.05/lib/Minion/Command/minion/job.pm).

You need to start a worker for minion to manage the queue and actually do the work. This is achieved by issuing in a command line:

    boris@midkemia mojo $ bin/alambic minion worker

The list of jobs in queue can be obtained from the command line:

    boris@midkemia mojo $ bin/alambic minion job
    142  finished  default  run_project
    141  finished  default  run_project

Display list of workers running:

    boris@midkemia mojo $ bin/alambic minion job -w
    83  midkemia:837

Display statistics about the queue:

    boris@midkemia mojo $ bin/alambic minion job -s
    {
      "active_jobs" => 0,
      "active_workers" => 0,
      "delayed_jobs" => 0,
      "enqueued_jobs" => 215,
      "failed_jobs" => 3,
      "finished_jobs" => 1,
      "inactive_jobs" => 0,
      "inactive_workers" => 1
    }

The full list of options for the Minion queueing system is:

    boris@midkemia mojo $ bin/alambic minion help job
    Usage: APPLICATION minion job [OPTIONS] [IDS]

      ./myapp.pl minion job
      ./myapp.pl minion job 10023
      ./myapp.pl minion job -w
      ./myapp.pl minion job -w 23
      ./myapp.pl minion job -s
      ./myapp.pl minion job -f 10023
      ./myapp.pl minion job -q important -t foo -S inactive
      ./myapp.pl minion job -e foo -a '[23, "bar"]'
      ./myapp.pl minion job -e foo -P 10023 -P 10024 -p 5 -q important
      ./myapp.pl minion job -R -d 10 10023
      ./myapp.pl minion job --remove 10023
      ./myapp.pl minion job -b jobs -a '[12]'
      ./myapp.pl minion job -b jobs -a '[12]' 23 24 25

    Options:
      -A, --attempts <number>     Number of times performing this new job will be
                                  attempted, defaults to 1
      -a, --args <JSON array>     Arguments for new job or worker remote control
                                  command in JSON format
      -b, --broadcast <command>   Broadcast remote control command to one or more
                                  workers
      -d, --delay <seconds>       Delay new job for this many seconds
      -e, --enqueue <task>        New job to be enqueued
      -f, --foreground            Retry job in "minion_foreground" queue and
                                  perform it right away in the foreground (very
                                  useful for debugging)
      -h, --help                  Show this summary of available options
          --home <path>           Path to home directory of your application,
                                  defaults to the value of MOJO_HOME or
                                  auto-detection
      -l, --limit <number>        Number of jobs/workers to show when listing
                                  them, defaults to 100
      -m, --mode <name>           Operating mode for your application, defaults to
                                  the value of MOJO_MODE/PLACK_ENV or
                                  "development"
      -o, --offset <number>       Number of jobs/workers to skip when listing
                                  them, defaults to 0
      -P, --parent <id>           One or more jobs the new job depends on
      -p, --priority <number>     Priority of new job, defaults to 0
      -q, --queue <name>          Queue to put new job in, defaults to "default",
                                  or list only jobs in this queue
      -R, --retry                 Retry job
          --remove                Remove job
      -S, --state <name>          List only jobs in this state
      -s, --stats                 Show queue statistics
      -t, --task <name>           List only jobs for this task
      -w, --workers               List workers instead of jobs, or show
                                  information for a specific worker
