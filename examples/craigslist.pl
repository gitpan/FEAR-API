#!/opt/local/bin/perl

use strict;
use FEAR::API -base;

my $output_file = io('output.craigslist');

url('http://www.craigslist.org/cgi-bin/search?areaID=1&subAreaID=0&query=perl&catAbbreviation=jjj');
fetch;
template('<p>&nbsp;[% date %]&nbsp;&nbsp;&nbsp;<a href="[% ... %]>[% title %]</a><font size="-1"> ([% location %])</font> &lt;&lt;<i><a href="[% ... %]">[% category %]</a></i></p>');
extract;
invoke_handler(sub {
		   print Dump $_;
		   $output_file->println(Dump $_);
	       });

