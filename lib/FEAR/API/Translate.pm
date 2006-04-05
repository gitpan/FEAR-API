package FEAR::API::Translate;

use strict;
use Switch;
use Spiffy -base;
use FEAR::API::Translate::Backend;

if($ENV{TRANSLATE_FEAR}){
    print '
use LWP::UserAgent;
my @url;
my $ua = LWP::UserAgent->new;
';
}

sub __translate(@) {
    my $self = shift;
    my $subname = shift;
    no strict 'refs';
    print 'FEAR::API::Translate::Backend::'.$subname,$/;
    &{'FEAR::API::Translate::Backend::'.$subname};
}


1;
