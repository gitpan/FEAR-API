use strict;
use FEAR::API -base;
use Storable qw(dclone);

use Test::More tests => 4;


url('http://search.cpan.org/recent')->();
submit_form(
	form_name => 'f',
	fields => {
		   query => 'perl'
		  });

preproc('s/\A.+<!--results-->(.+)<!--end results-->.+\Z/$1/s');
unlike(document->as_string, qr'DOCTYPE HTML PUBLIC');
template('<!--item-->[% p %]<!--end item-->');
extract;
my $old_result = dclone extresult;
postproc('$_->{p} =~ s/<.+?>//g');

add_field(site => 'cpan');

my $new_result = dclone extresult;
unlike($new_result->[-1], qr'<.+>');
#print Dumper $new_result, $old_result;
ok(length $old_result->[0]->{p} > length $new_result->[0]->{p});

is($new_result->[0]->{site}, 'cpan');