use strict;
use FEAR::API -base;

use Test::More tests => 5;

my @links = $_->url('http://google.com')->fetch()->links;

$_->keep_links('news');

ok($_->links);
ok($_->links < @links);

$_->wua->{links} = [ @links ];
$_->keep_links(tag => qr'no_such_a_tag');
ok(!$_->links);

$_->wua->{links} = [ @links ];
$_->keep_links(text => qr'english'i);
is($_->links, 1);

$_->wua->{links} = [ @links ];
$_->remove_links('ncr');
is($_->links, @links-1);

__END__
