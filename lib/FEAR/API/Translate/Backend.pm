package FEAR::API::Translate::Backend;

use strict;

sub __quote(@) {
    map{"'$_'"} @_;
}

sub __listify(@){
    join q/,/, @_;
}

sub __eol() {
    ';'
}

sub __paren {
    ('(', @_ ,')');
}

sub __gencode(@){
    print join( q//, @_).$/;
}


sub url {
    __gencode('push @url,',
	      __listify(__quote(@_)),
	      __eol) if @_;
}



sub fetch {
    @_ ?
	__gencode('$ua->get', __paren(__quote($_[0])), __eol)
	:
	__gencode('$ua->get(shift(@url))'.__eol);
}

#sub document {
#}


sub AUTOLOAD{ 
}
1;
