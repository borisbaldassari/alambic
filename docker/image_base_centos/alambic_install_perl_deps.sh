

# Download perlbrew and install it.

\curl -L https://install.perlbrew.pl | bash
echo 'source ~/perl5/perlbrew/etc/bashrc' >> ~alambic/.bashrc

# Using perlbrew, install cpanm, recent version of perl, and all modules

perlbrew install-cpanm
perlbrew --notest install perl-5.24.1
perlbrew switch perl-5.24.1

cpanm Crypt::PBKDF2 Date::Parse DateTime File::chdir File::Basename File::Copy File::Path File::stat List::Utils List::MoreUtils Minion Mojolicious Mojo::JSON Mojo::UserAgent Mojo::Pg XML::LibXML Text::CSV Time::localtime Mojolicious::Plugin::Mail Test::More Test::Perl::Critic Net::IDN::Encode IO::Socket::SSL
