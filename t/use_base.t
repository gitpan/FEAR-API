use Test::More tests => 2;
use strict;
use Data::Dumper;
use FEAR::API -base, -url => 'http://directory.google.com';

ok($_->isa('FEAR::API'));
is($_->{url}->[0], 'http://directory.google.com');
