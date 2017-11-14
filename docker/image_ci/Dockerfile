
FROM bbaldassari/alambic_base_centos:latest
MAINTAINER Boris boris.baldassari@castalia.solutions

EXPOSE 3000

# Switch to user alambic to execute the tests
USER alambic

# Clone Alambic repository
WORKDIR /home/alambic/alambic/
COPY . .

USER root
RUN chown -R alambic:alambic /home/alambic/alambic

# Execute processes
CMD [ "su", "-", "alambic", "-c", "sh /home/alambic/alambic/docker/image_ci/alambic_init_start.sh"]


