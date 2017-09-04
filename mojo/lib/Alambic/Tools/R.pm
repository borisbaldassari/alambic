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

package Alambic::Tools::R;

use strict;
use warnings;

use Alambic::Model::RepoFS;
use File::chdir;
use File::Copy;

use Data::Dumper;

# Main configuration hash for the plugin
my %conf = (
  "id"      => "r_sessions",
  "name"    => "R sessions",
  "desc"    => "Runs R for plugins, computes data and generates files.",
  "ability" => ["methods"],
  "type"    => "tool",
  "params"  => {"path_r" => "The absolute path to the R binary.",},
  "provides_methods" => {
    "knit_rmarkdown_inc"    => "Knit a r markdown document into a inc file.",
    "knit_rmarkdown_pdf"    => "Knit a r markdown document into a pdf file",
    "knit_rmarkdown_html"   => "Knit a r markdown document into a html file",
    "knit_rmarkdown_images" => "Knit a r markdown document into a svg file",
  },
);


# Constructor
sub new {
  my ($class) = @_;

  return bless {}, $class;
}


# Get configuration for this Git plugin instance.
sub get_conf() {
  return \%conf;
}


# Automated setup procedure for the tool.
sub install() {
}

# Return R version as a string.
sub version() {

  my $r_cmd = "R --version";
  my @out   = `$r_cmd 2>&1`;
  chomp @out;

  for my $l (@out) {
    if ($l =~ m/^(R version .*)$/) {
      return $1;
    }
    else {
      return "R version not found.";
    }
  }
  return "R version not found.";

}

# Self-test method for the tool.
sub test() {

  my @log;

  my $path_r;
  for my $path (split /:/, $ENV{PATH}) {
    if (-f "$path/R" && -x _ ) { $path_r = "$path/R"; last; }
  }

  if (defined($path_r)) {
    push(@log, "OK: R exec found in PATH at [$path_r].");
  }
  else {
    push(@log, "ERROR: R exec NOT found in PATH.");
  }

  my $path_rscript;
  for my $path (split /:/, $ENV{PATH}) {
    if (-f "$path/Rscript" && -x _ ) { $path_rscript = "$path/Rscript"; last; }
  }

  if (defined($path_rscript)) {
    push(@log, "OK: Rscript exec found in PATH at [$path_rscript].");
  }
  else {
    push(@log, "ERROR: Rscript exec NOT found in PATH.");
  }

  return \@log;
}


# Function to knit a rmarkdown document to a html snippet.
# It goes into the plugin's directory,
# creates required directories (e.g. figures/) and executes Rscript.
#
# The plugin assumes that the input files needed are already present in the directory.
#
# Params:
#   - $plugin_id: the name/id of the calling plugin, e.g. EclipseIts.
#   - $project_id: the id of the project analysed.
#   - $r_in: the short name of the file to execute (e.g. EclipseIts.rmd)
#   - \@r_out: the short name of the file to produce (e.g. EclipseIts.png)
#   - %params: a ref to hash of parameters/values for the execution.
sub knit_rmarkdown_inc($$$$) {
  my ($self, $plugin_id, $project_id, $r_in, $r_out, $params) = @_;

  my @log;
  $params = $params || {};

  # Set vars.
  my $r_dir    = "lib/Alambic/Plugins/$plugin_id/";
  my $r_md_out = $r_in;
  $r_md_out =~ s/(.*)\..*+/$1/;
  $r_md_out = "${project_id}_${r_md_out}.inc";

  # Change the current working directory localy only.
  {
    local $CWD = $r_dir;

    # Create dir for figures.
    if (!-d "figures/") {
      push(@log, "[Tools::R] Creating directory [figures/].");
      mkdir "figures/";
    }

    # Now execute the main R script.
    my $r_cmd = "Rscript -e \"library(rmarkdown); ";
    $r_cmd .= "project.id <- '${project_id}'; plugin.id <- '$plugin_id'; ";
    foreach my $key (keys %{$params}) {
      $r_cmd .= $key . " <- '" . ($params->{$key}  || '') . "'; ";
#      $r_cmd .= $key . " <- '" . $params->{$key} . "'; ";
    }
    $r_cmd
      .= "rmarkdown::render('${r_in}', output_format='html_fragment', output_file='$r_md_out')\"";

    push(@log, "[Tools::R] Exec [$r_cmd].");
    my @out = `$r_cmd 2>&1`;
  }

  # Move the generated main file to project output dir
  my $file_in     = $r_dir . "/" . $r_md_out;
  my $dir_in_fig  = $r_dir . '/figures/';
  my $dir_out     = "projects/" . $project_id . "/output/";
  my $dir_out_fig = $dir_out . '/figures/';
  my $ret         = move($file_in, $dir_out);
  push(@log,
    "[Tools::R] Moved main file from [${file_in}] to [$dir_out]. ret [$ret].");

  # Create dir for figures.
  if (!-d "${dir_out_fig}") {
    push(@log, "Creating directory [${dir_out_fig}].");
    mkdir "${dir_out_fig}";
  }

  # Move the generated picture files to project output dir
  my $files = $dir_in_fig . "*";
  my @files = glob qq(${files});
  foreach my $file (@files) {
    $ret = move($file, $dir_out_fig);
  }

  # If defined, also move the generated images.
  if (defined($r_out) and ref($r_out) eq 'ARRAY') {
    foreach my $file (@$r_out) {
      $file_in = $r_dir . "/" . $project_id . "_" . $file;
      $ret = move($file_in, $dir_out);
      push(@log,
        "[Tools::R] Moved image file from [${file_in}] to [$dir_out]. ret [$ret]."
      );
    }
  }

  return \@log;
}


# Function to knit a rmarkdown document to a pdf document.
# It goes into the plugin's directory,
# creates required directories (e.g. figures/) and executes Rscript.
#
# The plugin assumes that the input files needed are already present in the directory.
#
# Params:
#   - $plugin_id: the name/id of the calling plugin, e.g. EclipseIts.
#   - $project_id: the id of the project analysed.
#   - $r_file: the short name of the file to execute (e.g. EclipseIts.Rmd)
#   - %params: a ref to hash of parameters/values for the execution.
sub knit_rmarkdown_pdf($$$$) {
  my ($self, $plugin_id, $project_id, $r_file, $params) = @_;

  my @log;
  $params = $params || {};

  # Set vars.
  my $r_dir = "lib/Alambic/Plugins/$plugin_id/";
  my $r_md  = $r_file;
  $r_file =~ s/(.*)\..*+/$1/;
  my $r_md_out = "${project_id}_${r_file}.pdf";

  # Change the current working directory localy only.
  {
    local $CWD = $r_dir;

    # Create dir for figures.
    if (!-d "figures/") {
      push(@log, "[Tools::R] Creating directory [figures/].");
      mkdir "figures/";
    }

    # Now execute the main R script.
    my $r_cmd = "Rscript -e \"library(rmarkdown); ";
    $r_cmd .= "project.id <- '${project_id}'; plugin.id <- '$plugin_id'; ";
    foreach my $key (keys %{$params}) {
      $r_cmd .= $key . " <- '" . ($params->{$key}  || '') . "'; ";
#      $r_cmd .= $key . " <- '" . $params->{$key} . "'; ";
    }
    $r_cmd .= "rmarkdown::render('${r_md}', output_file='$r_md_out')\"";

    push(@log, "[Tools::R] Exec [$r_cmd].");
    my @out = `$r_cmd 2>&1`;
  }

  # Move the generated main file to project output dir
  my $file_in     = $r_dir . "/" . $r_md_out;
  my $dir_in_fig  = $r_dir . '/figures/';
  my $dir_out     = "projects/" . $project_id . "/output/";
  my $file_out    = $dir_out . $r_md_out;
  my $dir_out_fig = $dir_out . '/figures/';
  move($file_in, $file_out);
  push(@log, "[Tools::R] Moved file from ${file_in} to $dir_out.");

  # Create dir for figures.
  if (!-d "${dir_out_fig}") {
    push(@log, "Creating directory [${dir_out_fig}].");
    mkdir "${dir_out_fig}";
  }

  # Move the generated picture files to project output dir
  my $files = $dir_in_fig . "*";
  my @files = glob qq(${files});
  foreach my $file (@files) {
    my $ret = move($file, $dir_out_fig);
    push(@log, "[Tools::R] Moved file from ${file} to $dir_out_fig.");
  }

  return \@log;
}


# Function to knit a rmarkdown document to a full html document.
# It goes into the plugin's directory,
# creates required directories (e.g. figures/) and executes Rscript.
#
# The plugin assumes that the input files needed are already present in the directory.
#
# Params:
#   - $plugin_id: the name/id of the calling plugin, e.g. EclipseIts.
#   - $project_id: the id of the project analysed.
#   - $r_in: the short name of the file to execute (e.g. EclipseIts.rmd)
#   - \@r_out: the short name of the file to produce (e.g. EclipseIts.png)
#   - %params: a ref to hash of parameters/values for the execution.
sub knit_rmarkdown_html($$$$) {
  my ($self, $plugin_id, $project_id, $r_in, $r_out, $params) = @_;

  my @log;
  $params = $params || {};

  # Set vars.
  my $r_dir    = "lib/Alambic/Plugins/$plugin_id/";
  my $r_md_out = $r_in;
  $r_md_out =~ s/(.*)\..*+/$1/;
  $r_md_out = "${project_id}_${r_md_out}.html";

  # Change the current working directory localy only.
  {
    local $CWD = $r_dir;

    # Create dir for figures.
    if (!-d "figures/") {
      push(@log, "[Tools::R] Creating directory [figures/].");
      mkdir "figures/";
    }

    # Now execute the main R script.
    my $r_cmd = "Rscript -e \"library(rmarkdown); ";
    $r_cmd .= "project.id <- '${project_id}'; plugin.id <- '$plugin_id'; ";
    foreach my $key (keys %{$params}) {
      $r_cmd .= $key . " <- '" . ($params->{$key}  || '') . "'; ";
    }
    $r_cmd
      .= "rmarkdown::render('${r_in}', output_format='html_document', output_file='$r_md_out')\"";

    push(@log, "[Tools::R] Exec [$r_cmd].");
    my @out = `$r_cmd 2>&1`;
  }

  # Move the generated main file to project output dir
  my $file_in     = $r_dir . "/" . $r_md_out;
  my $dir_in_fig  = $r_dir . '/figures/';
  my $dir_out     = "projects/" . $project_id . "/output/";
  my $dir_out_fig = $dir_out . '/figures/';
  move($file_in, $dir_out);

  # Create dir for figures.
  if (!-d "${dir_out_fig}") {
    push(@log, "Creating directory [${dir_out_fig}].");
    mkdir "${dir_out_fig}";
  }

  # Move the generated picture files to project output dir
  my $files = $dir_in_fig . "*";
  my @files = glob qq(${files});
  foreach my $file (@files) {
    my $ret = move($file, $dir_out_fig);
  }

  # If defined, also move the generated images.
  if (defined($r_out) and ref($r_out) eq 'ARRAY') {
    foreach my $file (@$r_out) {
      $file_in = $r_dir . "/" . $project_id . "_" . $file;
      my $ret = move($file_in, $dir_out);
      push(@log,
        "[Tools::R] Moved image file from [${file_in}] to [$dir_out]. ret [$ret]."
      );
    }
  }

  return \@log;
}


# Function to knit a rmarkdown document to image(s).
# It goes into the plugin's directory,
# creates required directories (e.g. figures/) and executes Rscript.
#
# The plugin assumes that the input files needed are already present in the directory.
#
# Params:
#   - $plugin_id: the name/id of the calling plugin, e.g. EclipseIts.
#   - $project_id: the id of the project analysed.
#   - $r_in: the short name of the file to execute (e.g. EclipseIts.rmd)
#   - \@r_out: the short name of the file to produce (e.g. EclipseIts.png)
#   - \%params: a ref to hash of parameters/values for the execution.
sub knit_rmarkdown_images($$$$$) {
  my ($self, $plugin_id, $project_id, $r_in, $r_out, $params) = @_;

  my @log;
  $params = $params || {};

  # Set vars.
  my $r_dir = "lib/Alambic/Plugins/$plugin_id/";

  # Change the current working directory localy only.
  {
    local $CWD = $r_dir;

    # Now execute the main R script.
    my $r_cmd = "Rscript '$r_in' ";

    # Passing arguments: 2 first args are project.id and plugin.id
    $r_cmd .= $project_id . " " . $plugin_id;
    foreach my $key (sort keys %{$params}) {
      $r_cmd .= $key . " <- '" . ($params->{$key}  || '') . "'; ";
#      $r_cmd .= " " . $params->{$key};
    }

    push(@log, "[Tools::R] Exec [$r_cmd].");
    my @out = `$r_cmd 2>&1`;
  }

  # Move the generated files to project output dir
  my $dir_out = "projects/" . $project_id . "/output/";
  foreach my $file (@$r_out) {
    my $file_in = $r_dir . "/" . $project_id . "_" . $file;
    my $ret = move($file_in, $dir_out);
    push(@log,
      "[Tools::R] Moved image file from [${file_in}] to [$dir_out]. ret [$ret]."
    );
  }

  return \@log;
}


1;


=encoding utf8

=head1 NAME

B<Alambic::Tools::R> - A plugin to interact with the R engine.

=head1 DESCRIPTION

B<Alambic::Tools::R> provides an interface to the L<R statistical engine|https://r-project.org>.
It specifically provides methods to compute R script files and knit L<R markdown 
documents|http://rmarkdown.rstudio.com/>.

For the complete configuration see the user documentation on the web site: L<https://alambic.io/Plugins/Tools/R.html>.

=head2 C<new()>

    my $tool = Alambic::Tools::R->new();
    $tool->test();

Build a new R tool object.

=head2 C<get_conf()>

    my $conf = $r->get_conf();

Get configuration for this Git plugin instance.

=head2 C<version()>

    my $version = $r->version();

Return R version as a string.

=head2 C<test()>

    my $results = 

Self-test method for the tool.

    [
      'OK: R exec found in PATH at [/home/boris/applis/R-3.3.2/bin/R].',
      'OK: Rscript exec found in PATH at [/home/boris/applis/R-3.3.2/bin/Rscript].'
    ]

=head2 C<knit_rmarkdown_inc()>

    my $log = $tool->knit_rmarkdown_inc('Hudson', 'test.project', 
      'hudson.Rmd', [], \%params);

Function to knit a rmarkdown document to a html snippet. 

It goes into the plugin's directory, creates required directories 
(e.g. figures/) and executes Rscript. The plugin assumes that the input 
files needed are already present in the directory. Returns the log of the 
transformation.

    [
      '[Tools::R] Exec [Rscript -e "library(rmarkdown); project.id <- 
        \'test.project\'; plugin.id <- \'Hudson\'; rmarkdown::render(\'
        hudson.Rmd\', output_format=\'html_fragment\', output_file=
        \'test.project_hudson.inc\')"].',
      '[Tools::R] Moved main file from [lib/Alambic/Plugins/Hudson/
        test.project_hudson.inc] to [projects/test.project/output/]. ret [1].'
    ]

=head2 C<knit_rmarkdown_pdf()>

    my $log = $tool->knit_rmarkdown_pdf('Hudson', 'test.project', 
      'hudson.Rmd', \%params);

Function to knit a rmarkdown document to a pdf document.

It goes into the plugin's directory, creates required directories (e.g. 
figures/) and executes Rscript. The plugin assumes that the input files 
needed are already present in the directory. Returns the log of the 
transformation.

=head2 C<knit_rmarkdown_html()>

    $log = $tool->knit_rmarkdown_html('Hudson', 'test.project',
      'hudson_hist.rmd', [], \%params);

Function to knit a rmarkdown document to a full html document.

It goes into the plugin's directory, creates required directories 
(e.g. figures/) and executes Rscript. The plugin assumes that the input 
files needed are already present in the directory. Returns the log of the 
transformation.

=head2 C<knit_rmarkdown_images()>

    $log = $tool->knit_rmarkdown_images('PmdAnalysis', 'test.project',
      'pmd_analysis_files_ncc1.r', ["pmd_analysis_files_ncc1.svg"]);

Function to knit a rmarkdown document to image(s).

It goes into the plugin's directory, creates required directories (e.g. figures/) 
and executes Rscript. The plugin assumes that the input files needed are 
already present in the directory.  Returns the log of the transformation.

=head1 SEE ALSO

L<https://alambic.io/Plugins/Tools/R.html>, L<https://www.r-project.org>, 

L<Mojolicious>, L<http://alambic.io>, L<https://bitbucket.org/BorisBaldassari/alambic>


=cut


