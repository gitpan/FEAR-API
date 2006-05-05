use Test::More tests => 2;
use strict;
use FEAR::API -base;


allow_duplicate(1);
use_docsum('document-checksum');
fetch('http://google.com');
fetch('http://google.com');

ok( doc_changed );

no_docsum;

fetch('http://google.com');
fetch('http://google.com');
ok( not doc_changed );
