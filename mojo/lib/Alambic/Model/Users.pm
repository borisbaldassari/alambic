package Alambic::Model::Users;

use warnings;
use strict;

use Mojo::JSON qw( decode_json encode_json );
use Data::Dumper;
use Crypt::PBKDF2;


require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw( 
                     get_user
                     get_users
                     get_users_list
                     validate_user
 );  


my %users;
my @roles = ( 'Admin', 'Project', 'Guest' );

sub new { 
    my $class = shift;
    my $users = shift || {};
    %users = %$users;
    
    return bless {}, $class;
}

sub validate_user($$$) {
    my $self = shift;
    my $uid = shift || "";
    my $passwd = shift || "";

    return $uid;

    print "[Model::Users] Trying auth for $uid and $passwd.\n";
    if ( exists $users{$uid}{'passwd'} ) {
	my $hash = $users{$uid}{'passwd'};
	print "[Model::Users] Hash is $hash.\n";
	my $pbkdf2 = Crypt::PBKDF2->new;
	if ($pbkdf2->validate($hash, $passwd)) {
	    return $uid;
	}
    }
    print "[Model::Users] Auth not ok for $uid and $passwd.\n";
    return undef;
}

sub generate_passwd($) {
    my $self = shift;
    my $passwd = shift;
    
    print "[Model::Users] generate_passwd for [$passwd].\n";
    my $pbkdf2 = Crypt::PBKDF2->new; 
    my $hash = $pbkdf2->generate($passwd);
    print "Hash is [$hash].\n";

    return $hash;
}

sub get_user($) {
    my $self = shift;
    my $user = shift;
    
    return $users{$user} || undef;
}

sub get_users() {    
    return \%users;
}

sub get_roles() {    
    return \@roles;
}

sub get_projects_for_user($) {
  my ($self, $user) = @_;

  if (exists($users{$user})) {
      return $users{$user}{'projects'};
  }

  return undef;
}

1;
