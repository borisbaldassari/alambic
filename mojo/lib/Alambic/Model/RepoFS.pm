package Alambic::Model::RepoFS;

use warnings;
use strict;

use File::Path qw( remove_tree );
use Mojo::JSON qw( decode_json encode_json );
use POSIX;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw( 
                     write_input
                     read_input
                     write_output
                     read_output
                     write_plugin
                     read_plugin
                     write_models
                     read_models
                     write_users
                     read_users
                     delete_project
                   );  

# Create a new RepoFS object.
sub new { 
    my ($class, $args) = @_;

    return bless {}, $class;
}


sub write_input($$$) {
    my ($self, $project_id, $file_name, $content) = @_;

    # Create projects input dir if it does not exist
    if (not -d 'projects/' . $project_id ) { 
        mkdir( 'projects/' . $project_id );
    }
    if (not -d 'projects/' . $project_id . '/input') { 
        mkdir( 'projects/' . $project_id . '/input');
    }

    my $file_content_out = "projects/" . $project_id . "/input/" . $project_id . "_" . $file_name;
    open my $fh, ">", $file_content_out;
    print $fh $content;
    close $fh;
}

sub read_input($$) {
    my ($self, $project_id, $file_name) = @_;

    my $content;
    my $file = "projects/" . $project_id . "/input/" . $project_id . "_" . $file_name;

    if (-e $file) {
	do { 
	    local $/;
	    open my $fh, '<', $file;
	    $content = <$fh>;
	    close $fh;
	};
    }
    
    return $content;
}


sub write_output($$$) {
    my ($self, $project_id, $file_name, $content) = @_;

    # Create projects output dir if it does not exist
    if (not -d 'projects/' . $project_id ) { 
        mkdir( 'projects/' . $project_id );
    }
    if (not -d 'projects/' . $project_id . '/output') { 
        mkdir( 'projects/' . $project_id . '/output');
    }

    my $file_content_out = "projects/" . $project_id . "/output/" . $project_id . "_" . $file_name;
    open my $fh, ">", $file_content_out;
    print $fh $content;
    close $fh;
}


sub read_output($$) {
    my ($self, $project_id, $file_name) = @_;

    my $content;
    my $file = "projects/" . $project_id . "/output/" . $project_id . "_" . $file_name;
    
    if (-e $file) {
	do { 
	    local $/;
	    open my $fh, '<', $file;
	    $content = <$fh>;
	    close $fh;
	};
    }

    return $content;
}


sub write_plugin($$$) {
    my ($self, $plugin_id, $file_name, $content) = @_;

    my $file_content_out = "lib/Alambic/Plugins/" . $plugin_id . "/" . $file_name;
    open my $fh, ">", $file_content_out;
    print $fh $content;
    close $fh;
}


sub read_plugin($$) {
    my ($self, $plugin_id, $file_name) = @_;

    my $content;

    my $file = "lib/Alambic/Plugins/" . $plugin_id . "/" . $file_name;
    if (-e $file) {
	do { 
	    local $/;
	    open my $fh, '<', $file;
	    $content = <$fh>;
	    close $fh;
	};
    } 
    
    return $content;
}


sub write_backup($$$) {
    my ($self, $content) = @_;

    # Create backups dir if it does not exist
    if (not -d 'backups/' ) { 
        mkdir( 'backups/' );
    }

    my $file_name = strftime("backups/alambic_backup_%Y%m%d%H%M.sql", localtime);
    open my $fh, ">", $file_name;
    print $fh $content;
    close $fh;

    return $file_name;
}

sub read_backup($$) {
    my ($self, $file_name) = @_;

    my $content;
    my $file = "backups/" . $file_name;
    
    if (-e $file) {
	do { 
	    local $/;
	    open my $fh, '<', $file or return 0;
	    $content = <$fh>;
	    close $fh;
	};
    }
    
    return $content;
}


sub write_models($$$) {
    my ($self, $type, $file_name, $content) = @_;

    # Create backups dir if it does not exist
    if (not -d 'models/' ) { 
        mkdir( 'models/' );
    }

    my $path = 'models/' . $type . '/' . $file_name;
    open my $fh, ">", $path;
    print $fh $content;
    close $fh;
}

sub write_users($$$) {
    my ($self, $plugin_id, $project_id, $content) = @_;

    # Create users dir if it does not exist
    my $dir_path = 'projects/' . $project_id . '/users/' ;
    if (not -d $dir_path ) { 
        mkdir( $dir_path );
    }

    my $path = $dir_path . $plugin_id . "_users.json";
    open my $fh, ">", $path;
    print $fh encode_json( $content );
    close $fh;
}

sub read_users($$$) {
    my ($self, $project_id) = @_;

    my @files_users = <projects/${project_id}/users/*_users.json>;
    my %users;
#    print "Reading users.\n";
    foreach my $file (@files_users) {
	if (-e $file && $file =~ m!.*/([^/]+)_users.json!) {
	    my $plugin_id = $1;
	    do { 
		local $/;
		open my $fh, '<', $file or return 0;
		my $json = <$fh>;
		close $fh;
		my $content = decode_json($json);
		foreach my $u (keys %$content) { 
		    $users{$u}{$plugin_id} = $content->{$u};
#		    print "Reading user [$u].\n";
		}
	    };
	}
    }
    
    return \%users;
}

sub read_models($$) {
    my ($self, $type, $file_name) = @_;

    my $content;
    my $file = "models/" . $type . "/" . $file_name;
    
    if (-e $file) {
	do { 
	    local $/;
	    open my $fh, '<', $file or return 0;
	    $content = <$fh>;
	    close $fh;
	};
    }
    
    return $content;
}


sub delete_project($) {
    my ($self, $project_id) = @_;

    remove_tree( "projects/${project_id}/" );
}


1;
