use Test::More tests => 4;

use strict;
use lib qw(t/data);
use FEAR::API -base;
use CPAN::DBI;

ok(-e 't/data/cpan.db');

url("http://search.cpan.org/")->();
submit_form(form_name => 'f',
	    fields => {
		       query => 'perl',
		       mode => 'module',
		      }) | _to_xhtml | _xpath('/html/body/p');
preproc('s/\A.+<!--results-->(.+)<!--end results-->.+\Z/$1/s');

template('[% ... %]<p><a href="[% link %]" shape="rect"><b>[% module %]</b></a><br clear="none" />[% ... %]<small>[% description %]</small><br clear="none" />[% ... %]<small><a href="[% ... %]" shape="rect">[% dist %]</a> - <span class="date">[% date %]</span> - <a href="/~[% ... %]" shape="rect">[% author %]</a></small>[% ... %]<!--end item-->');

extract;
append_url;
#print Dumper extresult;
ok(@{extresult()});
invoke_handler('CPAN::DBI');
my @r;
@r = CPAN::DBI->search_like(module => '%Perl%'); 
is(@r, 10);
CPAN::DBI->search_like(module => '%')->delete_all;
@r = CPAN::DBI->search_like(module => '%Perl%'); 
is(@r, 0);
