package FEAR::API::Prefetching;

use strict;
use Storable qw(dclone);
use LWP::UserAgent;
use IO::Socket;
use FEAR::API::Prefetching::Base;


sub new {
    bless {}, shift;
}


sub has {
    my $self = shift;
    my $url = shift;
    my $path = document_path($url);
    return -e $path and time - (stat($path))[9] < 60*60;
}

sub load_document {
    my $self = shift;
    my $url = shift;
    my $path = document_path($url);
    open my $f, '<', $path or die $!;
    local $/;
    return <$f>;
}

sub save_document {
    my $self = shift;
    my $url = shift;
    my $docref = shift;
    my $path = document_path($url);
    open my $f, '>', $path or die $!;
    print {$f} $$docref;
}

sub fetch {
    my $self = shift;
    my @links = @_;
    print Dumper \@links;
    my $ua = LWP::UserAgent->new();
    my $socket = IO::Socket::INET->new(
				       PeerAddr => '127.0.0.1',
				       PeerPort => '20203',
				       Proto => 'tcp') or die $!;
    while (my $link = shift @links){
	my $referer = $link->referer;
	my $link_digest = digest($link->url);
 	print "    ... Try prefetching   ", $link->url,$/;
 	print "         ", digest($link->url),$/;
	$socket->print($link->url, qq(\t), $link->referer, "\n");
    }
    $socket->close();

}


1;
