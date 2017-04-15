package Alambic::Commands::backup;
use Mojo::Base 'Mojolicious::Command';

use Alambic::Model::RepoDB;

has description => 'Command line backup for Alambic';
has usage       => "Usage: alambic backup\n";

sub run {
    my ($self, @args) = @_;

    say "Starting database backup.";

    my $sql      = $self->app->al->backup();
    my $repofs   = Alambic::Model::RepoFS->new();
    my $file_sql = $repofs->write_backup($sql);

    say "Database has been backed up in [$file_sql].";
      
}


1;
