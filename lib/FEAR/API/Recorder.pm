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
sub start_recorder {
    my %arg = @_;
    print Dumper \%arg;
    my $proxy = HTTP::Proxy->new();
    $proxy->port($arg{port}) if $arg{port};
    $proxy->host($arg{host}) if $arg{host};

    my $agent = new HTTP::Recorder;
    $agent->file($arg{outputfile}) if $arg{outputfile};

    $proxy->agent( $agent );
    $proxy->start();
}


 
1;
