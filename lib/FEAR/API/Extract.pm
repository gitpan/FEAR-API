package FEAR::API::Extract;

use strict;
use utf8;

use Switch;
use Template::Extract;
use Regexp::Bind qw(bind global_bind);
use Data::Dumper;

sub new {
    my $class = shift;
    my $method = shift;
    if(ref($_[0])){
	$method = shift;
    }
    else {
    }
    bless {
	method => $method,
	@_
    } => $class;
}

sub new_all {
    my %e =
	map { $_ => __PACKAGE__->new($_) } 
    qw(
       Regexp::GlobalBind
       Template::Extract
       ),
       ;
}

my $te = Template::Extract->new;
sub extract {
    my $self = shift;
    my %arg = @_;
    my $template = $arg{template};
    my $document = $arg{document};
    my $method = $arg{extmethod};
    my $r;

    switch($method || $self->{method}){
	case 'Template::Extract' {
	    $template = '[% FOREACH record %]'.$template.'[% END %]';
	    $r = $te->extract($template, $document);
	    my @r;
	    if(ref($r) && ref $r eq 'HASH'){
		# Flatten data into a list.
		foreach my $k (keys %$r){
		    push @r, @{$r->{$k}};
		}
		$r = \@r;
	    }
	}
	case 'Regexp::GlobalBind' {
	    $r = global_bind($document, qr($template)s );
	}
	else {
	    die "Unknown extraction method is given.\n";
	}
    }
    $r;
}

1;
