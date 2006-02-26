use Test::More tests => 1;
ok(1);

use strict;
use FEAR::API -base;

url('google.com')->();
keep_links(qr(https));
#print Dumper links;