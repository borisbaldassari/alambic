package Alambic::Controller::Dashboard;
use Mojo::Base 'Mojolicious::Controller';

use Data::Dumper;


# Main page for project dashboard.
sub display_summary {
    my $self = shift;

    $self->param( 'id' ) =~ m!^(.*?)(\.html)?$!;
    my $project_id = $1;
    my $page_id = $self->param( 'page' ) || '';
    
    my $run = $self->app->al->get_project_last_run($project_id);
    
    # Prepare data for template.
    $self->stash(
	project_id => $project_id,
	run => $run,
	);
    
    
    $self->render(template => 'alambic/dashboard/dashboard');
}

# Main page for project dashboard.
sub display_project {
    my $self = shift;

    my $project_id = $self->param( 'id' );
    my $page_id = $self->param( 'page' ) || '';
    print "# DBG $project_id $page_id.\n";

    if ($page_id =~ m!\.json$!) {
	&_display_project_json($self, $project_id, $page_id);
    } else {
	&_display_project_html($self, $project_id, $page_id);
    }

}

sub _display_project_json($$) {
    my ($self, $project_id, $page_id) = @_;
    
    my $run = $self->app->al->get_project_last_run($project_id);
    
    if ($page_id =~ m!^qm$!) {

        # Prepare data for template.
        $self->stash(
            project_id => $project_id,
            );    
        
        # Render json for qm.
        $self->render(json => $project_id);   

    } elsif ($page_id =~ m!^attributes$!) {
	
        my $attributes = $self->app->al->get_project_last_run($project_id)->{'attributes'};
        $self->render(json => $attributes);
                
    } elsif ($page_id =~ m!^metrics!) {
        
        my $metrics = $self->app->al->get_project_last_run($project_id)->{'metrics'};
        $self->render(json => $metrics);
        
    } elsif ($page_id =~ m!^plugins_(.+)$!) {

        my $plugin_id = $1;
        # Prepare data for template.
        $self->stash(
            project_id => $project_id,
            plugin_id => $plugin_id,
            );
        
        # Render template for plugins
        $self->render(template => 'alambic/dashboard/plugins');
        
    } else {

	my $run = $self->app->al->get_project_last_run($project_id);
	
        # Prepare data for template.
        $self->stash(
            project_id => $project_id,
	    run => $run,
            );    
        
        # Render template "alambic/dashboard.html.ep"
        $self->render(template => 'alambic/dashboard/dashboard');

    }

}

sub _display_project_html($$) {
    my ($self, $project_id, $page_id) = @_;

    my $run = $self->app->al->get_project_last_run($project_id);
    
    if ($page_id =~ m!^qm$!) {

        # Prepare data for template.
        $self->stash(
            project_id => $project_id,
            );    
        
        $self->render(template => 'alambic/dashboard/qm');   

    } elsif ($page_id =~ m!^attributes$!) {
        
        # Prepare data for template.
        $self->stash(
            project_id => $project_id,
	    attributes => $run->{'attributes'},
            );
        
        $self->render(template => 'alambic/dashboard/attributes');
        
    } elsif ($page_id =~ m!^metrics!) {
        
        my $all = $self->param('all');

        # Prepare data for template.
        $self->stash(
            all => $all,
            project_id => $project_id,
	    run =>$run,
            );    
        
        $self->render(template => 'alambic/dashboard/metrics');
        
    } elsif ($page_id =~ m!^log$!) {
        
        # Prepare data for template.
        $self->stash(
            project_id => $project_id,
            );    
        
        $self->render(template => 'alambic/dashboard/log');
        
    } elsif ($page_id =~ m!^plugins_(.+)$!) {

        my $plugin_id = $1;
        # Prepare data for template.
        $self->stash(
            project_id => $project_id,
            plugin_id => $plugin_id,
            );
        
        $self->render(template => 'alambic/dashboard/plugins');
        
    } else {
	
	$self->reply->not_found;

    }

}


1;
