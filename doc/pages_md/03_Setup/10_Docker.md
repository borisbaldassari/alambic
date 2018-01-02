title: Alambic in Docker
navi_name: Docker


# Executing Alambic in Docker

A few Docker images are setup:

* A **base image** built from a CentOS 7 (`alambic_base_centos`) that contains all dependencies: Postgresql, Perl, Mojolicious, R, and all required modules.
* A **test image** `image_test` built from `alambic_base_centos` that clones the Alambic repository and executes all tests.
* A **release image** `alambic_ci` built from `alambic_base_centos` that provides a complete Alambic ready to use.

The official repository for Alambic images is:

* [https://hub.docker.com/r/bbaldassari/](https://hub.docker.com/r/bbaldassari/)

Please note that both test and ci images need a postgresql container to run. A compose file is provided to run the complete setup in one single neat command.

## Running Alambic using compose

You can execute Alambic in a single command line, thanks to docker compose. The `docker-compose.run.yml` file at the root of the repository provides an integrated environment that uses the official docker `postgresql:9.5` and `bbaldassari/alambic` images, runs an init script and sets the application up for use.

In the root of the Alambic repository, execute:

    $ docker-compose -f docker-compose.run.yml up

Then head up to [http://localhost:3000](http://localhost:3000) and play with Alambic. Default login/password is `administrator`/`password`. Note that in some (docker corner) cases one needs to identify the container's network interface, e.g. [http://172.19.0.3:3000](http://172.19.0.3:3000).

## Running Alambic tests using compose

The `docker-compose.test.yml` file at the root of the repository provides an integrated environment that uses the official docker `postgresql:9.5` image, runs all perl tests and outputs the result of [Test::Harness](http://search.cpan.org/~leont/Test-Harness/lib/Test/Harness.pm).

In the root of the Alambic repository, execute:

    $ docker-compose -f docker-compose.test.yml run alambic_test


## Using Docker volumes

The test and CI Docker images both export a set of volumes:

* alambic_db is the directory of the PostgreSQL cluster
* alambic_fs is the directory of the Alambic code itself. It also contains file-system visualisations and data files for all analysed projects.

These volumes can easily be identified using the `docker volumes list` command:

    $ docker volume list
    DRIVER              VOLUME NAME
    local               alambic_db
    local               alambic_fs

Volumes can be directly accessed on the host filesystem, usually in the docker lib directory: `/var/lib/docker/volumes/`.

When run without the compose file, the docker image can be started with a volume using the following command:

    docker run -P --network=bbalambic_default --mount \
      source=alambic_fs,target=/home/alambic \
      bbaldassari/alambic_ci


# Building Docker images


## Building the base image

The base image is continuously built on codefresh, and pushed to the docker hub at

* [https://hub.docker.com/r/bbaldassari/alambic_base_centos/](https://hub.docker.com/r/bbaldassari/alambic_base_centos/)

In the `$AL_HOME/docker/image_base_centos directory`, execute:

    $ docker build -t bbaldassari/alambic_base_centos -f Dockerfile .

It creates a Centos docker image, with:

* Postgresql 9.5 (client),
* Perlbrew, Perl, Mojolicious and all required modules,
* The latest release of R and all required packages.

You can also get the image directly from docker hub with the docker cli, like this:

    docker pull bbaldassari/alambic_base_centos

## Building the latest Alambic test image

The test image is continuously built on codefresh, and pushed to the docker hub:

* [https://hub.docker.com/r/bbaldassari/alambic_test](https://hub.docker.com/r/bbaldassari/alambic_test)

In the `$AL_HOME/docker/image_test` directory, execute:

    $ docker build -t bbaldassari/alambic_test -f Dockerfile .

It creates an image called `bbaldassari/alambic_test` with Alambic installed and ready for test.

You can also get individually from docker like this:

    docker pull bbaldassari/alambic_test

## Building the latest Alambic CI image

The ci image is continuously built on codefresh, and pushed to the docker hub:

* [https://hub.docker.com/r/bbaldassari/alambic_ci](https://hub.docker.com/r/bbaldassari/alambic_ci)

In the `$AL_HOME/docker/image_ci` directory, execute:

    $ docker build -t bbaldassari/alambic_ci -f Dockerfile .

It creates an image called `bbaldassari/alambic_ci` with Alambic installed and ready for test.

You can also get individually from docker like this:

    $ docker pull bbaldassari/alambic_ci
