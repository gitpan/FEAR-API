use Test::More tests => 1;

use strict;
use FEAR::API -base;

like( url('http://google.com')->()->title, qr'google'i);