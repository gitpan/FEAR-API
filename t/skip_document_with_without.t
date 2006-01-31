use Test::More tests => 2;

use strict;
use Data::Dumper;
use FEAR::API -base, -url => 'http://cnn.com';

$_->();

my $d = $_->doc();
ok $d->content_contains(qr(cnn));
ok $d->content_lacks(qr(qhpegriunbvpeiufnviupadnvgpaifdnbupaengpqenbeqpirunbpeqrueqi));


