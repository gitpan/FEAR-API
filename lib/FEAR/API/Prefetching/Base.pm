package FEAR::API::Prefetching::Base;

use strict;
use Exporter::Lite;
use Digest::MD5 qw(md5_hex);

use File::Spec::Functions;
our @EXPORT = qw(
		 repos_path
		 digest
		 document_path
		 has
		 );

my $repos_path = '/tmp/fear-api/pf';

sub repos_path { $repos_path }

sub digest {
    md5_hex($_[0]);
}

sub document_path {
    my $url_digest = digest(shift);
    catfile(
	    $repos_path,
	    substr($url_digest, 0, 1),
	    substr($url_digest, 1, 1),
	    $url_digest);
}


sub has {
    my $path = document_path(shift);
    return -e $path and time() - (stat($path))[9] < 60*60;
}



1;
