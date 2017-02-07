
FROM bbaldassari/alambic_base_centos:latest
MAINTAINER Boris boris.baldassari@castalia.solutions

EXPOSE 3000

# Copy as root and set permissions
COPY alambic_init.sh /home/alambic/alambic_init.sh
COPY alambic_start.sh /home/alambic/alambic_start.sh
RUN chown alambic:alambic /home/alambic/alambic_init.sh
RUN chown alambic:alambic /home/alambic/alambic_start.sh

# Switch to user alambic to execute the tests
USER alambic

# Clone Alambic repository
RUN git clone https://bitbucket.org/BorisBaldassari/alambic.git /home/alambic/alambic
COPY alambic.conf /home/alambic/alambic/mojo/alambic.conf
RUN echo "test"

# Execute processes
CMD ["sh", "/home/alambic/alambic_init.sh"]

