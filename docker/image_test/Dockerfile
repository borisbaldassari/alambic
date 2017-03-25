
FROM bbaldassari/alambic_base_centos:latest
MAINTAINER Boris boris.baldassari@castalia.solutions

EXPOSE 3000

# Switch to user alambic to execute the tests
USER alambic

# Clone Alambic repository
RUN echo "REBUILD ME now please!"
RUN git clone https://bitbucket.org/BorisBaldassari/alambic.git /home/alambic/alambic

USER root

CMD [ "su", "-", "alambic", "-c", "perl -v" ]


