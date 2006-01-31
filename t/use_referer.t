use strict;
use FEAR::API -base;

use Test::More tests => 1;

$_->referer('http://google.com');
$_->url('http://google.com');
$_->fetch();

ok(ref $_->document);
