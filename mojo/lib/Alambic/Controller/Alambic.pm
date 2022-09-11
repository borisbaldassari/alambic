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

package Alambic::Controller::Alambic;
use Mojo::Base 'Mojolicious::Controller';

use Data::Dumper;

# Main screen for Alambic
sub welcome {
  my $self = shift;

  # Render template "alambic/welcome.html.ep"
  $self->render();
}

# Display login screen.
sub login() {
  my $self = shift;

  $self->render(template => 'alambic/login');
}

# Display login screen -- post processing.
sub login_post() {
  my $self = shift;

  my $username = $self->param('username');
  my $password = $self->param('password');

  # Check return value for login.
  my $users = $self->app->al->users();
  my $valid = $users->validate_user($username, $password);
  if ($valid) {
    $self->session('session_user' => $username);
    $self->flash(
      msg => "You have been successfully authenticated as user $username.");
    $self->redirect_to('/user/' . $username . '/profile');
  }
  else {
    delete $self->session->{session_user};
    $self->flash(msg => "Wrong login/password. Sorry.");
    $self->redirect_to('/login');
  }
}

# Clear the session cookies and logout user.
sub logout() {
  my $self = shift;

  delete $self->session->{session_user};

  $self->redirect_to('/');
}


# Used when the user failed auth and asks for Admin.
sub failed() {
  my $self = shift;

  $self->render(template => 'alambic/failed', status => 403);
}

# Post processing to send an email to the administrator of the instance.
sub contact_post() {
  my $self = shift;

  my $name    = $self->param('name');
  my $email   = $self->param('email');
  my $message = $self->param('message');

  # Prepare mail content
  my $data = $self->render_mail(
    'alambic/contact',
    name    => $name,
    email   => $email,
    message => $message
  );

  # Get the administrator email address.
  my $admin = $self->app->al->get_user('administrator');

  if (defined($admin->{'email'})) {

    # Actually send the email
    $self->mail(
      mail => {To => $admin->{'email'}, Format => 'mail', Data => $data});
    $self->flash(msg => "Message has been sent. Thank you!");
  }
  else {
    $self->flash(msg =>
        "Message could not be sent: cannot find an email address for administrator."
    );
  }

  $self->redirect_to('/');
}


1;


=encoding utf8

=head1 NAME

B<Alambic::Controller::Alambic> - Routing logic for Alambic general-purpose
actions (install, login, etc.)

=head1 SYNOPSIS

Routing logic for Alambic general-purpose actions (install, login, etc.). This is automatically called by the Mojolicious framework.

=head1 METHODS

=head2 C<welcome()> 

Home page and main screen for Alambic.

=head2 C<login()> 

Display login screen.

=head2 C<login_post()> 

Display login screen -- post processing.

=head2 C<logout()> 

Clear the session cookies and logout user.

=head2 C<failed()> 

Used when the user failed auth and asks for Admin.

=head2 C<contact_post()> 

Post processing to send an email to the administrator of the instance.

=head1 SEE ALSO

L<Alambic>, L<http://alambic.io>, L<https://bitbucket.org/BorisBaldassari/alambic>, L<Mojolicious>.

=cut
