package Alambic::Controller::Alambic;
use Mojo::Base 'Mojolicious::Controller';

use Data::Dumper;

# Main screen for Alambic
sub welcome {
    my $self = shift;

    # Render template "alambic/welcome.html.ep"
    $self->render();
}


sub contact_post() {
    my $self = shift;
    
    my $name = $self->param( 'name' );
    my $email = $self->param( 'email' );
    my $message = $self->param( 'message' );

    # Prepare mail content
    my $data = $self->render_mail('alambic/contact', 
				  name => $name, 
				  email => $email, 
				  message => $message);
    # Actually send the email
    $self->mail(
	mail => {
	    To => 'boris.baldassari@gmail.com',
	    Format => 'mail',
            Data => $data,
        },
    );

    $self->flash( msg => "Message has been sent. Thank you!" );
    $self->redirect_to( '/' );    
}


1;
