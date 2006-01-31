use Test::More tests => 2;
use strict;
use Data::Dumper;
use FEAR::API -base;

my $url_file = '__URLS__';
$_
  ->url_from_inline($url_file)
  ;
is($_->{url}->[0], 'http://some.site/a');
is($_->{url}->[25], 'http://some.site/z');


__END__
__URLS__
[% FOREACH i = ['a'..'z'] %]

     http://some.site/[% i %]

[% END %]