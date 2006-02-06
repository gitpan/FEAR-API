use Test::More tests => 2;

use strict;
use FEAR::API -base;
use IO::All;


my $io = io('t/root/google');

fetch("google.com") > $io;
fetch("cnn.com") >> $io;
my $content << io('t/root/google');
like($content, qr(google)i);
like($content, qr(cnn)i);


