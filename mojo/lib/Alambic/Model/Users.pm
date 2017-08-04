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

package Alambic::Model::Users;

use warnings;
use strict;

use Data::Dumper;
use Crypt::PBKDF2;


require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(
  get_user
  get_roles
  get_users
  get_projects_for_user
  validate_user
  generate_passwd

);


my %users;
my @roles = ('Admin', 'Project', 'Guest');

# Constructor to build a new L<Alambic::Model::Users> object.
sub new {
  my $class = shift;
  my $users = shift || {};
  %users = %$users;

  return bless {}, $class;
}

# Check that the user exists and the password is correct.
sub validate_user($$$) {
  my $self   = shift;
  my $uid    = shift || "";
  my $passwd = shift || "";

  if (exists $users{$uid}{'passwd'}) {
    my $hash   = $users{$uid}{'passwd'};
    my $pbkdf2 = Crypt::PBKDF2->new;
    if ($pbkdf2->validate($hash, $passwd)) {
      return $uid;
    }
  }
  return undef;
}

# Encrypt a password using L<Crypto::PBKDF2>.
sub generate_passwd($) {
  my $self   = shift;
  my $passwd = shift;

  my $pbkdf2 = Crypt::PBKDF2->new;
  my $hash   = $pbkdf2->generate($passwd);

  return $hash;
}

# Get information about a user. 
# Return a hash reference.
sub get_user($) {
  my $self = shift;
  my $user = shift || "";

  return exists $users{$user} ? $users{$user} : undef;
}

# Get information about all users.
# Return a hash reference.
sub get_users() {
  return \%users;
}

# Get list of all roles.
# Return a array ref of strings.
sub get_roles() {
  return \@roles;
}

# Get list of projects for a user.
sub get_projects_for_user($) {
  my ($self, $user) = @_;

  if (exists($users{$user})) {
    return $users{$user}{'projects'};
  }

  return undef;
}


1;


=encoding utf8

=head1 NAME

B<Alambic::Model::Users> - A class to manage, and get information about, users.

=head1 SYNOPSIS

    my $users = Alambic::Model::Users->new();    
    my $list = $users->get_roles();

=head1 DESCRIPTION

B<Alambic::Model::Users> provides a common interface to manage, and get 
information about, users in Alambic.

=head1 METHODS

=head2 C<new()>

    my $users = Alambic::Model::Users->new();    

Creates a new L<Alambic::Model::Users> object to interact with users of 
Alambic.

=head2 C<validate_user()>

    if ($users->validate_user('boris', 'password') {
      print "Yeah\n";
    }

Check that the user exists and the password is correct. 
Returns the user ID if ok, undef otherwise.

=head2 C<generate_passwd()>

    my $hash = $user->generate_passwd('mypassword');

Encrypt a password using L<Crypto::PBKDF2>. Returns a hash.

=head2 C<get_user()>

    my $u = $users->get_user('boris');

Get information about a user. Returns a hash reference.

    {
      'notifs' => {},
      'name' => 'Administrator',
      'roles' => ['Admin'],
      'email' => 'alambic@castalia.solutions',
      'passwd' => '{X-PBKDF2}HMACSHA1:AAAD6A:5R2HIw==:3c7E0POr1PCmC7XQdahjgr/PDus=',
      'projects' => {},
      'id' => 'administrator'
    }

=head2 C<get_users()>

    my $u = $users->get_users(),

Get information about all users. Returns a hash reference.

    {
      'administrator' => {
        'notifs' => {},
        'name' => 'Administrator',
        'roles' => ['Admin'],
        'email' => 'alambic@castalia.solutions',
        'passwd' => '{X-PBKDF2}HMACSHA1:AAAD6A:5R2HIw==:3c7E0POr1PCmC7XQdahjgr/PDus=',
        'projects' => {},
        'id' => 'administrator'
      }
    }

=head2 C<get_roles()>

    my $list = $users->get_roles();

Get the list of roles defined in this instance.

    [
      'Admin',
      'Project',
      'Guest'
    ];

=head2 C<get_projects_for_user()>

    my $list = $users->get_projects_for_user('boris');

Get list of projects for a user.

=head1 SEE ALSO

L<Mojolicious>, L<http://alambic.io>, L<https://bitbucket.org/BorisBaldassari/alambic>

=cut

