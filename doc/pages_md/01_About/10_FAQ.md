title: About Alambic
navi_name: F.A.Q.

# Frquently Asked Questions

## How can I run analysis regularly?

Alambic itself doesn't provide a means to run cron-like runs of projects. It is recommended to use a scheduler for that, like Jenkins or Hudson -- that's what we use for the [demonstration instances](http://eclipse.castalia.camp).

## How to configure Alambic to run another port?

The port number Alambic listens to can be configured in the `alambic.conf` file, in the `$ALAMBIC_HOME/mojo` directory. Change the following line to whatever port you'd like. Please note however that usign a port <= 1024 requires root privileges.

    "hypnotoad" => {
      listen => ['http://*:3010'],
    },

In the docker image, mapped port can be modified in the docker-compose file by changing the line `ports:`, e.g. to use port 80 of the host:

    ports:
    - "80:3000"

Then head to http://localhost/ and start playing with Alambic.
