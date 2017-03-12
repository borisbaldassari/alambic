
FROM bbaldassari/alambic_base_centos:latest
MAINTAINER Boris boris.baldassari@castalia.solutions

EXPOSE 3000

# Switch to user alambic to execute the tests
USER alambic

# Clone Alambic repository
RUN echo "REBUILD ME now pleased!"
RUN git clone https://bitbucket.org/BorisBaldassari/alambic.git /home/alambic/alambic
COPY /home/alambic/alambic/docker/image_test/alambic.conf /home/alambic/alambic/mojo/alambic.conf

USER root

CMD [ "su", "-", "alambic", "-c", "perl -v" ]


