#########################################################
#
# Copyright (c) 2015-2017 Castalia Solutions and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
#
# Contributors:
#   Boris Baldassari - Castalia Solutions
#
#########################################################

package Alambic::Plugins::Scancode;

use strict;
use warnings;

use Text::CSV;

use Alambic::Tools::Scancode;
use Alambic::Model::RepoFS;

use Mojo::JSON qw( decode_json encode_json );

#use Mojo::JSON qw( decode_json encode_json );
use Data::Dumper;

# Main configuration hash for the plugin
my %conf = (
  "id"   => "Scancode",
  "name" => "Scancode plugin",
  "desc" => [
    "The generic Scancode plugin enables users to easily scan their codebase for license issues.",
    'See <a href="http://alambic.io/Plugins/Pre/Scancode">the project\'s wiki</a> for more information.',
  ],
  "type"           => "pre",
  "ability"        => ['metrics', 'data', 'figs', 'viz'],
  "params"         => {
    "dir_bin" =>
      'The full path to the binary, e.g. /opt/scancode/scancode.',
  },
  "provides_cdata" => [],
  "provides_info"  => [],
  "provides_data"  => {
    "scancode.json" => "The JSON output of the Scancode execution.",
    "scancode_files.csv" => "The CSV list of all files analysed by Scancode.",
    "scancode_special_files.csv" => "The CSV list of all special files. See documentation to know what a special file is.",
    "scancode_licences.csv" => "The CSV extract of all license expressions found in files.",
    "scancode_copyrights.csv" => "The CSV extract of all copyrights found in files.",
    "scancode_holders.csv" => "The CSV extract of all holders found in files.",
    "scancode_authors.csv" => "The CSV extract of all holders authors in files.",
    "scancode_programming_languages.csv" => "The CSV extract of all programming languages found in files.",
  },
  "provides_metrics" => {
    "SC_LICENSES_VOL"      => "SC_LICENSES_VOL",
    "SC_COPYRIGHTS_VOL"      => "SC_COPYRIGHTS_VOL",
    "SC_HOLDERS_VOL"      => "SC_HOLDERS_VOL",
    "SC_AUTHORS_VOL"      => "SC_AUTHORS_VOL",
    "SC_PROGS_VOL"      => "SC_PROGS_VOL",
    "SC_FILES_VOL"      => "SC_FILES_VOL",
    "SC_FILES_COUNT"      => "SC_FILES_COUNT",
    "SC_GENERATED_VOL"      => "SC_GENERATED_VOL",
    "SC_SPECIAL_FILES"      => "SC_SPECIAL_FILES",
  },
  "provides_figs"    => {
    'scancode_licences.html' => "Pie chart of licences detected in the codebase.",
    'scancode_copyrights.html' => "Pie chart of copyrights detected in the codebase.",
    'scancode_authors.html' => "Pie chart of authors detected in the codebase.",
    'scancode_holders.html' => "Pie chart of holders detected in the codebase.",
    'scancode_programming_languages.html' => "Pie chart of programming languages detected in the codebase.",
  },
  "provides_recs" => ["SC_WARNINGS",],
  "provides_viz"     => {
    'scancode.html' => "Scancode",
  },
);


# Constructor
sub new {
  my ($class) = @_;

  return bless {}, $class;
}

sub get_conf() {
  return \%conf;
}


# Run plugin: retrieves data + compute_data
sub run_plugin($$) {
  my ($self, $project_id, $conf) = @_;

  my @log;
  push(@log, "[Plugins::Scancode] Start Scancode plugin execution for project $project_id.");

  my $params = {};

  # Execute the analysis scripts.
  my $sc = Alambic::Tools::Scancode->new($project_id);
  push(@log, "[Plugins::Scancode] Executing Scancode tool execution.");
  @log = (
    @log,
    @{
      $sc->scancode_scan_json()
    }
  );

  # Create RepoFS object for writing and reading files on FS.
  my $repofs = Alambic::Model::RepoFS->new();
  my $json = $repofs->read_input($project_id, "scancode.json");

  my $data = decode_json($json);
  my @licences = @{$data->{'summary'}{'license_expressions'}};
  my @copyrights = @{$data->{'summary'}{'copyrights'}};
  my @holders = @{$data->{'summary'}{'holders'}};
  my @authors = @{$data->{'summary'}{'authors'}};
  my @programming_languages = @{$data->{'summary'}{'programming_language'}};
  my @files = @{$data->{'files'}};      

  # Write list of licences.
  my $csv = Text::CSV->new({binary => 1, eol => "\n"});
  my $csv_out = "licence,count\n";
  my @licences_csv
    = map {
      $csv->combine(( $_->{'value'} || 'unknown', $_->{'count'} ));
      $csv_out .= $csv->string();
    }
    @licences;
  $repofs->write_output($project_id, "scancode_licences.csv", $csv_out);

  # Write list of copyrights.
  $csv = Text::CSV->new({binary => 1, eol => "\n"});
  $csv_out = "copyright,count\n";
  my @copyrights_csv
    = map { 
      $csv->combine(( $_->{'value'} || 'unknown', $_->{'count'} ));
      $csv_out .= $csv->string();
    }
    @copyrights;
  $repofs->write_output($project_id, "scancode_copyrights.csv", $csv_out);

  # Write list of holders.
  $csv = Text::CSV->new({binary => 1, eol => "\n"});
  $csv_out = "holder,count\n";
  my @holders_csv    = map { 
      $csv->combine(( $_->{'value'} || 'unknown', $_->{'count'} ));
      $csv_out .= $csv->string();
    }
    @holders;
  $repofs->write_output($project_id, "scancode_holders.csv", $csv_out);

  # Write list of authors.
  $csv = Text::CSV->new({binary => 1, eol => "\n"});
  $csv_out = "author,count\n";
  my @authors_csv    = map { 
      $csv->combine(( $_->{'value'} || 'unknown', $_->{'count'} ));
      $csv_out .= $csv->string();
    }
    @authors;
  $repofs->write_output($project_id, "scancode_authors.csv", $csv_out);

  # Write list of programming languages.
  $csv = Text::CSV->new({binary => 1, eol => "\n"});
  $csv_out = "programming_language,count\n";
  my @pl_csv
    = map { 
      $csv->combine(( $_->{'value'} || 'unknown', $_->{'count'} ));
      $csv_out .= $csv->string();
    }
    @programming_languages;
  $repofs->write_output($project_id, "scancode_programming_languages.csv", $csv_out);

  # Write list of files.
  $csv = Text::CSV->new({binary => 1, eol => "\n"});
  my @files_csv;
  my @keyfiles;
  my $generated = 0;
  $csv_out = "path,size,date,programming_language,sha1,is_binary,is_text,is_archive,";
  $csv_out .= "is_source,is_script,is_legal,is_manifest,is_readme,is_top_level,";
  $csv_out .= "is_key_file,is_generated\n";
  foreach my $f (@files) {
    next unless ( $f->{'type'} eq 'file' );
    $csv->combine((
      $_->{'path'}, $_->{'size'}, $_->{'date'}, $_->{'programming_language'},
      $_->{'sha1'}, $_->{'is_binary'}, $_->{'is_text'}, $_->{'is_archive'}, 
      $_->{'is_source'}, $_->{'is_script'}, $_->{'is_legal'}, $_->{'is_manifest'}, 
      $_->{'is_readme'}, $_->{'is_top_level'}, $_->{'is_key_file'}, $_->{'is_generated'}
    ));
    $csv_out .= $csv->string();

    # Identify key, readmes, manifests, legal files.
    push( @keyfiles, { 'path' => $f->{'path'}, 'type' => 'key' } ) if ( $f->{'is_keyfile'} );
    push( @keyfiles, { 'path' => $f->{'path'}, 'type' => 'readme' } ) if ( $f->{'is_readme'} );
    push( @keyfiles, { 'path' => $f->{'path'}, 'type' => 'manifest' } ) if ( $f->{'is_manifest'} );
    push( @keyfiles, { 'path' => $f->{'path'}, 'type' => 'legal' } ) if ( $f->{'is_legal'} );
    $generated++ if ( $f->{'is_generated'} );
  }
  $repofs->write_output($project_id, "scancode_files.csv", $csv_out);

  my $metrics = {
      "SC_LICENSES_VOL" => scalar(@licences),
      "SC_COPYRIGHTS_VOL" => scalar(@copyrights),
      "SC_HOLDERS_VOL" => scalar(@holders),
      "SC_AUTHORS_VOL" => scalar(@authors),
      "SC_PROGS_VOL" => scalar(@programming_languages),
      "SC_FILES_VOL" => scalar(@files),
      "SC_SPECIAL_FILES" => scalar(@keyfiles),
      "SC_GENERATED_VOL" => $generated,
      "SC_FILES_COUNT" => $data->{'headers'}[0]{'extra_data'}{'files_count'} || -1,
    };

  # Write list of special files.
  $csv = Text::CSV->new({binary => 1, eol => "\n"});
  $csv_out = "path,type\n";
  my @metrics_csv    = map { 
      $csv->combine(( $_->{'path'}, $_->{'type'} ));
      $csv_out .= $csv->string();
    }
    @keyfiles;
  $repofs->write_output($project_id, "scancode_special_files.csv", $csv_out);

  # Write list of metrics.
  $csv = Text::CSV->new({binary => 1, eol => "\n"});
  $csv_out = "metric,value\n";
  @metrics_csv    = map { 
      $csv->combine(( $_, $metrics->{$_} || 'unknown' ));
      $csv_out .= $csv->string();
    }
    keys %{$metrics};
  $repofs->write_output($project_id, "scancode_metrics.csv", $csv_out);

  # Now execute the main R script.
  push(@log, "[Plugins::Scancode] Executing R main file.");
  my $r = Alambic::Tools::R->new();
  @log = (@log, @{$r->knit_rmarkdown_inc('Scancode', $project_id, 'scancode.Rmd')});

  # And execute the figures R scripts.
  push(@log, "[Plugins::Scancode] Executing R figures.");
  @log = (
    @log,
    @{$r->knit_rmarkdown_html('Scancode', $project_id, 'scancode_programming_languages.rmd')}
  );
  @log = (
    @log,
    @{$r->knit_rmarkdown_html('Scancode', $project_id, 'scancode_authors.rmd')}
  );
  @log = (
    @log,
    @{$r->knit_rmarkdown_html('Scancode', $project_id, 'scancode_licences.rmd')}
  );
  @log = (
    @log,
    @{$r->knit_rmarkdown_html('Scancode', $project_id, 'scancode_copyrights.rmd')}
  );
  @log = (
    @log,
    @{$r->knit_rmarkdown_html('Scancode', $project_id, 'scancode_holders.rmd')}
  );

  return {
    "metrics" => $metrics, 
    "recs" => [], "info" => {}, "log" => \@log,
  };
}


1;


=encoding utf8

=head1 NAME

B<Alambic::Plugins::Scancode> - A plugin to scan licences and copyrights 
in a codebase with Scancode.

=head1 DESCRIPTION

B<Alambic::Plugins::Scancode> A plugin to scan licences and copyrights 
in a codebase with Scancode.

Parameters: None

For the complete description of the plugin see the user documentation on the web site: L<https://alambic.io/Plugins/Pre/Scancode.html>.

=head1 SEE ALSO

L<https://alambic.io/Plugins/Pre/Scancode.html>,
L<https://github.com/nexB/scancode-toolkit>,

L<Mojolicious>, L<http://alambic.io>, L<https://bitbucket.org/BorisBaldassari/alambic>


=cut
