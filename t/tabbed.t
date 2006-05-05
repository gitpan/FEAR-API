use Test::More tests => 13;
use FEAR::API -base;

fetch('google.com');
like(current_url(), qr(google));

tab 1;
unlike(current_url(), qr(google));
fetch('tw.yahoo.com');
like(current_url(), qr(tw));
like(document->as_string, qr(yahoo));

tab 0;
like(current_url(), qr(google));
ok(document->as_string);
like(document->as_string, qr(google)i);

tab 2;
fetch("search.cpan.org");
ok(document->as_string);
like(document->as_string, qr(perl)i);


is(scalar @FEAR::API::tabs, 3);
close_tab 1;
is(scalar @FEAR::API::tabs, 2);


keep_tab 1;
is(scalar @FEAR::API::tabs, 1);
like(current_url, qr(cpan));
