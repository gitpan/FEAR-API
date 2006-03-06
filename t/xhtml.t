use Test::More tests => 1;

use strict;
use FEAR::API -base;

#print fetch('google.com')->document->html_to_xhtml;
file('index.html')->document->html_to_xhtml;

document->xpath('/html/head/title',
		'/html/body/center/table/tr[1]'
	       );
print $$_;

