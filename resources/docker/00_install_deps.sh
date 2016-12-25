
# This script installs the required dependencies to run Alambic.

# Install perlbew
su - alambic -c '\curl -L https://install.perlbrew.pl | bash'
echo 'source ~/perl5/perlbrew/etc/bashrc' >> ~alambic/.bashrc

# Install cpanm and perl-5.22.0
su - alambic -c 'perlbrew install-cpanm'
su - alambic -c 'perlbrew --notest install perl-5.22.0'
su - alambic -c 'perlbrew switch perl-5.22.0'

# Install all required perl modules
su - alambic -c 'POSTGRES_HOME=/usr/pgsql-9.5 cpanm Test::More inc::latest Net::IDN::Encode Mojolicious XML::LibXML List::MoreUtils IO::Socket::SSL Minion Mojolicious::Plugin::Mail DateTime Date::Parse File::chdir Text::CSV Crypt::PBKDF2 Mojo::Pg'
