#! perl -I../../lib/
#########################################################
#
# Copyright (c) 2015-2017 Castalia Solutions and Thales Group.
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


use strict;
use warnings;

use Test::More;
use Mojo::JSON qw( decode_json);
use Data::Dumper;

BEGIN { use_ok('Alambic::Plugins::EclipseForums'); }

my $plugin = Alambic::Plugins::EclipseForums->new();
isa_ok($plugin, 'Alambic::Plugins::EclipseForums');

note("Checking the plugin parameters. ");
my $conf = $plugin->get_conf();

ok(grep(m!forum_id!, keys %{$conf->{'params'}}), "Conf has params > forum_id");
ok(grep(m!proxy!, keys %{$conf->{'params'}}),
  "Conf has params > proxy");

ok(grep(m!info!,    @{$conf->{'ability'}}), "Conf has ability > info");
ok(grep(m!metrics!, @{$conf->{'ability'}}), "Conf has ability > metrics");
ok(grep(m!data!,    @{$conf->{'ability'}}), "Conf has ability > data");
ok(grep(m!recs!,    @{$conf->{'ability'}}), "Conf has ability > recs");
ok(grep(m!figs!,    @{$conf->{'ability'}}), "Conf has ability > figs");
ok(grep(m!viz!,     @{$conf->{'ability'}}), "Conf has ability > viz");

ok(grep(m!MLS_USR_URL!, @{$conf->{'provides_info'}}),
  "Conf has provides_info > MLS_USR_URL");
ok(grep(m!MLS_USR_NAME!, @{$conf->{'provides_info'}}),
  "Conf has provides_info > MLS_USR_NAME");
ok(grep(m!MLS_USR_CAT!, @{$conf->{'provides_info'}}),
  "Conf has provides_info > MLS_USR_CAT");
ok(grep(m!MLS_USR_DESC!, @{$conf->{'provides_info'}}),
  "Conf has provides_info > MLS_USR_DESC");

ok(grep(m!import_eclipse_forums_forum.json!, keys %{$conf->{'provides_data'}}),
  "Conf has provides_data > import_eclipse_forums_forum.json");
ok(grep(m!import_eclipse_forums_threads.json!, keys %{$conf->{'provides_data'}}),
  "Conf has provides_data > import_eclipse_forums_threads.json");
ok(grep(m!import_eclipse_forums_posts.json!, keys %{$conf->{'provides_data'}}),
  "Conf has provides_data > import_eclipse_forums_posts.json");

ok(grep(m!eclipse_forums_forum.csv!, keys %{$conf->{'provides_data'}}),
  "Conf has provides_data > eclipse_forums_forum.csv") or print Dumper($conf->{'provides_data'});
ok(grep(m!eclipse_forums_threads.csv!, keys %{$conf->{'provides_data'}}),
  "Conf has provides_data > eclipse_forums_threads.csv");
ok(grep(m!eclipse_forums_posts.csv!, keys %{$conf->{'provides_data'}}),
  "Conf has provides_data > eclipse_forums_posts.csv");



ok(grep(m!MLS_USR_VOL!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > MLS_USR_VOL");
ok(grep(m!MLS_USR_AUTHORS!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > MLS_USR_AUTHORS");
ok(grep(m!MLS_USR_AUTHORS_1M!, keys %{$conf->{'provides_metrics'}}),
   "Conf has provides_metrics > MLS_USR_AUTHORS_1M");
ok(grep(m!MLS_USR_AUTHORS_1W!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > MLS_USR_AUTHORS_1W");
ok(grep(m!MLS_USR_AUTHORS_1Y!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > MLS_USR_AUTHORS_1Y");
ok(grep(m!MLS_USR_THREADS_1M!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > MLS_USR_THREADS_1M");
ok(grep(m!MLS_USR_THREADS_1W!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > MLS_USR_THREADS_1W");
ok(grep(m!MLS_USR_THREADS_1Y!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > MLS_USR_THREADS_1Y");
ok(grep(m!MLS_USR_POSTS_1M!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > MLS_USR_POSTS_1M");
ok(grep(m!MLS_USR_POSTS_1W!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > MLS_USR_POSTS_1W");
ok(grep(m!MLS_USR_POSTS_1Y!, keys %{$conf->{'provides_metrics'}}),
  "Conf has provides_metrics > MLS_USR_POSTS_1Y");

ok(grep(m!eclipse_forums_wordcloud.png!, keys %{$conf->{'provides_figs'}}),
  "Conf has provides_figs > eclipse_forums_wordcloud.png");
ok(grep(m!eclipse_forums_wordcloud.svg!, keys %{$conf->{'provides_figs'}}),
  "Conf has provides_figs > eclipse_forums_wordcloud.svg");
ok(grep(m!eclipse_forums_plot.html!, keys %{$conf->{'provides_figs'}}),
  "Conf has provides_figs > eclipse_forums_plot.html");

# Remove file before trying to create them.
unlink (
    "projects/test.mls/input/test.mls_import_eclipse_forums_forum.json",
    "projects/test.mls/input/test.mls_import_eclipse_forums_threads.json",
    "projects/test.mls/input/test.mls_import_eclipse_forums_posts.json",
    "projects/test.mls/output/test.mls_eclipse_forums_forum.csv",
    "projects/test.mls/output/test.mls_eclipse_forums_threads.csv",
    "projects/test.mls/output/test.mls_eclipse_forums_posts.csv",
    "projects/test.mls/output/test.mls_eclipse_forums_wordcloud.svg",
    "projects/test.mls/output/test.mls_eclipse_forums_wordcloud.png",
    "projects/test.mls/output/test.mls_eclipse_forums_plot.html",
    "projects/test.mls/output/test.mls_eclipse_forums.inc",
    );

note("Executing the plugin with sirius project. ");
my $ret = $plugin->run_plugin(
  "test.mls",
  {
    'forum_id'         => '262',
    'proxy'     => '',
  }
    );

ok(
  grep(m!\[Plugins::EclipseForums\] Fetch forum info using \[https://api.eclipse.org!,
    @{$ret->{'log'}}),
  "Ret has log > fetch info."
) or print Dumper( $ret->{'log'} );
ok(grep(m!\[Plugins::EclipseForums\] Writing Forum info json file to input.!, @{$ret->{'log'}}),
  "Ret has log > writing forum info to json.");
ok(grep(m!\[Plugins::EclipseForums\] Fetch topics for forum using \[https://api.!, @{$ret->{'log'}}),
  "Ret has log > fetch topics.");

ok(grep(/^\[Tools::R\] Exec \[Rsc.*eclipse_forums.Rmd/, @{$ret->{'log'}}) == 1,
 "Checking if log contains eclipse_forums.Rmd R code exec.")
 or diag explain $ret;
ok(
 grep(/^\[Tools::R\] Exec \[Rsc.*eclipse_forums_wordcloud.r/, @{$ret->{'log'}})
   == 1,
 "Checking if log contains eclipse_forums_wordcloud.r R code exec."
) or diag explain $ret;

ok($ret->{'metrics'}{'MLS_USR_POSTS'} =~ /^\d+$/, "MLS_USR_POSTS is a digit.")
    or print Dumper($ret);
ok($ret->{'metrics'}{'MLS_USR_POSTS_1W'} =~ /^\d+$/, "MLS_USR_POSTS_1W is a digit.")
    or print Dumper($ret);
ok($ret->{'metrics'}{'MLS_USR_POSTS_1M'} =~ /^\d+$/, "MLS_USR_POSTS_1M is a digit.")
  or print Dumper($ret);
ok($ret->{'metrics'}{'MLS_USR_POSTS_1Y'} =~ /^\d+$/, "MLS_USR_POSTS_1Y is a digit.")
  or print Dumper($ret);

ok($ret->{'metrics'}{'MLS_USR_AUTHORS'} =~ /^\d+$/, "MLS_USR_AUTHORS is a digit.")
    or print Dumper($ret);
ok($ret->{'metrics'}{'MLS_USR_AUTHORS_1W'} =~ /^\d+$/, "MLS_USR_AUTHORS_1W is a digit.")
    or print Dumper($ret);
ok($ret->{'metrics'}{'MLS_USR_AUTHORS_1M'} =~ /^\d+$/, "MLS_USR_AUTHORS_1M is a digit.")
  or print Dumper($ret);
ok($ret->{'metrics'}{'MLS_USR_AUTHORS_1Y'} =~ /^\d+$/, "MLS_USR_AUTHORS_1Y is a digit.")
  or print Dumper($ret);

ok($ret->{'metrics'}{'MLS_USR_THREADS'} =~ /^\d+$/, "MLS_USR_THREADS is a digit.")
    or print Dumper($ret);
ok($ret->{'metrics'}{'MLS_USR_THREADS_1W'} =~ /^\d+$/, "MLS_USR_THREADS_1W is a digit.")
    or print Dumper($ret);
ok($ret->{'metrics'}{'MLS_USR_THREADS_1M'} =~ /^\d+$/, "MLS_USR_THREADS_1M is a digit.")
  or print Dumper($ret);
ok($ret->{'metrics'}{'MLS_USR_THREADS_1Y'} =~ /^\d+$/, "MLS_USR_THREADS_1Y is a digit.")
  or print Dumper($ret);


ok($ret->{'info'}{'MLS_USR_NAME'} eq 'Sirius',
  "Ret has correct info MLS_USR_NAME.") or print Dumper($ret);
ok($ret->{'info'}{'MLS_USR_DESC'} eq 'Sirius communtiy discussions',
  "Ret has correct info MLS_USR_DESC.") or print Dumper($ret);
ok($ret->{'info'}{'MLS_USR_URL'} eq 'https://www.eclipse.org/forums/index.php/f/262/',
  "Ret has correct info MLS_USR_URL.") or print Dumper($ret);
ok($ret->{'info'}{'MLS_USR_CAT_URL'} =~ m!^https://api.eclipse.org/forums/category!,
  "Ret has correct info MLS_USR_CAT_URL.") or print Dumper($ret);


note("Check that files have been created. ");
ok(-e "projects/test.mls/input/test.mls_import_eclipse_forums_forum.json",
  "Check that file import_eclipse_forums_forum.json exists.");
ok(-e "projects/test.mls/input/test.mls_import_eclipse_forums_threads.json",
  "Check that file import_eclipse_forums_threads.json exists.");
ok(-e "projects/test.mls/input/test.mls_import_eclipse_forums_posts.json",
  "Check that file import_eclipse_forums_posts.json exists.");

ok(-e "projects/test.mls/output/test.mls_eclipse_forums_forum.csv",
   "Check that file eclipse_forums_forum.csv exists.");
ok(-e "projects/test.mls/output/test.mls_eclipse_forums_threads.csv",
   "Check that file eclipse_forums_threads.csv exists.");
ok(-e "projects/test.mls/output/test.mls_eclipse_forums_posts.csv",
   "Check that file eclipse_forums_posts.csv exists.");

ok(-e "projects/test.mls/output/test.mls_eclipse_forums_wordcloud.svg",
   "Check that file eclipse_forums_wordcloud.svg exists.");
ok(-e "projects/test.mls/output/test.mls_eclipse_forums_wordcloud.png",
   "Check that file eclipse_forums_wordcloud.png exists.");
ok(-e "projects/test.mls/output/test.mls_eclipse_forums_plot.html",
   "Check that file eclipse_forums_plot.html exists.");
ok(-e "projects/test.mls/output/test.mls_eclipse_forums.inc",
   "Check that file eclipse_forums.inc exists.");

done_testing();

