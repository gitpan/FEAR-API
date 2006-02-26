use Test::More tests => 1;

use strict;
use FEAR::API -base;

url('http://tw.yahoo.com')->();
document->MIME_encode;
#print document->as_string;
document->MIME_decode;
like(document->as_string, qr'yahoo');
