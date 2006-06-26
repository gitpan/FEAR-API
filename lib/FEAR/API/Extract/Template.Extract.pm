package FEAR::API::Extract::Template::Extract;

use strict;
use base 'FEAR::API::Extract::Base';

use Template::Extract;
sub init {
    Template::Extract->new;
}

sub extract {
    my $self = shift;
    my $template_ref = shift;
    my $document_ref = shift;
    my $template = '[% FOREACH record %]'.$$template_ref.'[% END %]';
    my $r = $self->{extor}->extract($template, $$document_ref);
    my @r;
    if (ref($r) && ref $r eq 'HASH') {
	# Flatten data into a list.
	foreach my $k (keys %$r) {
	    push @r, @{$r->{$k}};
	}
	$r = \@r;
    }
    return $r;
}

1;
