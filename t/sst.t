use Test::More qw(no_plan);
use FEAR::API -base;

load_sst(<<'.');
fetch('google.com') >> _self;
fetch&&Test::More::ok(1) while $_;
.

run_sst;
