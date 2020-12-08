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

package Alambic::Plugins::EclipseForums;

use strict;
use warnings;

use Alambic::Model::RepoFS;
use Alambic::Tools::R;

use Mojo::JSON qw( decode_json encode_json );
use Mojo::UserAgent;
use Date::Parse;
use Time::Piece;
use Time::Seconds;
use Text::CSV;
use Data::Dumper;


# Main configuration hash for the plugin
my %conf = (
  "id"   => "EclipseForums",
  "name" => "Eclipse Forums",
  "desc" => [
    "Eclipse Forums retrieves data about the forums used by the Eclipse infrastructure.",
    'See <a href="https://alambic.io/Plugins/Pre/EclipseForums.html">the project\'s documentation</a> for more information.',
  ],
  "type"    => "pre",
  "ability" => ["metrics", "info", 'data', 'figs', 'recs', 'viz'],
  "params"  => {
    "forum_id" =>
      "The ID of the forum to be used to identify the project on the Eclipse API server. Look for it in the URL of the project's forum on <a href=\"https://forums.eclipse.org\">https://forums.eclipse.org</a>.",
    "proxy" =>
      'If a proxy is required to access the remote resource of this plugin, please provide its URL here. A blank field means no proxy, and the <code>default</code> keyword uses the proxy from environment variables, see <a href="https://alambic.io/Documentation/Admin/Projects.html">the online documentation about proxies</a> for more details. Example: <code>https://user:pass@proxy.mycorp:3777</code>.',
  },
  "provides_cdata" => [],
  "provides_info"  => [
      "MLS_USR_URL",
      "MLS_USR_DESC",
      "MLS_USR_NAME",
      "MLS_USR_CAT",
  ],
  "provides_data" => {
    "import_eclipse_forums_forum.json" => "The forum description file as returned by Eclipse servers (JSON).",
    "import_eclipse_forums_threads.json" => "The list of threads for the forum as returned by Eclipse servers (JSON).",
    "import_eclipse_forums_posts.json" => "The list of posts for the forum as returned by Eclipse servers (JSON).",
    "eclipse_forums_forum.csv" => "The forum description file as returned by Eclipse servers (CSV).",
    "eclipse_forums_threads.csv" => "The list of threads for the forum as returned by Eclipse servers (CSV).",
    "eclipse_forums_posts.csv" => "The list of posts for the forum as returned by Eclipse servers (CSV).",
  },
  "provides_metrics" => {
    "MLS_USR_AUTHORS"    => "MLS_USR_AUTHORS",
    "MLS_USR_AUTHORS_1W"    => "MLS_USR_AUTHORS_1W",
    "MLS_USR_AUTHORS_1M"    => "MLS_USR_AUTHORS_1M",
    "MLS_USR_AUTHORS_1Y"    => "MLS_USR_AUTHORS_1Y",
    "MLS_USR_THREADS"    => "MLS_USR_THREADS",
    "MLS_USR_THREADS_1W"    => "MLS_USR_THREADS_1W",
    "MLS_USR_THREADS_1M"    => "MLS_USR_THREADS_1M",
    "MLS_USR_THREADS_1Y"    => "MLS_USR_THREADS_1Y",
    "MLS_USR_POSTS"    => "MLS_USR_POSTS",
    "MLS_USR_POSTS_1W"    => "MLS_USR_POSTS_1W",
    "MLS_USR_POSTS_1M"    => "MLS_USR_POSTS_1M",
    "MLS_USR_POSTS_1Y"    => "MLS_USR_POSTS_1Y",
    "MLS_USR_DIVERSITY_RATIO_1Y"    => "MLS_USR_DIVERSITY_RATIO_1Y",
  },
  "provides_figs" => {
      'eclipse_forums_wordcloud.svg' => 'Wordcloud of threads subjects (SVG)',
      'eclipse_forums_wordcloud.png' => 'Wordcloud of threads subjects (PNG)',
      'eclipse_forums_plot.html' => 'Timeline of posts',
  },
  "provides_recs" => [
  ],
  "provides_viz" => {"eclipse_forums.html" => "Eclipse Forums",},
);

my $eclipse_url  = "https://api.eclipse.org";


# Constructor to build a new EclipseForums object.
sub new {
  my ($class) = @_;

  return bless {}, $class;
}

# Get Wizard plugin configuration.
sub get_conf() {
  return \%conf;
}


# Run wizard plugin: retrieves data + compute_data.
sub run_plugin($$) {
  my ($self, $project_id, $conf) = @_;

  my $forum_id = $conf->{'forum_id'} || $project_id;
  my $proxy_url   = $conf->{'proxy'}       || '';

  # Create RepoFS object for writing and reading files on FS.
  my $repofs = Alambic::Model::RepoFS->new();

  # Retrieve and store data from the remote repository.
  my $ret_tmp = &_retrieve_data($project_id, $forum_id, $proxy_url, $repofs);
  if (not defined($ret_tmp)) {
    return {'log' => ['Could not fetch anything useful from api.eclipse.org.']};
  }

  
  my %ret = (
      'metrics' => $ret_tmp->{'metrics'}, 
      'info' => $ret_tmp->{'info'}, 
      'recs' => $ret_tmp->{'recs'},
      'log' => $ret_tmp->{'log'},
      );
  
  return \%ret;
}


sub _retrieve_data($$$) {
  my ($project_id, $forum_id, $proxy_url, $repofs) = @_;

  my @log;
  my @recs;
  my %metrics;
  my %info;

  # Prepare userAgent spider
  my $ua = Mojo::UserAgent->new;
  $ua->max_redirects(10);
  $ua->inactivity_timeout(60);

  # Time::Piece object. Will be used for the date calculations.
  my $t_now = localtime;
  my $t_1w  = $t_now - ONE_WEEK;
  my $t_1m  = $t_now - ONE_MONTH;
  my $t_1y  = $t_now - ONE_YEAR;

  # Configure Proxy
  if ($proxy_url =~ m!^default!i) {

    # If 'default', then use detect
    $ua->proxy->detect;
    my $proxy_http  = $ua->proxy->http;
    my $proxy_https = $ua->proxy->https;
    push(@log,
      "[Plugins::EclipseForums] Using default proxy [$proxy_http] and [$proxy_https]."
    );
  }
  elsif ($proxy_url =~ m!\S+!) {

    # If something, then use it
    $ua->proxy->http($proxy_url)->https($proxy_url);
    push(@log, "[Plugins::EclipseForums] Using provided proxy [$proxy_url].");
  }
  else {
    # If blank, then use no proxy
    push(@log, "[Plugins::EclipseForums] No proxy defined [$proxy_url].");
  }

  #
  # Fetch forum info json file from api.eclipse.org
  # 
 
  my $url = $eclipse_url . '/forums/forum/' . $forum_id . '';
  push(@log, "[Plugins::EclipseForums] Fetch forum info using [$url].");

  my $content = $ua->get($url)->res->body;

  my $forum = &_decode_content($content); 
#  return undef if (not defined($forum));
  
  push(@log, "[Plugins::EclipseForums] Writing Forum info json file to input.");
  $repofs->write_input($project_id, "import_eclipse_forums_forum.json",
    encode_json($forum));

  # Start to populate info 
  $info{'MLS_USR_URL'} = $forum->{'html_url'} || '';
  $info{'MLS_USR_NAME'} = $forum->{'name'} || '';
  $info{'MLS_USR_DESC'} = $forum->{'description'} || '';
  $info{'MLS_USR_CAT_URL'} = $forum->{'category_url'} || '';

  # Prepare CSV export for forum
  my $csv_forum = Text::CSV->new({binary => 1, eol => "\n"});
  my @csv_forum_attrs = sort keys %$forum;
  my $csv_forum_out = join( ',', @csv_forum_attrs ) . "\n";
  my @attrs_forum = map { $forum->{$_} || '' } @csv_forum_attrs;
  $csv_forum->combine(@attrs_forum);
  $csv_forum_out .= $csv_forum->string();
  
  # Write CSV file to output dir.
  $repofs->write_output($project_id, "eclipse_forums_forum.csv", $csv_forum_out);
  
  
  #
  # Fetch topics info json file from api.eclipse.org
  # 
  my @topics;
  $url = $eclipse_url . '/forums/topic?pagesize=100&forum_id=' . $forum_id;
  push(@log, "[Plugins::EclipseForums] Fetch topics for forum using [$url].");

  $content = $ua->get($url)->res->body;

  my $ret_topics = &_decode_content($content);
#  return undef if (not defined($ret_topics));

  @topics = @{$ret_topics->{'result'} || []};
  my $results_max = $ret_topics->{'pagination'}{'total_result_size'} || 0; 

  push(@log, "[Plugins::EclipseForums] Got topics [" . scalar( @topics )
     . "] id [" . ( $ret_topics->{'pagination'}{'result_end'} || 0 ) 
     . "] out of [$results_max] total.");

  
  # Get remaining pages if any.
  my $page = 2;
  my $result_end = $ret_topics->{'pagination'}{'result_end'} || 0;
  while($result_end < $results_max) {
    $url = $eclipse_url . '/forums/topic?pagesize=100&forum_id=' . $forum_id . '&page=' . $page;
    #push(@log, "[Plugins::EclipseForums] Fetch topics for forum using [$url].");

    $content = $ua->get($url)->res->body;

    $ret_topics = &_decode_content($content);
    #return undef if (not defined($ret_topics));

    my @topics_ = @{$ret_topics->{'result'} || []}; 
    push(@log, "[Plugins::EclipseForums] Got topics [" . scalar( @topics_ ) 
       . "] id [" . ( $ret_topics->{'pagination'}{'result_end'} || 0 ) 
       . "] out of [$results_max] total."); 
  
    # Add this page's set to the global array
    push( @topics, @topics_ ); 
    $page++;

    $result_end = $ret_topics->{'pagination'}{'result_end'} || 0;

    # Watchdog
    if ($page > 1000) { exit; }
  }

  push(@log, "[Plugins::EclipseForums] Writing Forum threads json file to input.");
  $repofs->write_input($project_id, "import_eclipse_forums_threads.json",
		       encode_json(\@topics));

  $metrics{'MLS_USR_THREADS'} = scalar @topics;
  my ($mls_usr_threads_1w, $mls_usr_threads_1m, $mls_usr_threads_1y) = (0,0,0);


  # Prepare CSV export for topics
  my $csv_topics = Text::CSV->new({binary => 1, eol => "\n"});
  my @csv_topics_attrs = ('id', 'subject', 'last_post_date', 'last_post_id', 
			  'root_post_id', 'replies', 'views', 'html_url');
  my $csv_topics_out = join( ',', @csv_topics_attrs ) . "\n";

  foreach my $topic (@topics) { 
    my $date_last_post = $topic->{'last_post_date'} || 0;
    
    # Is the topic recent (<1W)?
    if ($date_last_post > $t_1w->epoch) {
      $mls_usr_threads_1w++;
    }

    # Is the topic recent (<1M)?
    if ($date_last_post > $t_1m->epoch) {
	$mls_usr_threads_1m++;
    }

    # Is the topic recent (<1Y)?
    if ($date_last_post > $t_1y->epoch) {
      $mls_usr_threads_1y++;
    }
    

    my @attrs = map { $topic->{$_} || '' } @csv_topics_attrs;
    # if replies is empty, set to zero (more convenient for R post analysis).
    if ($attrs[5] =~ m!^$!) { $attrs[5] = 0 }
    
    $csv_topics->combine(@attrs);
    $csv_topics_out .= $csv_topics->string();
  }
  
  # Write CSV file to output dir.
  $repofs->write_output($project_id, "eclipse_forums_threads.csv", $csv_topics_out);
  
  $metrics{'MLS_USR_THREADS_1W'} = $mls_usr_threads_1w;
  $metrics{'MLS_USR_THREADS_1M'} = $mls_usr_threads_1m;
  $metrics{'MLS_USR_THREADS_1Y'} = $mls_usr_threads_1y;

  
  #
  # Fetch posts info json file from api.eclipse.org
  # 
  my @posts;
  $url = $eclipse_url . '/forums/post?pagesize=100&forum_id=' . $forum_id;
#  push(@log, "[Plugins::EclipseForums] Fetch posts for forum using [$url].");
  $content = $ua->get($url)->res->body;

  my $ret_posts = &_decode_content($content);
#  return undef if (not defined($ret_posts));

  @posts = @{$ret_posts->{'result'} || []}; 
  $results_max = $ret_posts->{'pagination'}{'total_result_size'} || 0;

  push(@log, "[Plugins::EclipseForums] Got posts [" . scalar( @posts )
     . "] id [" . ( $ret_posts->{'pagination'}{'result_end'} || '' )
     . "] out of [$results_max] total.");
  
  # Get remaining pages if any.
  $page = 2;
  $result_end = $ret_posts->{'pagination'}{'result_end'} || 0;
  while($result_end < $results_max) {
    $url = $eclipse_url . '/forums/post?pagesize=100&forum_id=' . $forum_id . '&page=' . $page;
#    push(@log, "[Plugins::EclipseForums] Fetch posts for forum using [$url].");

    $content = $ua->get($url)->res->body;

    $ret_posts = &_decode_content($content);
#    return undef if (not defined($ret_posts));

    my @posts_ = @{$ret_posts->{'result'} || []};
    push(@log, "[Plugins::EclipseForums] Got posts [" . scalar( @posts_ )
       . "] id [" . ( $ret_posts->{'pagination'}{'result_end'} || '' )
       . "] out of [$results_max] total.");
    
    # Add this page's set to the global array
    push( @posts, @posts_ ); 
    $page++;

    $result_end = $ret_posts->{'pagination'}{'result_end'} || 0;

    # Watchdog
    if ($page > 1000) { exit; }
  }

  push(@log, "[Plugins::EclipseForums] Writing forum posts json file to input.");
  $repofs->write_input($project_id, "import_eclipse_forums_posts.json",
    encode_json($ret_posts));

  $metrics{'MLS_USR_POSTS'} = scalar @topics;
  my ($mls_usr_posts_1w, $mls_usr_posts_1m, $mls_usr_posts_1y) = (0,0,0);
  my (%authors, %authors_1w, %authors_1m, %authors_1y);
  my %timeline_p;

  # Prepare CSV export for posts
  my $csv_posts = Text::CSV->new({binary => 1, eol => "\n"});
  my @csv_attrs = ('id', 'subject', 'created_date', 'author_id', 'thread_id', 'html_url');
  my $csv_posts_out = join( ',', @csv_attrs ) . "\n";
  
  foreach my $post (@posts) {
    my $date_post = $post->{'created_date'} || 0;

    my ($S, $M, $H, $d, $m, $Y) = localtime($date_post);
    $timeline_p{ "$Y-$m-$d" }++;
    $authors{$post->{'poster_id'}}++;
    
    # Is the post recent (<1W)?
    if ($date_post > $t_1w->epoch) {
      $authors_1w{$post->{'poster_id'}}++;
      $mls_usr_posts_1w++;
    }

    # Is the post recent (<1M)?
    if ($date_post > $t_1m->epoch) {
	$authors_1m{$post->{'poster_id'}}++;
	$mls_usr_posts_1m++;
    }

    # Is the post recent (<1Y)?
    if ($date_post > $t_1y->epoch) {
      $authors_1y{$post->{'poster_id'}}++;
      $mls_usr_posts_1y++;
    }

    
    my @attrs = (
	$post->{'id'},
	$post->{'subject'}, 
	$post->{'created_date'},
	$post->{'poster_id'}, 
	$post->{'topic_id'}, 
	$post->{'html_url'}
	);
    $csv_posts->combine(@attrs);
    $csv_posts_out .= $csv_posts->string();
  }

  # Write CSV file to output dir.
  $repofs->write_output($project_id, "eclipse_forums_posts.csv", $csv_posts_out);

  
  $metrics{'MLS_USR_POSTS_1W'}   = $mls_usr_posts_1w;
  $metrics{'MLS_USR_POSTS_1M'}   = $mls_usr_posts_1m;
  $metrics{'MLS_USR_POSTS_1Y'}   = $mls_usr_posts_1y;
  
  $metrics{'MLS_USR_AUTHORS'}    = scalar keys %authors || 0;
  $metrics{'MLS_USR_AUTHORS_1W'} = scalar keys %authors_1w || 0;
  $metrics{'MLS_USR_AUTHORS_1M'} = scalar keys %authors_1m || 0;
  $metrics{'MLS_USR_AUTHORS_1Y'} = scalar keys %authors_1y || 0;


  my $authors_1y = $metrics{'MLS_USR_AUTHORS_1Y'} == 0 ? 1 : $metrics{'MLS_USR_AUTHORS_1Y'};
  $metrics{'MLS_USR_DIVERSITY_RATIO_1Y'}   = int( 
    $metrics{'MLS_USR_POSTS_1Y'} / $authors_1y 
  );

  
  # Now execute the main R script.
  push(@log, "[Plugins::EclipseForums] Executing R main file.");
  my $r = Alambic::Tools::R->new();
  @log = (
    @log,
    @{$r->knit_rmarkdown_inc('EclipseForums', $project_id, 'eclipse_forums.Rmd')}
      );
  @log = ( @log,
    @{ $r->knit_rmarkdown_images('EclipseForums', $project_id, 
			       'eclipse_forums_wordcloud.r',
			       ['eclipse_forums_wordcloud.png', 
				'eclipse_forums_wordcloud.svg']) 
    }
  );
  @log = ( @log,
    @{ $r->knit_rmarkdown_html('EclipseForums', $project_id, 
			       'eclipse_forums_plot.rmd',
			       []) 
    }
  );
  
  
  my %ret = (
      'metrics' => \%metrics, 
      'info' => \%info, 
      'recs' => \@recs,
      'log' => \@log,
      );

  return \%ret;
}


sub _decode_content() {
    my $content = shift;
    
  # Check if we actually get some results.
  my $decoded;
  my $is_ok = 0;

  # Remove utf8 chars and weird chars from body.
  $content =~ s!\\u[0-9a-fA-F]{4}!!g;
  $content =~ s/"body":\s?".+?",\s?"/"body":"","/g;

  eval {
    $decoded = decode_json($content);
    $is_ok = 1;
  };
  if ($is_ok) { 
    return $decoded;
  } else {
    print "Could not decode data: \n" . Dumper($content);
    return undef;
  }
}



1;


=encoding utf8

=head1 NAME

B<Alambic::Plugins::EclipseForums> - A plugin to fetch information about the
Eclipse Forums.

=head1 DESCRIPTION

B<Alambic::Plugins::EclipseForums> retrieves information from the Eclipse forums hosted on 
L<https://forums.eclipse.org>.

Parameters:

=over

=item * Project forum ID - e.g. C<232> for Sisu forums.

=back

For the complete configuration see the user documentation on the web site: L<https://alambic.io/Plugins/Pre/EclipseForums.html>.

=head1 SEE ALSO

L<https://alambic.io/Plugins/Pre/EclipseForums.html>, L<https://forums.eclipse.org>,

L<Mojolicious>, L<http://alambic.io>, L<https://bitbucket.org/BorisBaldassari/alambic>


=cut

