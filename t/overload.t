use strict;
use Data::Dumper;
use FEAR::API;
use Test::More 'no_plan';

my $f = fear('http://www.bbc.co.uk/cgi-bin/search/results.pl?q=asdf&go.x=0&go.y=0&go=go&uri=%2Fcalc%2Fnews%2F');

sub fetch {
  &$f;
  $f > my $source;
  ok($source);
  ok($$f);
  is($source => $$f);
}

sub extract_title {
  $f->auto_append_url(1);
  $f  | _preproc ( 's/BBC/CBB/sig')
      | _template('<title>[% title %]</title>')
      | _postproc( '$_->{url} =~ s/http/ftp/')
	;
#  print Dumper \@$f;
  like($f->[0]{url}, qr'ftp');
  like($f->[0]{title}, qr'CBB', 'title test');
  $f  | _preproc ( 's/BBC/CBB/sig')
      | '<title>[% title %]</title>'
      | _postproc( '$_->{url} =~ s/http/ftp/')
	;
  like($f->[0]{title}, qr'CBB', 'title test');
}


sub recursive_get {
  $f >> $f;
  my $cnn = 'http://cnn.com';
  $f += [ $cnn ];
#  print Dumper $f->{url};
  is($f->{url}[-1], $cnn);
  $f->() while $f;
}

sub getprint {
  my $str;
  use IO::String;
  my $io = IO::String->new($str);
  $f | _print($io);
  ok($str);
}

sub save_document {
  $f | _save_as('fetched.html');
  ok( -s 'fetched.html' );
  unlink 'fetched.html';
}

sub save_as_tree {
  $f | _save_as_tree('t/root');
  ok(-d 't/root/www.bbc.co.uk/');
}

fetch;
getprint;
extract_title;
recursive_get;
save_document;
save_as_tree;

