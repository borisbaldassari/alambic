
FROM bbaldassari/alambic_base_centos:latest
MAINTAINER Boris boris.baldassari@castalia.solutions

EXPOSE 3000

# Switch to user alambic to execute the tests
USER alambic

# Clone Alambic repository
RUN git clone https://bitbucket.org/BorisBaldassari/alambic.git /home/alambic/alambic
COPY alambic.conf /home/alambic/alambic/mojo/alambic.conf

USER root

# Execute processes
CMD [ "su", "-", "alambic", "-c", "sh /home/alambic/alambic/docker/image_ci/alambic_init_start.sh"]


