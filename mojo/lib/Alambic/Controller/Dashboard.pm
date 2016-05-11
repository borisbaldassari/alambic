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

    if ($page_id =~ m!\.json$!) {
	&_display_project_json($self, $project_id, $page_id);
    } else {
	&_display_project_html($self, $project_id, $page_id);
    }

}


sub display_plugins {
    my $self = shift;

    my $project_id = $self->param( 'id' );
    my $plugin_id = $self->param( 'plugin' );
    my $page_id = $self->param( 'page' ) || '';

    my $plugin_conf = $self->app->al->get_plugins()->get_plugin($plugin_id)->get_conf();
    
    # Action depends on the type of file requested
    if ( grep( /$page_id/, keys %{$plugin_conf->{'provides_viz'}} ) ) {

	# If the page is a viz, render 'alambic/dashboard/plugins'
	$self->stash(
	    project_id => $project_id,
	    plugin_id => $plugin_id,
	    page_id => $page_id,
	    );
	$self->render( template => 'alambic/dashboard/plugins' );

    } elsif ( grep( /$page_id(.html)?/, map {$plugin_conf->{'provides_figs'}{$_}} keys %{$plugin_conf->{'provides_figs'}} ) ) {
	
	# If the page is a fig, reply static file under 'projects/output'
	$self->reply->static( '../projects/' . $project_id . '/output/' . $page_id );

    } elsif ( grep( /$page_id/, keys %{$plugin_conf->{'provides_data'}} ) ) {

	# If the page is a data, reply static file under 'projects/output'
	$self->reply->static( '../projects/' . $project_id . '/output/' . $page_id );

    } else {

	$self->flash( msg => "Cannot find [$project_id/$plugin_id/$page_id]." );
	$self->redirect_to( '/projects/' . $project_id );

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
    
    if ($page_id =~ m!^qm(\.html)?$!) {

        # Prepare data for template.
        $self->stash(
            project_id => $project_id,
            );    
        
        $self->render(template => 'alambic/dashboard/qm');     

    } elsif ($page_id =~ m!^data(\.html)?$!) {
        
        # Prepare data for template.
        $self->stash(
            project_id => $project_id,
	    run => $run,
            );
        
        $self->render(template => 'alambic/dashboard/data'); 

    } elsif ($page_id =~ m!^info(\.html)?$!) {
        
        # Prepare data for template.
        $self->stash(
            project_id => $project_id,
	    run => $run,
            );
        
        $self->render(template => 'alambic/dashboard/info');
        
    } elsif ($page_id =~ m!^metrics(\.html)?!) {
        
        my $all = $self->param('all');

        # Prepare data for template.
        $self->stash(
            all => $all,
            project_id => $project_id,
	    run => $run,
            );
        
        $self->render(template => 'alambic/dashboard/metrics');

    } elsif ($page_id =~ m!^attributes(\.html)?$!) {
        
        # Prepare data for template.
        $self->stash(
            project_id => $project_id,
	    attributes => $run->{'attributes'},
            );
        
        $self->render(template => 'alambic/dashboard/attributes');
        
    } elsif ($page_id =~ m!^recs(\.html)?!) {
        
        my $all = $self->param('all');

        # Prepare data for template.
        $self->stash(
            project_id => $project_id,
	    recs => $run->{'recs'},
            );
        
        $self->render(template => 'alambic/dashboard/recs');
        
    } elsif ($page_id =~ m!^log(\.html)?$!) {
        
        # Prepare data for template.
        $self->stash(
            project_id => $project_id,
            );    
        
        $self->render(template => 'alambic/dashboard/log');
        
    } else {
	
	$self->reply->not_found;

    }

}


1;
