title: Frequently Asked Questions
navi_name: F.A.Q.

# Frequently Asked Questions

## How can I run project analyses regularly?

Alambic itself doesn't provide a means to run cron-like runs of projects. It is recommended to use a scheduler for that, like Jenkins or Hudson -- that's what we use for the [demonstration instances](http://eclipse.castalia.camp). Most Alambic features are available through the REST API.

TODO add documentation from alambic app here.

## What is the default password for administrator?

When initialising Alambic, a default login/password pair is created, so administrators can connect, create more users and obviously change the password.

Default login is `administrator` and default password is `password`.

## How to configure Alambic to run another port?

The port number Alambic listens to can be configured in the `alambic.conf` file, in the `$ALAMBIC_HOME/mojo` directory. Change the following line to whatever port you'd like. Please note however that usign a port <= 1024 requires root privileges.

    "hypnotoad" => {
      listen => ['http://*:3010'],
    },

In the docker image, mapped port can be modified in the docker-compose file by changing the line `ports:`, e.g. to use port 80 of the host:

    ports:
    - "80:3000"

Then head to http://localhost/ and start playing with Alambic.

## How did Alambic start?

The idea of Alambic originates from the [Polarsys](https://polarsys.org) Working Group and the [Maturity Assessment task force](https://wiki.polarsys.org/Maturity_Assessment_WG). A [dashboard](http://dashboard.polarsys.org) was developed as a support of the discusssion. The application was then entirely re-written to be more generic and adaptable to other contexts by [Castalia Solutions](http://castalia.solutions).

Since Alambic is a fork of the PolarSys dashboard, there is a lot of information (mostly historical by now, but still relevant) available on the PolarSys wiki, since the project started there. From the beginning the PolarSys dashboard has been driven by the PolarSys members: the definition of the quality model, attributes, metrics has been discussed on the [public mailing list](https://dev.eclipse.org/mailman/listinfo/polarsys-iwg), and the full retrieval and analysis process has received a common agreement on the mailing list. The project and/or its features have also been presented a few times:

* EclipseCon France 2016. [Eclipse projects and Open data: get to know your project with Alambic](https://www.eclipsecon.org/france2016/session/eclipse-projects-and-open-data-get-know-your-project-alambic)
* International Conference on Software & Systems Engineering and their Applications, 2016. [Alambic: An Open-Source Platform for Software Engineering Data Management. The Case of Embedded Software Development](http://castalia.camp/dl/pub/icssea_2016_the_alambic_platform.pdf)
* EclipseCon France 2015 Unconference (working session).
* EclipseCon Europe 2014. [Assessing project quality for improvement: the PolarSys Maturity Assessment initiative](https://www.eclipsecon.org/europe2014/session/assessing-project-quality-improvement-polarsys-maturity-assessment-initiative)
* EclipseCon Europe 2014 Unconference: https://polarsys.org/wiki/EclipseConEurope2014
* EclipseCon France 2014 Unconference: https://wiki.eclipse.org/Eclipse_WG_Unconference_France_2014
* EclipseCon France 2013. [Software Quality: The Eclipse Way and Beyond ](http://www.eclipsecon.org/france2013/sessions/software-quality-eclipse-way-and-beyond)


## How can I contribute?

Any contribution, user, code, test, talk, nice word, smile, beer, is welcome.

There are many different ways to contribute to Alambic:

* **Documentation**: this wiki can be improved. If there is anything you can say about Alambic, please go, create and edit !
* **Code and tests**: you can fork the project, pick up an issue, edit and send in a pull request. Pull requests will be checked quickly, promise! :-)
* **Communication & dissemination** are important matters too.

If in doubt, do not hesitate to [contact me](http://castalia.solutions/contact.html) and I'll be happy to help.

## What is the severity on recommendations?

* High is severity 3
* Normal is severity 2
* Low is severity 1
* Info is severity 0
