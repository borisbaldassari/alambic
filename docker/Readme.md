# Using alambic in Docker

A few Docker images are setup:
* A base image built from a CentOS 7 (`alambic_base_centos`) that contains all dependencies: Postgresql, Perl, Mojolicious, R, and all required modules.
* A test image built from `alambic_base_centos` that clones the Alambic repository and executes all tests.
* A release image built from `alambic_base_centos` that provides a complete Alambic ready to use.

Please note that both test and release images need a postgresql container to run. A compose file (and codeship file) is provided to run the complete setup in one command.

## Building the base image

In the $AL_HOME/docker/image_base_centos directory, execute:
`$ docker build -t bbaldassari/alambic_base_centos -f Dockerfile .`

It creates a Centos docker image, with:
* Postgresql 9.5 (client),
* Perlbrew, Perl, Mojolicious and all required modules,
* The latest release of R and all required packages.

## Building the test image

In the $AL_HOME/docker/image_test directory, execute:
`$ docker build -t bbaldassari/alambic_test -f Dockerfile .`

It creates an image with Alambic installed and ready for test. 

These images need a Postgresql instance to run. The docker-compose.run.yml file at the root of the repository provides an integrated environment that uses the official docker postgresql image.

In the root of the Alambic repository, execute:
`$ docker-compose -f docker-compose.run.yml up`

To execute all tests, execute:
`$ docker-compose -f docker-compose.test.yml up`
