package FEAR::API::Prefetching::Server;

use strict;
use LWP::UserAgent;
use Net::Server::PreFork;
use FEAR::API::Agent;
use FEAR::API::Prefetching::Base;

our @ISA = qw(
	      FEAR::API::Prefetching::Base
	      Net::Server::PreFork);

use Exporter::Lite;
our @EXPORT = qw(start_server);



use Parallel::ForkManager;
sub process_request {
    my $ua = FEAR::API::Agent->new();
    $ua->timeout(10);

    open STDERR, '>', '/dev/null' or die $!;
    my $pm = new Parallel::ForkManager(5);

    while(my $line = <STDIN>){
	$line =~ s/\r?\n$//;
	my ($url, $referer) = split /\t/, $line;
	next if -e document_path($url);
# 	print "($url, $referer)\n";

	{
	    my $pid = $pm->start and next;

	    $ua->add_header(Referer => $referer) if $referer;
	    $ua->get_content($url);
	    $ua->delete_header('Referer') if $referer;

	    if (open my $output, '>', document_path($url)) {
		print {$output}  $ua->content;
# 		print "OK\n";
	    }
	    $pm->finish;
	}
    }
    $pm->wait_all_children();
}

sub start_server {
    __PACKAGE__->run();
}


1;
