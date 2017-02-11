
FROM bbaldassari/alambic_base_centos:latest
MAINTAINER Boris boris.baldassari@castalia.solutions

EXPOSE 3000

# Copy as root and set permissions
COPY alambic_test.sh /home/alambic/alambic_test.sh
COPY alambic_test.pl /home/alambic/alambic_test.pl
RUN chmod +x /home/alambic/alambic_test.sh
RUN chown alambic:alambic /home/alambic/alambic_test.sh

# Switch to user alambic to execute the tests
USER alambic

# Clone Alambic repository
RUN git clone https://bitbucket.org/BorisBaldassari/alambic.git /home/alambic/alambic
COPY alambic.conf /home/alambic/alambic/mojo/alambic.conf

# copy sql init script for alambic_test.sh
COPY psql_init.sql /home/alambic/psql_init.sql

USER root

CMD [ "su", "-", "alambic", "-c", "perl", "-v" ]


