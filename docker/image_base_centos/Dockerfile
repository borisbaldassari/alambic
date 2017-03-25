FROM centos:7
MAINTAINER Boris boris.baldassari@castalia.solutions

EXPOSE 3000

# Install
RUN yum -y update; yum clean all

# Install openssh
RUN yum -y install openssh-server passwd wget libcurl-devel passwd perl-CPAN gcc \
    make bzip2 git libxml2-devel openssl openssl-devel; yum clean all
RUN mkdir /var/run/sshd && ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N ''

# Install postgresql 9.5 client
RUN rpm -Uvh https://download.postgresql.org/pub/repos/yum/9.5/redhat/rhel-7-x86_64/pgdg-centos95-9.5-3.noarch.rpm \
    && yum install -y postgresql95 postgresql95-devel


# Create user alambic, password passpass
RUN adduser alambic \
    && echo passpass | passwd alambic --stdin


# Install R and all dependencies
RUN rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm; \
    yum install -y R;
COPY alambic_install_r_deps.sh /root/alambic_install_r_deps.sh
RUN chmod +x /root/alambic_install_r_deps.sh
RUN /bin/bash -c "/root/alambic_install_r_deps.sh"

# Copy perl deps file for alambic
RUN echo "REBUILD ME now please! "
COPY alambic_install_perl_deps.sh /home/alambic/alambic_install_perl_deps.sh
RUN chmod +x /home/alambic/alambic_install_perl_deps.sh
RUN chown alambic /home/alambic/alambic_install_perl_deps.sh

# Install pandoc
RUN yum -y install pandoc; yum clean all

# Switch to user alambic to install Perl
USER alambic

# Install Perl, Mojolicious and all dependencies
RUN /bin/bash -c  "/home/alambic/alambic_install_perl_deps.sh"

# Switch back to user root
USER root

CMD ["/usr/sbin/sshd", "-D"]
