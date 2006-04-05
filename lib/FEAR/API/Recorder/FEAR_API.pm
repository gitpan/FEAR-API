package FEAR::API::Recorder::FEAR_API;

use strict;
use HTTP::Recorder::Logger;
our @ISA = qw( HTTP::Recorder::Logger );


sub Log {
    my $self = shift;
    my $function = shift;
    my $args = shift || '';

    return unless $function;
    my $line = "$function($args);\n";

    my $scriptfile = $self->{'file'};
    open (SCRIPT, ">>$scriptfile");
    print SCRIPT $line;
    close SCRIPT;
}


sub GotoPage {
    my $self = shift;
    my %args = (
		url => "",
		@_
		);

    $self->Log("fetch", "'$args{url}'");
}


sub FollowLink {
    my $self = shift;
    my %args = (
	text => "",
	index => "",
	@_
	);

    if ($args{text}) {
	$args{text} =~ s/"/\\"/g;
	$self->Log("follow_link", 
		   "text => '$args{text}', n => '$args{index}'");
    } else {
	$self->Log("follow_link", 
		   "n => '$args{index}'");
    }
}

1;
