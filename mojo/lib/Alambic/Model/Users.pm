package Alambic::Model::Users;

use warnings;
use strict;

use Scalar::Util 'weaken';
use Mojo::JSON qw( decode_json encode_json );
use Data::Dumper;


require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw( read_all_files
                 get_all_users
                 get_list );  


my %users;

sub new { 
    my $class = shift;
    my $app = shift;
    
    my $hash = {app => $app};
    weaken $hash->{app};

    return bless $hash, $class;
}

sub read_all_files() {
    my $self = shift;

    my $file_users = $self->{app}->config->{'file_users'};
    my $pass_str;
    open my $fh, '<', $file_users or die "Could not open users file [$file_users].\n";
    while (<$fh>) { chomp; $pass_str .= $_; }
    close $fh;

    my $tmp_users = decode_json( $pass_str );
    %users = %{$tmp_users->{'children'}};
    
    return 1;
}

sub validate_user($$$) {
    my $self = shift;
    my $uid = shift || "";
    my $passwd = shift || "";
    my $realm = shift;
    
    $self->{app}->log->info( "[Model::Users] validate_user trying uid [$uid] pass [$passwd]." );

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

sub has_user_project {
  my $self = shift;
  my $user = shift || '';
  my $project = shift || '';

  # Return the role of the user for the project, if ok.
  if ( exists( $users{$user}{'projects'}{$project} ) ) {
      return $users{$user}{'projects'}{$project};
  }

  # Fail
  return undef;
}

sub get_all_users() {
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
