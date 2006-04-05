use Test::More qw(no_plan);

use strict;
use FEAR::API -base;

ok(1);

url("google.com")->() >> _self;
pfetch(sub{
    join q/ /, title, current_url, document->size,$/;
});
