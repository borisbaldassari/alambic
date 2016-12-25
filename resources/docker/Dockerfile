
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
RUN rpm -Uvh https://download.postgresql.org/pub/repos/yum/9.5/redhat/rhel-7-x86_64/pgdg-centos95-9.5-3.noarch.rpm \
    && yum install -y postgresql95 postgresql95-devel


# Create user alambic, password passpass
RUN adduser alambic && \
    echo passpass | passwd alambic --stdin


# Run initialisation script to install perlbrew and all mojo stuff
COPY 00_install_deps.sh /root/00_install_deps.sh
RUN chmod +x /root/00_install_deps.sh 
RUN sh /root/00_install_deps.sh

USER alambic
RUN git clone https://bitbucket.org/BorisBaldassari/alambic.git /home/alambic/alambic
COPY test_all.sh /home/alambic/test_all.sh

USER root
COPY start_test_all.sh /root/start_test_all.sh
RUN chmod +x /home/alambic/test_all.sh
RUN chmod +x /root/start_test_all.sh

CMD ["/usr/sbin/sshd", "-D"]


