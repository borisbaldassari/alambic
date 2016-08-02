package Alambic::Controller::Repo;
use Mojo::Base 'Mojolicious::Controller';

use Alambic::Model::RepoFS;

use Data::Dumper;

# Main screen for Alambic repo admin.
sub summary {
    my $self = shift;

    # Get list of backup files.
    my @files_backup = <backups/*.*>;

    $self->stash(
        files_backup => \@files_backup,
        );
    $self->render( template => 'alambic/admin/repo' );
}


# Initalisation of DB for Alambic admin.
sub init {
    my $self = shift;

    $self->app->al->init();
    
    my $msg = "Database has been initialised.";
    
    $self->flash( msg => $msg );
    $self->redirect_to( '/admin/summary' );
}


# Backup DB for Alambic admin.
sub backup {
    my $self = shift;

    my $sql = $self->app->al->backup();
    my $repofs = Alambic::Model::RepoFS->new();
    my $file_sql = $repofs->write_backup($sql);
    
    my $msg = "Database has been backed up in [$file_sql].";
    
    $self->flash( msg => $msg );
    $self->redirect_to( '/admin/repo' );
}


# Download SQL backup file.
sub dl {
    my $self = shift;
    
    my $file_sql = $self->param( 'file' );

    # If the page is a fig, reply static file under 'backups/'
    $self->reply->static( '../backups/' . $file_sql );
}


# Restore DB for Alambic admin.
sub restore {
    my $self = shift;
    
    my $file_sql = $self->param( 'file' );

    my $repofs = Alambic::Model::RepoFS->new();
    my $sql = $repofs->read_backup($file_sql);

    if (length($sql) < 10) {
	$self->flash( msg => "Could not find SQL file. Database has NOT been restored." );
	$self->redirect_to( '/admin/summary' );
    }
    
    $self->app->al->restore($sql);
    
    my $msg = "Database has been restored from [$file_sql].";
    
    $self->flash( msg => $msg );
    $self->redirect_to( '/admin/repo' );
}


1;
