
FROM centos:7
MAINTAINER Boris boris.baldassari@castalia.solutions

EXPOSE 3000

# Install 
RUN yum -y update; yum clean all

# Install openssh
RUN yum -y install openssh-server passwd; yum clean all
RUN mkdir /var/run/sshd
RUN ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N '' 

# Install needed applications
RUN yum install -y passwd perl-CPAN gcc make bzip2 git libxml2-devel openssl openssl-devel; yum clean all

# Install postgresql 9.5 client
RUN rpm -Uvh https://download.postgresql.org/pub/repos/yum/9.5/redhat/rhel-7-x86_64/pgdg-centos95-9.5-3.noarch.rpm
RUN yum install -y postgresql95 postgresql95-devel


# Create user alambic, password passpass
RUN adduser alambic && \
    echo passpass | passwd alambic --stdin


# Run script for alambic user, perlbrew and all mojo stuff
COPY 00_init.sh /root/00_init.sh
RUN chmod +x /root/00_init.sh 
RUN sh /root/00_init.sh

COPY 01_alambic.sh /home/alambic/01_alambic.sh
COPY psql_init.sql /home/alambic/psql_init.sql

RUN chmod +x /home/alambic/01_alambic.sh
RUN /home/alambic/01_alambic.sh

COPY alambic.conf /home/alambic/alambic/mojo/alambic.conf

#COPY alambic.conf /home/alambic/alambic/mojo/
#RUN hypnotoad script/alambic

ENTRYPOINT ["/usr/sbin/sshd", "-D"]


