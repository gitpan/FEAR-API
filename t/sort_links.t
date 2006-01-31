use strict;
use FEAR::API -base;

use Test::More tests => 1;

my @links = $_->url('http://google.com')->fetch()->links;

#print Dumper [ $_->links];
$_->sort_links;
#print Dumper[ $_->links];

ok(($_->links)[0] ne $links[0]);

__END__
