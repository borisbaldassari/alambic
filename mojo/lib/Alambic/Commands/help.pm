package Alambic::Commands::help;
use Mojo::Base 'Mojolicious::Command';

use Alambic::Model::RepoDB;

has description => 'Command line help for Alambic';
has usage       => "Usage: alambic help\n";

sub run {
    my ($self, @args) = @_;
    
    my $usage = "
Welcome to the Alambic application. 

Usage: alambic <command>

Alambic commands: 
* bin/alambic init       Initialise the database.
* bin/alambic backup     Backup the database.

Other Mojolicious commands: 
* bin/alambic minion     Manage job queuing system.
* bin/alambic daemon     Run application in development mode.
* bin/alambic prefork    Run application in production (multithreaded) mode.

";
    print $usage;
    
  }
}


1;
