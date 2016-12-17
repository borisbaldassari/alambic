
# Create user alambic, password passpass
adduser alambic
echo passpass | passwd alambic --stdin

su - alambic -c '\curl -L https://install.perlbrew.pl | bash'
echo 'source ~/perl5/perlbrew/etc/bashrc' >> ~alambic/.bashrc
su - alambic -c 'perlbrew install-cpanm'
su - alambic -c 'perlbrew --notest install perl-5.22.0'

su - alambic -c 'perlbrew switch perl-5.22.0'

su - alambic -c 'cpanm Test::More inc::latest Net::IDN::Encode Mojolicious XML::LibXML List::MoreUtils IO::Socket::SSL Minion Mojolicious::Plugin::Mail DateTime Date::Parse File::chdir Text::CSV Crypt::PBKDF2'

su - alambic -c 'POSTGRES_HOME=/usr/pgsql-9.5 cpanm  Mojo::Pg'

su - alambic -c 'git clone https://bitbucket.org/BorisBaldassari/alambic.git'

su - alambic -c 'PGPASSWORD=pass4alambic psql -h postgres < psql_init.sql'

