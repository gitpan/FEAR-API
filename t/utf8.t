use Test::More tests => 1;

use strict;
use FEAR::API -base;
use Encode;

url('http://tw.yahoo.com')->();

ok( Encode::is_utf8($_->document->as_string) );

