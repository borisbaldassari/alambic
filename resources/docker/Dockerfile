
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
RUN yum install -y passwd perl-CPAN gcc make bzip2 git libxml2-dev openssl-dev

# Run script for alambic user, perlbrew and all mojo stuff
COPY 00_init.sh /root/
RUN chmod +x /root/00_init.sh
RUN /root/00_init.sh

ENTRYPOINT ["/usr/sbin/sshd", "-D"]


