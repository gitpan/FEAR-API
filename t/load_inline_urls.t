use Test::More tests => 1;
use strict;
use Data::Dumper;
use FEAR::API -base;

my $url_file = '__URLS__';
$_
  ->url_from_inline($url_file)
  ;
is($_->{url}->[0], 'http://directory.google.com');


__END__
__URLS__
http://directory.google.com