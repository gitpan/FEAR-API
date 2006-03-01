use Test::More tests => 4;

use strict;
use FEAR::API -base;
use Encode;

allow_duplicate(1);
url('http://google.com')->() | _grep(qr(title));
ok($$_);

url('http://google.com')->() | _map(sub { length($_) * 2 });
ok($$_);

url('http://google.com')->() | _sort;
ok($$_);

document->content(join qq/\n/, qw(1 2 3 4 1 5 5 6 7 51));
$_ | _uniq;
ok($$_);
