
# Create user alambic, password passpass
adduser alambic
echo passpass | passwd alambic --stdin

su - alambic -c '\curl -L https://install.perlbrew.pl | bash'
echo 'source ~/perl5/perlbrew/etc/bashrc' >> ~alambic/.bashrc
su - alambic -c 'perlbrew install-cpanm'
su - alambic -c 'perlbrew --notest install perl-5.22.0'

su - alambic -c 'perlbrew switch perl-5.22.0'
#su - alambic -c 'cpanm Test::More inc::latest Net::IDN::Encode Mojolicious XML::LibXML List::MoreUtils IO::Socket::SSL Minion Mojo::Pg Mojolicious::Plugin::Mail DateTime Date::Parse File::chdir'

#rpm -Uvh https://download.postgresql.org/pub/repos/yum/9.5/redhat/rhel-7-x86_64/pgdg-centos95-9.5-3.noarch.rpm

#su - alambic -c 'cpanm Mojolicious XML::LibXML List::MoreUtils IO::Socket::SSL Minion Mojo::Pg Mojolicious::Plugin::Mail DateTime Date::Parse File::chdir'
#su - alambic -c 'git clone https://bitbucket.org/BorisBaldassari/alambic.git'



