package Alambic::Controller::Tools;
use Mojo::Base 'Mojolicious::Controller';

use Data::Dumper;

# Displays a list of jobs with information and actions
sub summary {
    my $self = shift;

    $self->render(template => 'alambic/admin/tools');   

}

# Displays information about a single job.
sub display {
    my $self = shift;

    my $tool_id = $self->param( 'id' );

    # Prepare data for template and render.
    $self->stash( tool_id => $tool_id );
    $self->render(template => 'alambic/admin/tool');   

}

1;
