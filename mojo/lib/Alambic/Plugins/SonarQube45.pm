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
#   Thales 
#   Boris Baldassari - Castalia Solutions
#
#########################################################

package Alambic::Plugins::SonarQube45;
use base 'Mojolicious::Plugin';

use strict;
use warnings;

use Alambic::Model::RepoFS;
use Alambic::Tools::R;

use Mojo::JSON qw( decode_json encode_json );
use Mojo::UserAgent;
use Data::Dumper;


# Main configuration hash for the plugin
my %conf = (
  "id"   => "SonarQube45",
  "name" => "SonarQube 4.5.x",
  "desc" => [
    "Retrieves information from a SonarQube 4.5.x instance (i.e. metrics and violations), and visualises them.",
    "Check the documentation for this plugin on the project wiki: <a href=\"http://alambic.io/Plugins/Pre/SonarQube45.html\">http://alambic.io/Plugins/Pre/SonarQube45.html</a>."
  ],
  "type"    => "pre",
  "ability" => ['metrics', 'info', 'data', 'viz', 'figs'],
  "params"  => {
    "sonar_url" =>
      "The base URL for the SonarQube instance (e.g. http://localhost:9000).",
    "sonar_project" => "The Project ID in the SonarQube instance.",
  },
  "provides_info" => ["SQ_URL",],

  # Adding a metric to this list automatically adds it to the list
  # of retrieved data from sonar.
  "provides_metrics" => {
    "ncloc"                         => "SQ_NCLOC",
    "files"                         => "SQ_FILES",
    "functions"                     => "SQ_FUNCS",
    "statements"                    => "SQ_STATEMENTS",
    "comment_lines"                 => "SQ_COMMENT_LINES",
    "comment_lines_density"         => "SQ_COMR",
    "complexity"                    => "SQ_CPX",
    "file_complexity"               => "SQ_CPX_FILE_IDX",
    "class_complexity"              => "SQ_CPX_CLASS_IDX", #TODO
    "function_complexity"           => "SQ_CPX_FUNC_IDX",  # TODO
    "coverage"                      => "SQ_COVERAGE",
    "public_api"                    => "SQ_PUBLIC_API",
    "public_documented_api_density" => "SQ_PUBLIC_API_DOC_DENSITY",
    "public_undocumented_api"       => "SQ_PUBLIC_UNDOC_API",
    "files_cycles"                  => "SQ_FILES_CYCLES",
    "package_cycles"                => "SQ_PACKAGES_CYCLES",
    "package_tangle_index"          => "SQ_PACKAGES_TANGLE_IDX",
    "commented_out_code_lines"      => "SQ_COM_CODE",
    "tests"                         => "SQ_TESTS",
    "test_success_density"          => "SQ_TEST_SUCCESSFUL_DENSITY",
    "line_coverage"                 => "SQ_COVERAGE_LINE",
    "branch_coverage"               => "SQ_COVERAGE_BRANCH",
    "duplicated_lines"              => "SQ_DUPLICATED_LINES",
    "duplicated_blocks"             => "SQ_DUPLICATED_BLOCKS",
    "duplicated_files"              => "SQ_DUPLICATED_FILES",
    "duplicated_lines_density"      => "SQ_DUPLICATED_LINES_DENSITY",
    "violations"                    => "SQ_VIOLATIONS",
    "blocker_violations"            => "SQ_VIOLATIONS_BLOCKER",
    "critical_violations"           => "SQ_VIOLATIONS_CRITICAL",
    "major_violations"              => "SQ_VIOLATIONS_MAJOR",
    "minor_violations"              => "SQ_VIOLATIONS_MINOR",
    "info_violations"               => "SQ_VIOLATIONS_INFO",
    "new_violations"                => "SQ_VIOLATIONS_NEW",
    "new_blocker_violations"        => "SQ_VIOLATIONS_BLOCKER_NEW",
    "new_critical_violations"       => "SQ_VIOLATIONS_CRITICAL_NEW",
    "new_major_violations"          => "SQ_VIOLATIONS_MAJOR_NEW",
    "new_minor_violations"          => "SQ_VIOLATIONS_MINOR_NEW",
    "new_info_violations"           => "SQ_VIOLATIONS_INFO_NEW",
    "open_issues"                   => "SQ_ISSUES_OPEN",
    "unreviewed_issues"             => "SQ_ISSUES_UNREVIEWED",

    #	"instability" => "SQ_INSTABILITY",
    "sqale_rating"                => "SQ_SQALE_RATING",
    "sqale_debt_ratio"            => "SQ_SQALE_DEBT_RATIO",
    "sqale_index"                 => "SQ_SQALE_INDEX",
    "ncloc_language_distribution" => "SQ_NCLOC_LANG",
    "rules"                       => "SQ_RULES",
  },
  "provides_data" => {
    "import_sq_issues_blocker.json" =>
      "The original list of blocker issues as sent out by SonarQube (JSON).",
    "import_sq_issues_critical.json" =>
      "The original list of critical issues as sent out by SonarQube (JSON).",
    "import_sq_issues_major.json" =>
      "The original list of major issues as sent out by SonarQube (JSON).",
    "sq_issues_blocker.csv" =>
      "A list of all blocker issues for the project (CSV).",
    "sq_issues_critical.csv" =>
      "A list of all critical issues for the project (CSV).",
    "sq_issues_major.csv" =>
      "A list of all major issues for the project (CSV).",
    "sq_metrics.csv" => "A list of all metrics with their values (CSV).",
  },
  "provides_figs" => {

      'sonarqube_violations_bar.svg' => "Repartition of violations severity (SVG)",
      'sonarqube_violations_pie.html' =>
	  "Pie chart of repartition of violations severity (HTML)",
      'sonarqube_summary.html'    => "Summary of main SonarQube metrics (HTML)",
      'sonarqube_violations.html' => "Summary of SonarQube violations (HTML)",
	  
#      'sonarqube_coverage.html' => "Bar plot of the different coverage metrics of SonarQube",
  },
  "provides_recs" => [

#	"SQ_XXX",
  ],
  "provides_viz" => {"sonarqube45.html" => "SonarQube",},
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

  my %ret = ('metrics' => {}, 'info' => {}, 'recs' => [], 'log' => [],);

  my $sonar_url     = $conf->{'sonar_url'};
  my $sonar_project = $conf->{'sonar_project'};
  $ret{'info'}{'SQ_URL'} = $sonar_url . "/dashboard/index?id=" . $sonar_project;

  # Create RepoFS object for writing and reading files on FS.
  my $repofs = Alambic::Model::RepoFS->new();

  # Prepare UserAgent.
  my $ua = Mojo::UserAgent->new;

  # Check auth
  my $url_auth = $sonar_url . "/api/authentication/validate?format=json";
  my $content  = $ua->get($url_auth)->res->json;
  if ($content->{'valid'}) {
    push(
      @{$ret{'log'}},
      "[Plugins::SonarQube45] Authentication successful on server."
    );
  }
  else {
    push(
      @{$ret{'log'}},
      "[Plugins::SonarQube45] Authentification failed on server."
    );
  }

  # Fetch blocker issues
  my $url_issues
    = $sonar_url
    . "/api/issues/search?projectKeys="
    . $sonar_project
    . "&pageSize=-1&severities=BLOCKER";
  push(
    @{$ret{'log'}},
    "[Plugins::SonarQube45] Get issues from [${url_issues}]."
  );
  $content = $ua->get($url_issues)->res->json;
  $repofs->write_input($project_id, "import_sq_issues_blocker.json",
    encode_json($content));
  my (%rules, %files, %issues_blocker, %issues_critical, %issues_major);
  foreach my $i (@{$content->{'issues'}}) {
    $issues_blocker{$i->{'key'}}{'msg'}         = $i->{'message'};
    $issues_blocker{$i->{'key'}}{'rule'}        = $i->{'rule'};
    $issues_blocker{$i->{'key'}}{'sev'}         = $i->{'severity'};
    $issues_blocker{$i->{'key'}}{'last_update'} = $i->{'updateDate'};
    $rules{$i->{'rule'}}{'vol'}++;
    $rules{$i->{'rule'}}{'sev'}                      = $i->{'severity'};
    $files{$i->{'component'}}{$i->{'key'}}{'msg'}    = $i->{'message'};
    $files{$i->{'component'}}{$i->{'key'}}{'line'}   = $i->{'message'};
    $files{$i->{'component'}}{$i->{'key'}}{'rule'}   = $i->{'rule'};
    $files{$i->{'component'}}{$i->{'key'}}{'status'} = $i->{'status'};
    $files{$i->{'component'}}{$i->{'key'}}{'sev'}    = $i->{'severity'};
  }
  push(
    @{$ret{'log'}},
    "[Plugins::SonarQube45] Got ["
      . scalar(keys %issues_blocker)
      . "] blocker issues."
  );
  push(
    @{$ret{'log'}},
    "[Plugins::SonarQube45] Got ["
      . scalar @{($content->{'rules'} || [])}
      . "] rules."
  );

  # Print issues to file system.
  my $csv_out = "key,rule,sev,last_update,message\n";
  foreach my $i (sort keys %issues_blocker) {
    my $msg = $issues_blocker{$i}{'msg'};
    $msg =~ tr/,;"'/ /;
    $csv_out
      .= $i . ","
      . $issues_blocker{$i}{'rule'} . ","
      . $issues_blocker{$i}{'sev'} . ","
      . $issues_blocker{$i}{'last_update'} . ","
      . $msg . "\n";
  }
  $repofs->write_output($project_id, "sq_issues_blocker.csv", $csv_out);
  $repofs->write_plugin('SonarQube45', $project_id . "_sq_issues_blocker.csv",
    $csv_out);


  # Fetch critical issues
  $url_issues
    = $sonar_url
    . "/api/issues/search?projectKeys="
    . $sonar_project
    . "&pageSize=-1&severities=CRITICAL";
  push(
    @{$ret{'log'}},
    "[Plugins::SonarQube45] Get issues from [${url_issues}]."
  );
  $content = $ua->get($url_issues)->res->json;
  $repofs->write_input($project_id, "import_sq_issues_critical.json",
    encode_json($content));
  foreach my $i (@{$content->{'issues'}}) {
    $issues_critical{$i->{'key'}}{'msg'}         = $i->{'message'};
    $issues_critical{$i->{'key'}}{'rule'}        = $i->{'rule'};
    $issues_critical{$i->{'key'}}{'sev'}         = $i->{'severity'};
    $issues_critical{$i->{'key'}}{'last_update'} = $i->{'updateDate'};
    $rules{$i->{'rule'}}{'vol'}++;
    $rules{$i->{'rule'}}{'sev'}                      = $i->{'severity'};
    $files{$i->{'component'}}{$i->{'key'}}{'msg'}    = $i->{'message'};
    $files{$i->{'component'}}{$i->{'key'}}{'line'}   = $i->{'message'};
    $files{$i->{'component'}}{$i->{'key'}}{'rule'}   = $i->{'rule'};
    $files{$i->{'component'}}{$i->{'key'}}{'status'} = $i->{'status'};
    $files{$i->{'component'}}{$i->{'key'}}{'sev'}    = $i->{'severity'};
  }
  push(
    @{$ret{'log'}},
    "[Plugins::SonarQube45] Got ["
      . scalar(keys %issues_critical)
      . "] critical issues."
  );
  push(
    @{$ret{'log'}},
    "[Plugins::SonarQube45] Got ["
      . scalar @{($content->{'rules'} || [])}
      . "] rules."
  );

  # Print issues to file system.
  $csv_out = "key,rule,sev,last_update,message\n";
  foreach my $i (sort keys %issues_critical) {
    my $msg = $issues_critical{$i}{'msg'};
    $msg =~ tr/,;"'/ /;
    $csv_out
      .= $i . ","
      . $issues_critical{$i}{'rule'} . ","
      . $issues_critical{$i}{'sev'} . ","
      . $issues_critical{$i}{'last_update'} . ","
      . $msg . "\n";
  }
  $repofs->write_output($project_id, "sq_issues_critical.csv", $csv_out);
  $repofs->write_plugin('SonarQube45', $project_id . "_sq_issues_critical.csv",
    $csv_out);

  # Fetch major issues
  $url_issues
    = $sonar_url
    . "/api/issues/search?projectKeys="
    . $sonar_project
    . "&pageSize=-1&severities=MAJOR";
  push(
    @{$ret{'log'}},
    "[Plugins::SonarQube45] Get issues from [${url_issues}]."
  );
  $content = $ua->get($url_issues)->res->json;
  $repofs->write_input($project_id, "import_sq_issues_major.json",
    encode_json($content));
  foreach my $i (@{$content->{'issues'}}) {
    $issues_major{$i->{'key'}}{'msg'}         = $i->{'message'};
    $issues_major{$i->{'key'}}{'rule'}        = $i->{'rule'};
    $issues_major{$i->{'key'}}{'sev'}         = $i->{'severity'};
    $issues_major{$i->{'key'}}{'last_update'} = $i->{'updateDate'};
    $rules{$i->{'rule'}}{'vol'}++;
    $rules{$i->{'rule'}}{'sev'}                      = $i->{'severity'};
    $files{$i->{'component'}}{$i->{'key'}}{'msg'}    = $i->{'message'};
    $files{$i->{'component'}}{$i->{'key'}}{'line'}   = $i->{'message'};
    $files{$i->{'component'}}{$i->{'key'}}{'rule'}   = $i->{'rule'};
    $files{$i->{'component'}}{$i->{'key'}}{'status'} = $i->{'status'};
    $files{$i->{'component'}}{$i->{'key'}}{'sev'}    = $i->{'severity'};
  }
  push(
    @{$ret{'log'}},
    "[Plugins::SonarQube45] Got ["
      . scalar(keys %issues_major)
      . "] major issues."
  );

  foreach my $i (@{$content->{'rules'}}) {
    $rules{$i->{'key'}}{'desc'}   = $i->{'desc'};
    $rules{$i->{'key'}}{'name'}   = $i->{'name'};
    $rules{$i->{'key'}}{'status'} = $i->{'status'};
  }
  $repofs->write_output($project_id, "sq_ref_rules.json", encode_json(\%rules));
  $repofs->write_plugin('SonarQube45', $project_id . "_sq_ref_rules.json",
    encode_json(\%rules));


  $ret{'metrics'}{'SQ_RULES'} = scalar @{$content->{'rules'}};
  push(
    @{$ret{'log'}},
    "[Plugins::SonarQube45] Got [" . scalar @{$content->{'rules'}} . "] rules."
  );

  # Print issues to file system.
  $csv_out = "key,rule,sev,last_update,message\n";
  foreach my $i (sort keys %issues_major) {
    my $msg = $issues_major{$i}{'msg'} || '';
    $msg =~ tr/,;"'/ /;
    $csv_out
      .= $i . ","
      . ($issues_major{$i}{'rule'}        || '') . ","
      . ($issues_major{$i}{'sev'}         || '') . ","
      . ($issues_major{$i}{'last_update'} || '') . ","
      . $msg . "\n";
  }
  $repofs->write_output($project_id, "sq_issues_major.csv", $csv_out);
  $repofs->write_plugin('SonarQube45', $project_id . "_sq_issues_major.csv",
    $csv_out);


  # Now retrieve all required metrics
  my $metrics_csv = join(',', sort keys %{$conf{'provides_metrics'}});
  my $url_res
    = $sonar_url
    . '/api/resources?resource='
    . $sonar_project
    . '&format=json&metrics='
    . $metrics_csv;
  push(
    @{$ret{'log'}},
    "[Plugins::SonarQube45] Get resources from [${url_res}]."
  );
  $content = $ua->get($url_res)->res->json;

  # Store all metrics with their Alambic names instead of SQ names.
  foreach my $m (@{$content->[0]{'msr'}}) {
    if (exists($conf{'provides_metrics'}{$m->{'key'}})) {
      $ret{'metrics'}{$conf{'provides_metrics'}{$m->{'key'}}} = $m->{'val'};
    }
  }
  push(
    @{$ret{'log'}},
    "[Plugins::SonarQube45] Got [" . scalar
      keys(%{$ret{'metrics'}}) . "] metrics."
  );

  # Print main information to file system.
  my $url_info
    = $sonar_url
    . '/api/server/system?resource='
    . $sonar_project
    . '&format=json';
  push(
    @{$ret{'log'}},
    "[Plugins::SonarQube45] Get resources from [${url_info}]."
  );
  $content = $ua->get($url_info)->res->json;

  $csv_out
    = "SonarQube version,Rules,JVM Vendor,JVM Name,Total Memory,Free Memory,Plugins\n";

  # Depends on the rights we have with this login..
  if (ref($content) eq 'ARRAY') {

    # We have rights to access the server info.
    $csv_out
      .= $content->[0]{'sonar_info'}{'Version'} . ","
      . $ret{'metrics'}{'SQ_RULES'} . ","
      . $content->[0]{'system_info'}{'JVM Vendor'} . ","
      . $content->[0]{'system_info'}{'JVM Name'} . ","
      . $content->[0]{'system_statistics'}{'Total Memory'} . ","
      . $content->[0]{'system_statistics'}{'Free Memory'} . ","
      . join('-',
      map { $_ . ':' . $content->[0]{'sonar_plugins'}{$_} }
      sort keys %{$content->[0]{'sonar_plugins'}})
      . "\n";
  }
  else {
    # We don't have admin rights
    $csv_out
      .= "Unknown,"
      . $ret{'metrics'}{'SQ_RULES'}
      . ",Unknown,Unknown,Unknown,Unknown,Unknown\n";
  }
  $repofs->write_plugin('SonarQube45', $project_id . "_sq_info.csv", $csv_out);

  # Print metrics to file system.
  $csv_out = join(',',
    map { $conf{'provides_metrics'}{$_} } keys %{$conf{'provides_metrics'}})
    . "\n";
  $csv_out .= join(',',
    map { $ret{'metrics'}{$conf{'provides_metrics'}{$_}} || '' }
      keys %{$conf{'provides_metrics'}})
    . "\n";
  $repofs->write_output($project_id, "sq_metrics.csv", $csv_out);
  $repofs->write_plugin('SonarQube45', $project_id . "_sq_metrics.csv",
    $csv_out);

  # Now execute the main R script.
  push(@{$ret{'log'}}, "[Plugins::SonarQube45] Executing R main file.");
  my $r = Alambic::Tools::R->new();
  push(
    @{$ret{'log'}},
    @{$r->knit_rmarkdown_inc('SonarQube45', $project_id, 'sonarqube45.Rmd')}
  );

  # And execute the figures R scripts.
  my @figs = (
    'sonarqube_violations_pie.rmd',
    'sonarqube_summary.rmd', 'sonarqube_violations.rmd'
  );
  foreach my $fig (sort @figs) {
    push(@{$ret{'log'}}, "[Plugins::SonarQube45] Executing R fig file [$fig].");
    @{$ret{'log'}} = (
      @{$ret{'log'}},
      @{$r->knit_rmarkdown_html('SonarQube45', $project_id, $fig)}
    );
  }


  return \%ret;
}


1;




=encoding utf8

=head1 NAME

B<Alambic::Plugins::SonarQube45> - A plugin to fetch information from a 
SonarQube 4.5.x instance.

=head1 DESCRIPTION

B<Alambic::Plugins::SonarQube45> retrieves information from a SonarQube 4.5.x instance.

Parameters:

=over

=item * B<SonarQube server URL> The URL of the SonarQube server, e.g. https://sonar.eclipse.org or http://localhost:9000.

=item * B<Project ID> The ID of the project within the SonarQube instance, e.g. log4j or org.polarsys:org.polarsys.capella.

=back

For the complete configuration see the user documentation on the web site: L<https://alambic.io/Plugins/Pre/SonarQube45.html>.

=head1 SEE ALSO

L<https://alambic.io/Plugins/Pre/SonarQube45.html>, L<https://www.sonarqube.org>,

L<Mojolicious>, L<http://alambic.io>, L<https://bitbucket.org/BorisBaldassari/alambic>


=cut

