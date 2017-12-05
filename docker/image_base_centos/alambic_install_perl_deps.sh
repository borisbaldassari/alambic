

# Download perlbrew and install it.
\curl -L https://install.perlbrew.pl | bash
echo 'source ~/perl5/perlbrew/etc/bashrc' >> ~alambic/.bashrc

source ~alambic/.bashrc

# Using perlbrew, install cpanm, recent version of perl, and all modules
perlbrew install-cpanm
perlbrew --notest install perl-5.26.1
perlbrew switch perl-5.26.1

POSTGRES_HOME=/usr/pgsql-9.5 cpanm Sub::Identify DBI DBD::Pg inc::Module::Install Digest::MD5 Crypt::PBKDF2 Date::Parse DateTime File::chdir File::Basename File::Copy File::Path File::stat List::Util List::MoreUtils Minion Mojolicious Mojo::JSON Mojo::UserAgent Mojo::Pg XML::LibXML Text::CSV Time::localtime Mojolicious::Plugin::Mail Test::More Test::Perl::Critic Net::IDN::Encode IO::Socket::SSL Git::Repository JIRA::REST Mojolicious::Plugin::InstallablePaths Pod::ProjectDocs GitLab::API:v3 Moose HTML::Entities Template



