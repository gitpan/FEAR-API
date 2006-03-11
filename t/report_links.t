use Test::More 'no_plan';

use strict;
use FEAR::API -base;

allow_duplicate(1);
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
ok(@{$_->value('url')});
while( has_more_urls ){
  fetch;
  ok(doc->as_string);
}


url('http://google.com')->();
report_links(
	 sub {$_->text =~ /google/i} => _feedback,
	);
while( has_more_urls ){
  fetch;
  ok(doc->as_string);
}
