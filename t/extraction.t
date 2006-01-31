use strict;
use FEAR::API -base;

use Test::More tests => 1;

url('google.com')->();
submit_form(
	    form_name => 'f',
	    fields => {
		       q => 'cpan',
		      }
	   );

template('[% ... %]<font[% ... %]>[% record %]</font>');
extract;
ok(@{ extresult() });
