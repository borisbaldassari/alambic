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

package Alambic::Plugins::GenericR;

use strict;
use warnings;

use Text::CSV;

use Alambic::Tools::R;

#use Mojo::JSON qw( decode_json encode_json );
use Data::Dumper;

# Main configuration hash for the plugin
my %conf = (
  "id"   => "GenericR",
  "name" => "Generic R plugin",
  "desc" => [
      "The generic R plugin enables users to easily define their own R markdown files to automatically run analysis on projects.",
      'See <a href="http://alambic.io/Plugins/Pre/GenericR">the project\'s wiki</a> for more information.',
  ],
  "type"             => "post",
  "ability"          => ['figs', 'viz'],
  "params"           => {},
  "provides_cdata"   => [],
  "provides_info"    => [],
  "provides_data"    => {
      "generic_r.pdf" => "The PDF document generated from the R markdown file.",
    },
  "provides_metrics" => {},
  "provides_figs"    => {},
  "provides_recs" => [],
  "provides_viz"  => {"generic_r.html" => "Generic R",},
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
sub run_post($$) {
  my ($self, $project_id, $conf) = @_;

  my @log;
  push(@log, "[Plugins::GenericR] Start Generic R plugin execution.");
  
  my $repofs  = Alambic::Model::RepoFS->new();
  my $models  = $conf->{'models'};
  my $project = $conf->{'project'};
  my $qm      = $project->get_qm(
      $models->get_qm(),
      $models->get_attributes(),
      $models->get_metrics(),
  );
  my $run = $conf->{'last_run'};

  my $params = {};

  # Create a CSV file with all metrics + values
  my $metrics = $project->metrics();
  my $csv = Text::CSV->new({binary => 1, eol => "\n"});
  $csv->combine( ('Mnemo', 'Value') );
  my $csv_out = $csv->string();
  foreach my $metric (sort keys %$metrics) {
      $csv->combine( ($metric, $metrics->{$metric}) );
      $csv_out .= $csv->string();
  }
  
  # Write csv file to disk.
  $repofs->write_plugin('GenericR', $project_id . "_metrics.csv", $csv_out);

  my $attributes = $project->attributes();
  $csv = Text::CSV->new({binary => 1, eol => "\n"});
  $csv->combine( ('Mnemo', 'Value') );
  $csv_out = $csv->string();
  foreach my $attribute (sort keys %$attributes) {
      $csv->combine( ($attribute, $attributes->{$attribute}) );
      $csv_out .= $csv->string();
  }
  
  # Write csv file to disk.
  $repofs->write_plugin('GenericR', $project_id . "_attributes.csv", $csv_out);
  
  # Execute the figures R scripts.
  my $r = Alambic::Tools::R->new();
  push(@log, "[Plugins::GenericR] Executing R pdf markdown document.");
  @log = (
    @log,
    @{
      $r->knit_rmarkdown_pdf('GenericR', $project_id, 'generic_r.Rmd',
        $params)
    }
  );

  return {"metrics" => {}, "recs" => [], "info" => {}, "log" => \@log,};
}


1;


=encoding utf8

=head1 NAME

B<Alambic::Plugins::GenericR> - A plugin to display badges 
and exportable snippets about the project's analysis.

=head1 DESCRIPTION

B<Alambic::Plugins::GenericR> provides exportable html snippets 
and images about the project's analysis results.

Parameters: None

For the complete description of the plugin see the user documentation on the web site: L<https://alambic.io/Plugins/Pre/GenericR.html>.

=head1 SEE ALSO

L<https://alambic.io/Plugins/Pre/GenericR.html>,

L<Mojolicious>, L<http://alambic.io>, L<https://bitbucket.org/BorisBaldassari/alambic>


=cut
