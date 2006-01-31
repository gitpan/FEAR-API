use Test::More tests => 3;

use strict;
use Data::Dumper;
use FEAR::API -base;


my %f = $_->list_filters;
#print Dumper( $_);
#print join $/, keys %f;
ok($f{remove_leading_trailing_spaces});
ok($f{strip_html});
ok($f{decode_entities});