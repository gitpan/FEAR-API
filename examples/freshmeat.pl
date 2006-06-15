#!/opt/local/bin/perl

use strict;
use FEAR::API -base;


url('http://freshmeat.net/random/');
fetch;
template('<b><font size="+1">[% project_name %] - Default branch</font></b><br>[% ... %]<b>About:</b><br>[% about %]<p>');
extract;
result_filter('$_->{about} =~ s/[\r\n\t]//g');
print Dump extresult;
