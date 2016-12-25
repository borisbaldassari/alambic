# Using alambic in Docker

In the /resources/docker directory, execute:
`$ docker build -t bbaldassari/alambic -f Dockerfile .`

Creates a Centos docker image, with: 
* Perlbrew, Perl, and all required modules installed,
* a fresh git clone of Alambic

This image needs a Postgresql instance to run. The docker-compose.run.yml file at the root of the repository provides an integrated environment that uses the official docker postgresql image.

In the root of the Alambic repository, execute:
`$ docker-compose -f docker-compose.run.yml up`

To execute all tests, execute:
`$ docker-compose -f docker-compose.test.yml up`

