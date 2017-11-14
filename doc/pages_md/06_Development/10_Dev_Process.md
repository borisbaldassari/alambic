title: Development process
navi_name: Development process


# Alambic Development Process

## Continuous integration

For historical reasons, Alambic uses two different services for Continuous Integration. In both cases we use Docker to make sure that the environment is pristine.

### Codefresh

The **[Codefresh](https://codefresh.io)** service builds the official building channel for the docker images. It notably builds the following images:

* `image_base_centos` is a base CentOS image with all requirements installed: system packages, R and Perl modules. [![Codefresh build status]( https://g.codefresh.io/api/badges/build?repoOwner=BorisBaldassari&repoName=alambic&branch=master&pipelineName=alambic_base_centos&accountName=borisbaldassari&type=cf-1)]( https://g.codefresh.io/repositories/BorisBaldassari/alambic/builds?filter=trigger:build;branch:master;service:589f16b56f0280010035a254~alambic_base_centos)

* `image_test` is run on every `git push`. It installs Alambic and runs the complete test suite using `bin/alambic test`. On success it pushes the image to `https://hub.docker.com/r/bbaldassari/alambic_test/`. [![Codefresh build status]( https://g.codefresh.io/api/badges/build?repoOwner=BorisBaldassari&repoName=alambic&branch=master&pipelineName=alambic_test&accountName=borisbaldassari&type=cf-1)]( https://g.codefresh.io/repositories/BorisBaldassari/alambic/builds?filter=trigger:build;branch:master;service:589ee0d5a567350100749f20~alambic_test)

* `image_ci` is run on every `git push`. It installs Alambic and initialises the application, and then waits for connections on port `3000`. [![Codefresh build status]( https://g.codefresh.io/api/badges/build?repoOwner=BorisBaldassari&repoName=alambic&branch=master&pipelineName=alambic_run&accountName=borisbaldassari&type=cf-1)]( https://g.codefresh.io/repositories/BorisBaldassari/alambic/builds?filter=trigger:build;branch:master;service:589f19636f0280010035a5f2~alambic_run)

### Codeship

**[Codeship](https://codeship.io)** executes only the Alambic test image to ensure that testing is done thoroughly and independently of the CI setup (even docker sometimes has caveats).

<p><a href="https://app.codeship.com/projects/189806"><img src="https://app.codeship.com/projects/8f5ae970-a10d-0134-6d00-664a346b6816/status?branch=master" alt="CI status" /></a></p>

### Results on BitBucket

Both services push their results back to the BitBucket repository and set build flags, as shown on the right of the image below.

----

![Alambic CI status](/images/alambic_ci_flags.png)

----

## Release engineering

Before any release (and hopefully before any commit) the release script located in `$ALAMBIC_HOME/resources/scripts/releng/alambic_release.sh` must be executed. The script executes the following actions:

* Run various checks,
* Tidy up code of all Perl files located under `lib/` and `t/`,
* Generate POD from Perl code and move it to the web site section in `$ALAMBIC_HOME/doc/public/perldoc`.

Example run:

    boris@midkemia bb_alambic $ sh resources/scripts/releng/alambic_release.sh 

    Hi. working on version [3.3.1-dev] of Alambic.

    ----- Creating tmp directory: /tmp/tmp.YvSi0lnRsH.

    ----- Creating log file: /home/boris/Projects/bb_alambic/resources/scripts/releng/alambic_checks.txt.

    ----- Checking Alambic version.
    [OK]  Checking that alambic.conf has the correct version.

    ----- Executing SLOCCount on Alambic code.
      * Found 5855 lines of Perl code in lib dir.
      * Found 1645 lines of Perl code in test (t/) dir.

    ----- Tidying source files.
    Tidy all files in mojo/lib/.
    mojo/lib/Alambic.pm
    mojo/lib/Alambic/Tools/Git.pm
    mojo/lib/Alambic/Tools/R.pm
    mojo/lib/Alambic/Model/Alambic.pm
    mojo/lib/Alambic/Model/Tools.pm
    mojo/lib/Alambic/Model/RepoFS.pm
    mojo/lib/Alambic/Model/Plugins.pm
    mojo/lib/Alambic/Model/Users.pm
    mojo/lib/Alambic/Model/Models.pm
    mojo/lib/Alambic/Model/RepoDB.pm
    mojo/lib/Alambic/Model/Wizards.pm
    mojo/lib/Alambic/Model/Project.pm
    mojo/lib/Alambic/Commands/backup.pm
    mojo/lib/Alambic/Commands/init.pm
    mojo/lib/Alambic/Commands/about.pm
    mojo/lib/Alambic/Commands/password.pm
    mojo/lib/Alambic/Controller/Admin.pm
    mojo/lib/Alambic/Controller/Alambic.pm
    mojo/lib/Alambic/Controller/Dashboard.pm
    mojo/lib/Alambic/Controller/Tools.pm
    mojo/lib/Alambic/Controller/Users.pm
    mojo/lib/Alambic/Controller/Repo.pm
    mojo/lib/Alambic/Controller/Documentation.pm
    mojo/lib/Alambic/Controller/Jobs.pm
    mojo/lib/Alambic/Wizards/EclipsePmi.pm
    mojo/lib/Alambic/Plugins/EclipsePmi.pm
    mojo/lib/Alambic/Plugins/PmdAnalysis.pm
    mojo/lib/Alambic/Plugins/StackOverflow.pm
    mojo/lib/Alambic/Plugins/ProjectSummary.pm
    mojo/lib/Alambic/Plugins/Hudson.pm
    Tidy all files in mojo/t/.
    mojo/t/ui/010_admin.t
    mojo/t/ui/011_auth.t
    mojo/t/ui/002_documentation.t
    mojo/t/ui/001_basic.t
    mojo/t/unit/Tools/R.t
    mojo/t/unit/Tools/Git.t
    mojo/t/unit/Model/Plugins.t
    mojo/t/unit/Model/RepoFS.t
    mojo/t/unit/Model/Alambic.t
    mojo/t/unit/Model/Users.t
    mojo/t/unit/Model/Tools.t
    mojo/t/unit/Model/RepoDB.t
    mojo/t/unit/Model/Project.t
    mojo/t/unit/Model/Models.t
    mojo/t/unit/Model/Wizards.t
    mojo/t/unit/Plugins/EclipsePmi.t

    ----- Generating web site from markdown.
    dumping everything to /home/boris/Projects/bb_alambic/doc/dump ...
    index.html ... done.
    About.html ... done.
    About/Features.html ... done.
    About/Community.html ... done.
    About/FAQ.html ... done.
    About/For_research.html ... done.
    Plugins.html ... done.
    Plugins/Pre.html ... done.
    Plugins/Pre/EclipsePmi.html ... done.
    Plugins/Pre/Hudson.html ... done.
    Plugins/Pre/PmdAnalysis.html ... done.
    Plugins/Pre/StackOverflow.html ... done.
    Plugins/Post.html ... done.
    Plugins/Post/ProjectSummary.html ... done.
    Plugins/Tools.html ... done.
    Plugins/Tools/Git.html ... done.
    Plugins/Wizards.html ... done.
    Plugins/Wizards/EclipsePmi.html ... done.
    Setup.html ... done.
    Setup/Prerequisites.html ... done.
    Setup/Install.html ... done.
    Setup/Run.html ... done.
    Setup/Upgrade.html ... done.
    Setup/Docker.html ... done.
    Documentation.html ... done.
    Documentation/Users.html ... done.
    Documentation/Users/Dashboard.html ... done.
    Documentation/Users/QualityModel.html ... done.
    Documentation/Admins.html ... done.
    Documentation/Admins/Summary.html ... done.
    Documentation/Admins/Database.html ... done.
    Documentation/Admins/ModelsAdmin.html ... done.
    Documentation/Admins/Jobs.html ... done.
    Documentation/Admins/Users.html ... done.
    Documentation/Admins/Tools.html ... done.
    Documentation/Tasks.html ... done.
    Documentation/Tasks/Backups.html ... done.
    Documentation/Tasks/Customise.html ... done.
    Documentation/Tasks/CLI.html ... done.
    Development.html ... done.
    Development/Contributing.html ... done.
    Development/Dev_Process.html ... done.
    Development/Ethics.html ... done.
    done!

    ----- Generating perldoc html files in doc section.

    ----- Processing completed. Have a good day!
