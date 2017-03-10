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

    $self->stash(
	project_id => $project_id,
	run => $run,
	);
    
    
    $self->render(template => 'alambic/dashboard/dashboard');
}

# Secondary pages for project dashboard.
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

# Main page for project history.
sub display_history {
    my $self = shift;

    my $project_id = $self->param( 'id' );
    my $plugin_id = $self->param( 'plugin' );
    my $build_id = $self->param( 'build' );
    my $page_id = $self->param( 'page' ) || '';

    if ($page_id =~ m!\.json$!) {
	&_display_project_history_json($self, $project_id, $plugin_id, $build_id, $page_id);
    } else {
	&_display_project_history_html($self, $project_id, $plugin_id, $build_id, $page_id);
    }

}


sub display_plugins {
    my $self = shift;

    my $project_id = $self->param( 'id' );
    my $plugin_id = $self->param( 'plugin' );
    my $page_id = $self->param( 'page' ) || '';

    my $plugin_conf = $self->app->al->get_plugins()->get_plugin($plugin_id)->get_conf();
    
    if ($plugin_conf->{'type'} =~ m!^cdata$!) {
	
    }
    
    # Action depends on the type of file requested
    if ( grep( /$page_id/, keys %{$plugin_conf->{'provides_viz'}} ) ) {

	# If the page is a viz, render 'alambic/dashboard/plugins'
	$self->stash(
	    project_id => $project_id,
	    plugin_id => $plugin_id,
	    page_id => $page_id,
	    );
	$self->render( template => 'alambic/dashboard/plugins' );
	
    } else {

	my $ret;
	
	# Identify the 404s from all requests
	if ( grep( /$page_id(.html)?/, keys %{$plugin_conf->{'provides_figs'}} ) ) {
#	    print Dumper(`ls`);
	    # If the page is a fig, reply static file under 'projects/output'
    print "# PLUG " . Dumper(`pwd`);
	    $ret = '../../../../projects/' . $project_id . '/output/' . $project_id . '_' . $page_id;
    print "# PLUG RET " . Dumper($ret);
	    
	} elsif ( grep( /$page_id/, keys %{$plugin_conf->{'provides_data'}} ) ) {
	    
	    # If the page is a data, reply static file under 'projects/output' or 'projects/input'
	    my $file_out = '../../../../projects/' . $project_id . '/output/' . $project_id . "_" . $page_id;
	    my $file_in = '../../../../projects/' . $project_id . '/input/' . $project_id . "_" . $page_id;
	    
	    if (-e $file_out) {
		$ret = '../../../../projects/' . $project_id . '/output/' . $project_id . "_" . $page_id;
	    } elsif (-e $file_in) {
		$ret = '../../../../projects/' . $project_id . '/input/' . $project_id . "_" . $page_id;
	    } 
	}   
	 
	if ( defined($ret) ) {
		$self->reply->static( $ret );
	} else {
	    $self->reply->not_found;
	    
	}
    }
}


# Is used only for backward compatibility and robustness.
# R reports often use figures/ for the generated plots. We want to support
# that for people developing R books.
sub display_figures {
    my $self = shift;

    my $project_id = $self->param( 'id' );
    my $plugin_id = $self->param( 'plugin' );
    my $page_id = $self->param( 'page' ) || '';

    my $plugin_conf = $self->app->al->get_plugins()->get_plugin($plugin_id)->get_conf();
    
    # If the page is a data, reply static file under 'projects/output'
    print "# FIG " . Dumper(`pwd`);
    $self->reply->static( '../../../../projects/' . $project_id . '/output/figures/' . $page_id );
}


# Manages custom data post requests
sub display_plugins_post {
    my $self = shift;

    my $project_id = $self->param( 'id' );
    my $plugin_id = $self->param( 'plugin' );
    my $page_id = $self->param( 'page' ) || '';
}



sub _display_project_json($$) {
    my ($self, $project_id, $page_id) = @_;
    
    my $run = $self->app->al->get_project_last_run($project_id);
    my $project = $self->app->al->get_project($project_id);
    
    if ($page_id =~ m!^qm.json$!) {

	my $models = $self->app->al->get_models();
	my $qm_ret = $project->get_qm($models->get_qm(), $models->get_attributes(), $models->get_metrics());
	$self->render(json => $qm_ret);

    } elsif ($page_id =~ m!^qm_full.json$!) {
        		
	my $models = $self->app->al->get_models();
	my $qm_ret = $project->get_qm($models->get_qm(), $models->get_attributes(), $models->get_metrics());
	my $qm_full = {
	    "name" => "Alambic Full Quality Model",
	    "version" => "" . localtime(),
	    "children" => $qm_ret,
	};
        $self->render(json => $qm_full); 

    } elsif ($page_id =~ m!^attributes.json$!) {
	
        my $attributes = $self->app->al->get_project_last_run($project_id)->{'attributes'};
        $self->render(json => $attributes);
                
    } elsif ($page_id =~ m!^metrics.json$!) {
        
        my $metrics = $self->app->al->get_project_last_run($project_id)->{'metrics'};
        $self->render(json => $metrics);
                
    } elsif ($page_id =~ m!^cdata.json$!) {
        
        my $cdata = $self->app->al->get_project_last_run($project_id)->{'cdata'};
        $self->render(json => $cdata);

    } elsif ($page_id =~ m!^info.json$!) {
        
        my $info = $self->app->al->get_project_last_run($project_id)->{'info'};
        $self->render(json => $info);

    } elsif ($page_id =~ m!^recs.json$!) {
	
        my $recs = $self->app->al->get_project_last_run($project_id)->{'recs'};
        $self->render(json => $recs);
        
    } else {
	
	$self->reply->not_found;
	
    }

}

sub _display_project_html($$) {
    my ($self, $project_id, $page_id) = @_;

    my $run = $self->app->al->get_project_last_run($project_id);
    $page_id =~ s!\.html$!!;
    
    if ($page_id =~ m!^qm$!) {

        $self->stash( project_id => $project_id );    
        
        $self->render(template => 'alambic/dashboard/qm');
	
    } elsif ($page_id =~ m!^history$!) {

	my %runs;
	my $runs_info = $self->app->al->get_repo_db->get_project_all_runs($project_id);
	foreach my $run_ (@{$runs_info}) {
	    $runs{ $run_->{'id'} } = $self->app->al->get_repo_db->get_project_run($project_id, $run_->{'id'});
	}

        $self->stash(
            project_id => $project_id,
	    runs => \%runs,
            );
        
        $self->render(template => 'alambic/dashboard/history'); 

    } elsif ($page_id =~ m!^data$!) {
        
        $self->stash(
            project_id => $project_id,
	    run => $run,
            );
        
        $self->render(template => 'alambic/dashboard/data'); 

    } elsif ($page_id =~ m!^info$!) {
        
        $self->stash(
            project_id => $project_id,
	    run => $run,
            );
        
        $self->render(template => 'alambic/dashboard/info');
        
    } elsif ($page_id =~ m!^metrics!) {
        
	my $models = $self->app->al->get_models();
	my $all = $self->param('all');
	
        $self->stash(
            all => $all,
            project_id => $project_id,
	    run => $run,
	    models => $models,
            );
        
        $self->render(template => 'alambic/dashboard/metrics');

    } elsif ($page_id =~ m!^attributes$!) {
        
        $self->stash(
            project_id => $project_id,
	    attributes => $run->{'attributes'},
	    attributes_conf => $run->{'attributes_conf'},
	    models => $self->app->al->get_models(),
            );
        
        $self->render(template => 'alambic/dashboard/attributes');
        
    } elsif ($page_id =~ m!^recs!) {
        
        my $all = $self->param('all');

        $self->stash(
            project_id => $project_id,
	    recs => $run->{'recs'},
            );
        
        $self->render(template => 'alambic/dashboard/recs');
        
    } elsif ($page_id =~ m!^log$!) {
        
        $self->stash(
            project_id => $project_id,
            );    
        
        $self->render(template => 'alambic/dashboard/log');
        
    } elsif ( grep( /$page_id/, keys %{$self->app->al->get_plugins()->get_names_all()} ) ) {
        
        $self->stash(
            project_id => $project_id,
	    plugin_id => $page_id,
	    run => $run,
	    models => $self->app->al->get_models(),
	    plugin => $self->app->al->get_plugins()->get_plugin($page_id),
            );
        
        $self->render(template => 'alambic/dashboard/plugin');
        
    } else {
	
	$self->reply->not_found;

    }

}


sub _display_project_history_json($$$$) {
    my ($self, $project_id, $plugin_id, $build_id, $page_id) = @_;
    
    my $run = $self->app->al->get_project_run($project_id, $build_id);
    
    if ($page_id =~ m!^attributes.json$!) {
	
        my $attributes = $run->{'attributes'};
        $self->render(json => $attributes);
                
    } elsif ($page_id =~ m!^attributes_conf.json$!) {
        
        my $attributes = $run->{'attributes_conf'};
        $self->render(json => $attributes);
                
    } elsif ($page_id =~ m!^metrics.json$!) {
        
        my $metrics = $run->{'metrics'};
        $self->render(json => $metrics);
                
    } elsif ($page_id =~ m!^indicators.json$!) {
        
        my $inds = $run->{'indicators'};
        $self->render(json => $inds);
                
    } elsif ($page_id =~ m!^cdata.json$!) {
        
        my $cdata = $run->{'cdata'};
        $self->render(json => $cdata);

    } elsif ($page_id =~ m!^info.json$!) {
        
        my $info = $run->{'info'};
        $self->render(json => $info);

    } elsif ($page_id =~ m!^recs.json$!) {
	
        my $recs = $run->{'recs'};
        $self->render(json => $recs);
        
    } else {
	
	$self->reply->not_found;
	
    }

}

sub _display_project_history_html($$$$) {
    my ($self, $project_id, $plugin_id, $build_id, $page_id) = @_;

    my $run = $self->app->al->get_project_run($project_id, $build_id);
    $page_id =~ s!\.html$!!;
    
    if ($page_id =~ m!^metrics!) {
        
	my $models = $self->app->al->get_models();
	my $all = $self->param('all');
	
        $self->stash(
            all => $all,
            project_id => $project_id,
	    run => $run,
	    models => $models,
            );
        
        $self->render(template => 'alambic/dashboard/metrics');

    } elsif ($page_id =~ m!^attributes$!) {
        
        $self->stash(
            project_id => $project_id,
	    attributes => $run->{'attributes'},
	    attributes_conf => $run->{'attributes_conf'},
	    models => $self->app->al->get_models(),
            );
        
        $self->render(template => 'alambic/dashboard/attributes');
        
    } elsif ($page_id =~ m!^recs!) {
        
        my $all = $self->param('all');

        $self->stash(
            project_id => $project_id,
	    recs => $run->{'recs'},
            );
        
        $self->render(template => 'alambic/dashboard/recs');
        
    } else {

	$self->reply->not_found;

    }

}


1;
