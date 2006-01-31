use Test::More tests => 2;
use strict;
use Data::Dumper;
use FEAR::API -base;

my $url_file = 't/data/url_list';
ok(-e $url_file);
$_
  ->url_from_file($url_file)
  ;
is($_->{url}->[0], 'http://directory.google.com');
