use strict;
use FEAR::API -base;

use Test::More tests => 1;

$_->url('http://www.google.com.tw');
$_->fetch();
$_->submit_form(
	form_number => 1,
	fields => {
		q => 'Bush',
	}	
	);

ok($_->document->as_string);
print $_->document->as_string;