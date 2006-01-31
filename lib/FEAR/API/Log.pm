package FEAR::API::Log;

use strict;
use Spiffy -base;
use FEAR::API::SourceFilter;
use FEAR::API::Closure;

chain_sub start_logging {
    my $filename = shift;
    if($filename){
	$self->logger(io($filename));
    }
    else {
	$self->logger(io('-')->stdout);
    }
}

chain_sub log_this {
    $self->logger->append(shift()."\n");
}




1;
