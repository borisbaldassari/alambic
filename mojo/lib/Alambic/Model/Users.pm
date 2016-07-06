package Alambic::Model::Users;

use warnings;
use strict;

use Mojo::JSON qw( decode_json encode_json );
use Data::Dumper;


require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw( 
                     get_user
                     get_users
                     get_users_list
                     validate_user
 );  


my %users;

sub new { 
    my $class = shift;
    my $users = shift;
    %users = %$users;
    
    return bless {}, $class;
}

sub validate_user($$$) {
    my $self = shift;
    my $uid = shift || "";
    my $passwd = shift || "";
    
    print "[Model::Users] validate_user trying uid [$uid] pass [$passwd].\n";

    return $uid if ( exists $users{$uid}{'passwd'} && $users{$uid}{'passwd'} eq $passwd );
    return undef;
}

sub is_user_authenticated {
  my ($self, $user, $page) = @_;

  if (not defined( $user )) { return undef }

  # Success if user has the given page in its alambic rights.
  if ( grep( /^${page}$/, @{$users{$user}{'alambic'}} ) ) {
      return 1;
  }

  # Fail
  return undef;
}

sub get_user($) {
    my $self = shift;
    my $user = shift;
    
    return $users{$user} || undef;
}

sub get_users() {    
    return \%users;
}

sub get_projects_for_user($) {
  my ($self, $user) = @_;

  if (exists($users{$user})) {
      return $users{$user}{'projects'};
  }

  return undef;
}

1;
