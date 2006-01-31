use Test::More 'no_plan';

use FEAR::API -base;

# GET
get('http://search.cpan.org/search', query => 'cpan', mode => 'all');
like(document->as_string, qr'Results');


