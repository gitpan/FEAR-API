package FEAR::API::Recorder;


$|++;
use strict;
use Spiffy -base;
use FEAR::API::Closure -base;
our @EXPORT = qw(
	       start_recorder
	       );

use HTTP::Proxy;
use HTTP::Recorder;

# level
# 0 => FEAR::API
# 1 => WWW::Mechanize
# 2 => LWP::UserAgent
# 3 => LWP::Simple

use Data::Dumper;
use Switch;
require FEAR::API::Recorder::LWP_Simple;
require FEAR::API::Recorder::LWP_UserAgent;
require FEAR::API::Recorder::FEAR_API;
 
sub start_recorder {
    my %arg = @_;
    print Dumper \%arg;
    my $proxy = HTTP::Proxy->new();
    $proxy->port($arg{port} || 3128);
    $proxy->host($arg{host}) if $arg{host};

    my $agent = new HTTP::Recorder;
    $agent->file($arg{outputfile}) if $arg{outputfile};

    $arg{level} ||= 0;
    my $logger;
    switch($arg{level}){
	case 3 {
	    $logger = FEAR::API::Recorder::LWP_Simple->new;
	}
	case 2 {
	    $logger = FEAR::API::Recorder::LWP_UserAgent->new;
	}
	case 0 {
	    $logger = FEAR::API::Recorder::FEAR_API->new;
	}
    }
    $agent->logger($logger) if $logger;

    $proxy->agent( $agent );
    $proxy->start();
}


 
1;
