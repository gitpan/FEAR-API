use Test::More tests => 2;

use strict;
use FEAR::API -base;

fetch('google.com')->document->html_to_xhtml;
document->xpath('/html/head/title',
		'/html/body/center/table/tr[1]'
	       );
like($$_, qr(title)) ;
like($$_, qr(bottom)) ;

