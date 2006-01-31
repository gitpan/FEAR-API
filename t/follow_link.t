use strict;
use FEAR::API -base;

use Test::More tests => 4;

url('google.com')->();
my $content = $_->document->as_string;
like(current_url, qr'google');

follow_link(n => 2);
like(current_url, qr'google');

back;
is($content, $_->document->as_string);

follow_link(n => 1);
like(current_url, qr'google');
