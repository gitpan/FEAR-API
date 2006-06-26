package FEAR::API::Extract::Regexp::GlobalBind;


use strict;
use base 'FEAR::API::Extract::Base';

use Regexp::Bind qw(global_bind);

sub init {
}

sub extract {
    my $self = shift;
    my $template_ref = shift;
    my $document_ref = shift;

    return global_bind($$document_ref, qr($$template_ref) )
}

1;
