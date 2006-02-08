use Test::More 'no_plan';

use strict;
use FEAR::API -base;

my @l;
url('http://google.com')->();
fallthrough_report(1);
report_links(
	 qr() => _feedback,
	 qr() => \@l,
	 qr() => sub {  ok '>>>'.Dumper($_) }
	);
#print Dumper \@l;
ok(@l);
ok(@{$_->{url}});
while( has_more_urls ){
  fetch;
  ok(doc->as_string);
}
