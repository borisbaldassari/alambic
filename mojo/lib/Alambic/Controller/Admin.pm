package Alambic::Controller::Admin;
use Mojo::Base 'Mojolicious::Controller';

use Mojo::JSON qw( encode_json decode_json );
use Data::Dumper;
use File::stat;
use Time::localtime;

# Main screen for Alambic admin.
sub summary {
    my $self = shift;
    
    $self->render( template => 'alambic/admin/summary' );
}


# JSON access for models data.
sub data {
    my $self = shift;
    my $page = $self->param( 'page' );
    
    my $models = $self->app->al->get_models();

    if ($page =~ m!^attributes.json$!) {
	$self->render( json => $models->get_attributes() );

    } elsif ($page =~ m!^attributes_full.json$!) {
	$self->render( json => $models->get_attributes_full() );

    } elsif ($page =~ m!^metrics.json$!) {
	$self->render( json => $models->get_metrics() );
    
    } elsif ($page =~ m!^metrics_full.json$!) {
	$self->render( json => $models->get_metrics_full() );
    
    } elsif ($page =~ m!^qm.json$!) {
	$self->render( json => $models->get_qm() );
    
    } elsif ($page =~ m!^qm_full.json$!) {
	$self->render( json => $models->get_qm_full() );

    } else {
	$self->render( json => {} );
    }
}

# Models display screen for Alambic admin.
sub models {
    my $self = shift;

    my $models = $self->app->al->get_models();
    
    # Get list of metrics definition files.
    my @files_metrics = <models/metrics/*.json>;
    my @files_attributes = <models/attributes/*.json>;
    my @files_qm = <models/qm/*.json>;

    $self->stash(
        files_metrics => \@files_metrics,
        files_attributes => \@files_attributes,
        files_qm => \@files_qm,
	models => $models,
        );
    
    $self->render( template => 'alambic/admin/models' );
}


# Models import for Alambic admin.
sub models_import {
    my $self = shift;
    my $file = $self->param( 'file' );
    my $type = $self->param( 'type' ) || "metrics";
    my $add = $self->param( 'add' ) || 1;
    
    my $repofs = Alambic::Model::RepoFS->new();
    my $repodb = $self->app->al->get_repo_db();
    
    if ($type =~ m!^metrics$!) {
	my $metrics = decode_json( $repofs->read_models('metrics', $file) );
	
	foreach my $metric ( @{$metrics->{'children'}} ) {
	    $repodb->set_metric( $metric->{'mnemo'}, 
				 $metric->{'name'}, 
				 encode_json($metric->{'desc'}), 
				 encode_json($metric->{'scale'}) );
	}
    } elsif ($type =~ m!^attributes$!) {
	my $attributes = decode_json( $repofs->read_models('attributes', $file) );
	
	foreach my $attribute ( @{$attributes->{'children'}} ) {
	    $repodb->set_attribute( $attribute->{'mnemo'}, 
				    $attribute->{'name'}, 
				    encode_json($attribute->{'desc'}) );
	}
    } elsif ($type =~ m!^qm$!) {
	my $qm = decode_json( $repofs->read_models('qm', $file) );
	print "# In Admin models_import " . Dumper($qm);
	
#	foreach my $node ( @{$qm->{'children'}} ) {
	$repodb->set_qm( "ALB_BASIC",
			 "Alambic Quality Model", 
			 encode_json($qm->{'children'}) );
#	}
    } else {
	print "DBG something went wrong.\n";
    }

    $self->app->al->get_models()->init_models(
	$repodb->get_metrics(), 
	$repodb->get_attributes(), 
	$repodb->get_qm(), 
	$self->app->al->get_plugins()->get_conf_all());
    
    my $msg = "File $file has been imported in the $type table.";
    $self->flash( msg => $msg );    
    $self->redirect_to( '/admin/models' );
}

# Models display screen for Alambic admin.
sub models_init {
    my $self = shift;
    
    my $repodb = $self->app->al->get_repo_db();
    $self->app->al->get_models()->init_models(
	$repodb->get_metrics(), 
	$repodb->get_attributes(), 
	$repodb->get_qm(), 
	$self->app->al->get_plugins()->get_conf_all());
    
    my $msg = "Models have been re-read.";
    $self->flash( msg => $msg );    
    $self->redirect_to( '/admin/models' );
}


# Projects screen for Alambic admin.
sub projects {
    my $self = shift;
    
    $self->render( template => 'alambic/admin/projects' );
}


# Display specific project screen for Alambic admin.
sub projects_show {
    my $self = shift;
    my $project_id = $self->param( 'pid' );

    # Get list of files in input and data directories.
    my @files_input = <projects/${project_id}/input/*.*>;
    my @files_output = <projects/${project_id}/output/*.*>;
    my %files_time;

    # TODO get the list of runs for this project.
    my $repodb = $self->app->al->get_repo_db();
#    $repodb->get_project_hist
    
    # Retrieve last modification time on input files.
    foreach my $file (@files_input, @files_output) { 
        $files_time{$file} = ctime( stat($file)->mtime );
    }

    # Prepare data for template.
    $self->stash(
        project_id => $project_id,
        files_input => \@files_input,
        files_output => \@files_output,
        files_time =>\%files_time,
        );
    
    $self->render( template => 'alambic/admin/project' );
}


# New project screen for Alambic admin.
sub projects_new {
    my $self = shift;

    $self->stash(
        project_id => '',
        project_name => '',
	project_active => '',
        );
    
    $self->render( template => 'alambic/admin/project_set' );
}


# New project screen for Alambic admin.
sub projects_new_post {
    my $self = shift;
    
    my $project_id = $self->param( 'id' );
    my $project_name = $self->param( 'name' );
    my $project_active = $self->param( 'is_active' );
    
    my $project = $self->app->al->create_project( $project_id, $project_name, '', $project_active );

    my $msg = "Project '$project_name' ($project_id) has been created.";
    
    $self->flash( msg => $msg );
    $self->redirect_to( '/admin/projects' );
}


# Run project screen for Alambic admin.
sub projects_run {
    my $self = shift;
    my $project_id = $self->param( 'pid' );

    # Start minion job
    my $job = $self->minion->enqueue( run_project => [ $project_id ] => { delay => 0 });
#    my $project = $self->app->al->run_project( $project_id );

    my $msg = "Project run for $project_id has been enqueued [$job].";
    
    $self->flash( msg => $msg );
    $self->redirect_to( '/admin/projects/' . $project_id );
}


# Delete project screen for Alambic admin.
sub projects_del {
    my $self = shift;
    my $project_id = $self->param( 'pid' );

    $self->app->al->delete_project($project_id);
    my $msg = "Project $project_id has been deleted.";
    
    $self->flash( msg => $msg );
    $self->redirect_to( '/admin/projects' );
}


# Edit project screen for Alambic admin.
sub projects_edit {
    my $self = shift;
    my $project_id = $self->param( 'pid' );

    # TODO
    
    # Render template for main admin section
    $self->render( template => 'alambic/admin/projects_edit' );
}


# Edit project screen for Alambic admin (POST).
sub projects_edit_post {
    my $self = shift;
    
    my $project_id = $self->param( 'id' );
    my $project_name = $self->param( 'name' );
    my $project_active = $self->param( 'is_active' );

    # TODO

    my $msg = "Project '$project_name' ($project_id) has been created.";
    
    $self->flash( msg => $msg );
    $self->redirect_to( '/admin/projects' );
}


# Add plugin to project screen for Alambic admin.
sub projects_add_plugin {
    my $self = shift;
    my $project_id = $self->param( 'pid' );
    my $plugin_id = $self->param( 'plid' );
    
    # Prepare data for template.
    my $conf = $self->app->al->get_plugins()->get_plugin($plugin_id)->get_conf();
    my $conf_project = $self->app->al->get_project($project_id)->get_plugins()->{$plugin_id};

    $self->stash(
        project => $project_id,
        conf => $conf,
	conf_project => $conf_project,
        );
    
    # Render template for main admin section
    $self->render( template => 'alambic/admin/project_plugin_add' );
}


# Add plugin to project screen for Alambic admin (POST).
sub projects_add_plugin_post {
    my $self = shift;
    my $project_id = $self->param( 'pid' );
    my $plugin_id = $self->param( 'plid' );
    
    my $conf = $self->app->al->get_plugins()->get_plugin($plugin_id)->get_conf();

    my %args;
    foreach my $param ( keys %{$conf->{'params'}} ) {
        $args{$param} = $self->param( $param );
    }

    $self->app->al->add_project_plugin($project_id, $plugin_id, \%args);

    my $msg = "Plugin $plugin_id has been added to project $project_id.";
    
    $self->flash( msg => $msg );
    $self->redirect_to( '/admin/projects/' . $project_id );
}


# Edit project screen for Alambic admin.
sub projects_run_plugin {
    my $self = shift;
    my $project_id = $self->param( 'pid' );
    my $plugin_id = $self->param( 'plid' );

    my $job = $self->minion->enqueue( run_plugin => [ $project_id, $plugin_id ] => { delay => 0 });
#    $self->app->al->get_project($project_id)->run_plugin($plugin_id);

    my $msg = "Plugin $plugin_id has been enqueued [$job] on project $project_id.";
    
    $self->flash( msg => $msg );
    $self->redirect_to( '/admin/projects/' . $project_id );
}


# Edit project screen for Alambic admin.
sub projects_del_plugin {
    my $self = shift;
    my $project_id = $self->param( 'pid' );
    my $plugin_id = $self->param( 'plid' );

    $self->app->al->del_project_plugin($project_id, $plugin_id);

    my $msg = "Plugin $plugin_id has been removed from project $project_id.";
    
    $self->flash( msg => $msg );
    $self->redirect_to( '/admin/projects/' . $project_id );
}


#
# Displays a list of plugins detected with information about them.
#
sub plugins {
    my $self = shift;

    # Render template 
    $self->render( template => 'alambic/admin/plugins' );   

}





1;
