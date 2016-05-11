package Alambic::Controller::Documentation;
use Mojo::Base 'Mojolicious::Controller';

use Mojo::JSON qw( decode_json );
use Data::Dumper;

# Renders all documentation pages.
sub welcome {
    my $self = shift;

    # 'id' is the specific documentation page from url.
    my $in_doc = $self->param( 'id' ) || '';

    my $repodb = $self->app->al->get_repo_db();

    if ($in_doc =~ m!^quality_model(.html)?$!) {

	# Render template for quality_model
	$self->render( template => 'alambic/documentation/quality_model' );

    } elsif ($in_doc =~ m!^plugins(.html)?$!) {

	# Render template for plugins
	$self->render( template => 'alambic/documentation/plugins' );

    } elsif ($in_doc =~ m!^data(.html)?$!) {

#        my %attributes = %{$self->models->get_attributes()};

        # TODO

	# Render template for attributes
#        $self->stash( attributes => \%attributes );
	$self->render( template => 'alambic/documentation/data' );

    } elsif ($in_doc =~ m!^attributes(.html)?$!) {

	my $models = $self->app->al->get_models();
	my $attributes = $models->get_attributes();

	# Render template for attributes
        $self->stash( attributes => $attributes );
	$self->render( template => 'alambic/documentation/attributes' );

    } elsif ($in_doc =~ m!^metrics(_(\w+))?(.html)?$!) {

        my $repo = $2 || "";

	my $models = $self->app->al->get_models();
	my $metrics = $models->get_metrics();
        my $repos = $models->get_metrics_repos();

	# Render template for metrics
        $self->stash( metrics => $metrics, repos => $repos, repo => $repo );
	$self->render( template => 'alambic/documentation/metrics' );

    } elsif ($in_doc =~ m!^scales(.html)?$!) {

	# Render template for scales
	$self->render( template => 'alambic/documentation/scales' );

    } elsif ($in_doc =~ m!^scales_grimoire(.html)?$!) {

	# Render template for grimoire scales
	$self->render( template => 'alambic/documentation/scales_grimoire' );

    } elsif ($in_doc =~ m!^scales_marketplace(.html)?$!) {

	# Render template for marketplace scales
	$self->render( template => 'alambic/documentation/scales_marketplace' );

    } elsif ($in_doc =~ m!^scales_pmi(.html)?$!) {

	# Render template for pmi scales
	$self->render( template => 'alambic/documentation/scales_pmi' );

    } elsif ($in_doc =~ m!^scales_rulechecking(.html)?$!) {

	# Render template for rulechecking scales
	$self->render( template => 'alambic/documentation/scales_rulechecking' );

    } elsif ($in_doc =~ m!^scales_rulechecking(.html)?$!) {

	# Render template for sonarqube scales
	$self->render( template => 'alambic/documentation/scales_sonarqube' );

    } elsif ($in_doc =~ m!^rules(_(.+?))?(.html)?$!) {

#        my %rules = %{$self->models->get_rules()};
#        my %sources = %{$self->models->get_rules_sources()};
#        my $source = $2 || "";

	# Render template for metrics
#        $self->stash( rules => \%rules, sources => \%sources, source => $source );
	$self->render( template => 'alambic/documentation/rules' );

    } elsif ($in_doc =~ m!^references(.html)?$!) {

	# Render template for references (bib)
	$self->render( template => 'alambic/documentation/references' );

    } else {

	$self->render( template => 'alambic/documentation/main' );        

    }
}

1;
