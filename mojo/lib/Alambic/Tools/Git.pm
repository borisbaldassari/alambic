#########################################################
#
# Copyright (c) 2015-2017 Castalia Solutions and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
#
# Contributors:
#   Boris Baldassari - Castalia Solutions
#
#########################################################

package Alambic::Tools::Git;

use strict;
use warnings;

use Alambic::Model::RepoFS;
use Git::Repository;
use Date::Parse;
use File::Path qw(make_path);
use Data::Dumper;

# Main configuration hash for the tool
my %conf = (
  "id"      => "git",
  "name"    => "Git Tool",
  "desc"    => "Provides Git commands and features.",
  "ability" => [

#   "install",
    "methods",

#   "project"
  ],
  "type"   => "tool",
  "params" => {
    "path_git" => "The absolute path to the git binary.",
    "proxy"    => "The URL of a proxy, if any.",
  },
  "provides_methods" => {
    "git_clone" => "Clone a project git repository locally.",
    "git_pull"  => "Execute a pull from a git repository.",
    "git_clone_or_pull" =>
      "Execute a pull from a git repository, clone if it doesn't exist.",
    "git_log"     => "Retrieves log from a local git repository.",
    "git_commits" => "Retrieves commits for a git repository.",
  },
);

my $git;
my $git_url;
my $project_id;
my $repofs;

# Constructor to build a new Git object.
#
# Params:
#   - $project_id: the id of the project analysed.
#   - $git_url: the url of the git repository to clone
sub new {
  my $class = shift;
  $project_id = shift;
  $git_url    = shift;

  my $dir = &_get_src_path($class, $project_id);

  # Will be used for the configuration of the git::repository object.
  my $conf;

  # Should we use a proxy?
  if (defined($conf->{'params'}{'proxy'})) {
    $conf->{'env'}{'HTTP_PROXY'}  = $conf->{'params'}{'proxy'};
    $conf->{'env'}{'HTTPS_PROXY'} = $conf->{'params'}{'proxy'};
  }
  
  $conf->{'env'}{'LANG'} = "en_GB";

  # Create projects input dir if it does not exist
  if (not &_is_a_git_directory($dir)) {
    Git::Repository->run(clone => $git_url => $dir);
  }

  # Now create Git object with dir.
  $git = Git::Repository->new(work_tree => $dir, $conf);
  $repofs = Alambic::Model::RepoFS->new();

  return bless {}, $class;
}

# Get configuration for this Git plugin instance.
sub get_conf() {
  return \%conf;
}

# Get path to sources cloned from repository.
sub _get_src_path($) {
  my ($self, $project) = @_;

  return "projects/" . $project . "/src";
}

# Automated setup procedure for the tool.
sub install() {
}

# Returns Git version as a string.
sub version() {

  my $git_cmd = "git --version";
  my @out     = `$git_cmd 2>&1`;
  chomp @out;

  for my $l (@out) {
    if ($l =~ m/^(git version .*)$/) {
      return $1;
    }
    else {
      return "Git version not found.";
    }
  }
  return "Git version not found.";
}

# Self-test method for the tool.
sub test() {

  my @log;

  my $path_git;
  for my $path (split /:/, $ENV{PATH}) {
    if (-f "$path/git" && -x _ ) { $path_git = "$path/git"; last; }
  }

  if (defined($path_git)) {
    push(@log, "OK: Git exec found in PATH at [$path_git].");
  }
  else {
    push(@log, "ERROR: Git exec NOT found in PATH.");
  }


  return \@log;
}


# Function to get a git repository locally, not even knowing if
# it's already there or not. If it exists, it will be pulld.
# If it doesn't, it will be cloned.
sub git_clone_or_pull() {
  my ($self) = @_;

  my @log;

  my $dir = &_get_src_path($self, $project_id);

  if (&_is_a_git_directory($dir)) {

    # start from an existing working copy
    eval {
      push(@log,
        "[Tools::Git] Directory [$dir] exists. Version is " . $git->version);
      @log = (@log, @{&git_pull($self)});
    };
  }
  else {
    # repository doesn't exist, clone src from git server.
    push(@log, "[Tools::Git] Directory [$dir] doesn't exist. Cloning.");
    @log = (@log, @{&git_clone($self)});
  }

  return \@log;
}

# Utility to know if a directory is a git repo.
sub _is_a_git_directory($) {
  my ($dir) = @_;

  if (-e "$dir/.git/") {
    return 1;
  }
  else {
    return 0;
  }
}


# Function to clone a git repository locally. It assumes the repository
# doesn't already exists (fails otherwise).
sub git_clone() {
  my ($self) = @_;

  my @log;

  my $dir = &_get_src_path($self, $project_id);

  push(@log, "[Tools::Git] Cloning [$git_url] to [$dir].");
  Git::Repository->run(clone => $git_url, $dir);

  return \@log;
}


# Function to get the log from a git repository. It assumes the repository
# already exists (fails otherwise).
sub git_log() {
  my ($self) = @_;

  my @log;

  my $output = $git->run(('log'));

  $repofs->write_input($project_id, "import_git.txt", $output);
  push(@log,
    "[Tools::Git] Getting Git log for [$project_id] in [${project_id}_import_git.txt]."
  );

  return \@log;
}

# Returns an array of commits. It assumes the repository
# already exists (fails otherwise).
sub git_commits() {
  my ($self) = @_;

  my @log = $git->run(
    ('log', '--format=%H %at %s%n author [%aE]%n committer [%cE]', '--stat'));
  my $log_ = _parse_git_log(@log);

  return $log_;
}


# Utility to parse git log
# http://preaction.me/talks/Perl/Scripting-Git.html
sub _parse_git_log {
  my @lines = @_;

  my @commits;
  my %commit;
  my $id;
  for my $line (@lines) {
    if ($line =~ /^(\w+) (\d+) (.*)$/) {
      $id             = $1;
      $commit{'id'}   = $1;
      $commit{'time'} = $2;
      $commit{'msg'}  = $3;
    }
    elsif ($line =~ /^\s+author\s\[([^]]*)\]/) {
	if ($1 !~ m!^$!) {
	    $commit{'auth'} = $1;
	} else {
	    $commit{'auth'} = "Unknown";
	}
    }
    elsif ($line =~ /^\s+committer \[([^]]*)\]/) {
	if ($1 !~ m!^$!) {
	    $commit{'cmtr'} = $1;
	} else {
	    $commit{'cmtr'} = "Unknown";
	}
    }
    elsif ($line
      =~ /^\s+(\d+) files? changed(, (\d+) insert[^,]+)?(, (\d+) del[^,]+)?.*$/)
    {
      $commit{'mod'} = $1;
      $commit{'add'} = $3 if defined($3);
      $commit{'del'} = $5 if defined($5);
      my %commit_ = %commit;
      push(@commits, \%commit_);
      undef %commit;
    }
    elsif ($line =~ /^\s*$/) {
    }
    else {
      print "Failed [$line].\n" unless ($line =~ m!\|!);
    }
  }

  return \@commits;
}


# Function to pull from a git repository. It is assumed that the clone
# directory already exists.
#
# Params:
sub git_pull() {
  my ($self) = @_;

  my @log;
  my @output = $git->run(('pull'));

  if (scalar @output == 1 && $output[0] =~ m!Already up-to-date!) {
    push(@log, "[Tools::Git] Pulling from origin. Already up-to-date.");
  }
  else {
    push(@log,
      "[Tools::Git] Pulling from origin. Pull output: " . $output[0] . ".");
  }

  return \@log;
}


1;


=encoding utf8

=head1 NAME

B<Alambic::Tools::Git> - A plugin to manage a git repository.

=head1 DESCRIPTION

B<Alambic::Tools::Git> provides an interface to the Git software 
configuration management tool within Alambic. It specifically provides 
methods to clone and pull a repository, and to get the log of commits.

For the complete configuration see the user documentation on the web site: L<https://alambic.io/Plugins/Tools/Git.html>.

=head2 C<new()>

    my $tool = Alambic::Tools::Git->new(
    'test.project', 
    'https://BorisBaldassari@bitbucket.org/BorisBaldassari/alambic.git');
    my $version = $tool->version();

Build a new Git object. 


If the git directory exists, the plugin will use it. Otherwise a clone will be 
automatically executed at object startup.

=head2 C<get_conf()>

    my $conf = $tool->get_conf();

Get configuration for this Git plugin instance. Returns a hash 
reference.

    (
      "id" => "git",
      "name" => "Git Tool",
      "desc" => "Provides Git commands and features.",
      "ability" => [
        "methods", "project"
      ],
      "type" => "tool",
      "params" => {"path_git" => "The absolute path to the git binary.",},
      "provides_methods" => {
        "git_clone" => "Clone a project git repository locally.",
        "git_pull" => "Execute a pull from a git repository.",
        "git_clone_or_pull" => "Execute a pull from a git repository, 
          clone if it doesn't exist.",
        "git_log" => "Retrieves log from a local git repository.",
        "git_commits" => "Retrieves commits for a git repository.",
      },
    )

=head2 C<version()>

    my $version = $tool->version();

Returns Git version as a string.

=head2 C<test()>

    my $log = $tool->test();

Self-test method for the tool. Returns a log as an array reference.

    [
      'OK: Git exec found in PATH at [/usr/bin/git].'
    ]

=head2 C<git_clone_or_pull()>

    $log = $tool->git_clone_or_pull();

Function to get a git repository locally, not even knowing if 
it's already there or not. If it exists, it will be pulld.
If it doesn't, it will be cloned

=head2 C<git_clone()>

    $log = $tool->git_clone('test.project',
      'https://BorisBaldassari@bitbucket.org/BorisBaldassari/alambic.git');

Function to clone a git repository locally. It assumes the repository
doesn't already exists (fails otherwise).

=head2 C<git_log()>

    $git->git-log('modeling.sirius');

Function to get the log from a git repository. It assumes the repository
already exists (fails otherwise).

Log file is written in the input directory of the project data space.

=head2 C<git_commits()>

    my $commits = $git->git_commits();

Returns an array of commits

=head2 C<git_pull()>

    $git->git_pull();

Function to pull from a git repository. It is assumed that the clone
directory already exists.

=head1 SEE ALSO

L<https://alambic.io/Plugins/Tools/Git.html>, L<https://stackoverflow.com>,

L<Mojolicious>, L<http://alambic.io>, L<https://bitbucket.org/BorisBaldassari/alambic>


=cut


