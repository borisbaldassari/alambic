
FROM bbaldassari/alambic_base_centos:latest
MAINTAINER Boris boris.baldassari@castalia.solutions

EXPOSE 3000

# Switch to user alambic to execute the tests
USER alambic

# Clone Alambic repository
RUN rm -rf /home/alambic/alambic/
RUN mkdir /home/alambic/alambic/
WORKDIR /home/alambic/alambic/
COPY . .

USER root
RUN chown -R alambic:alambic /home/alambic/alambic

USER alambic

CMD [ "su", "-", "alambic", "-c", "perl", "-v" ]


