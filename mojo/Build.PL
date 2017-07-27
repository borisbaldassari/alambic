use strict;
use warnings;

use 5.10.1;
use Module::Build::Mojolicious clean_install => 1;


my $builder = Module::Build::Mojolicious->new(
    module_name => 'Alambic',
    dist_version => '3.3.2',
    dist_author => 'Boris Baldassari',
    dist_abstract => 'A software development data management framework',
    license => 'EPL',
    
    requires => {
	'perl' => '5.24.0',
	'Mojolicious' => '7.28',  # Mojo::JSON booleans
	'Mojolicious::Plugin::Mail' => 0,
	'Minion' => 0,
	'Mojo::JSON' => 0,
	'Mojo::UserAgent' => 0,
	'Mojo::Pg' => 0,
	'Crypt::PBKDF2' => 0,
	'Date::Parse' => 0,
	'DateTime' => 0,
	'File::chdir' => 0,
	'File::Copy' => 0,
	'File::Basename' => 0,
	'File::Path' => 0,
	'File::stat' => 0,
	'Git::Repository' => 0,
	'IO::Socket::SSL' => 0,
	'JIRA::REST' => 0,
	'List::Util' => 0,
	'List::MoreUtils' => 0,
	'Net::IDN::Encode' => 0,
	'Time::localtime' => 0,
	'XML::LibXML' => 0,
    },
    configure_requires => {
	'Module::Build' => 0.38,
    },
    test_requires => {
	'Test::More' => 0,
    },
    
    recursive_test_files => 1,
    
    share_dir => 'lib/Alambic/files',
    
    meta_merge => {
	resources  => {
	    repository => "https://bitbucket.org/BorisBaldassari/alambic.git",
	    bugtracker => "https://bitbucket.org/BorisBaldassari/alambic/issues",
	},
#	no_index => {
#	    file      => [ 'README.pod' ],
#	},
    }
    );

$builder->create_build_script;
