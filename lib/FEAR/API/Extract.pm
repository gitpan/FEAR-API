package FEAR::API::Extract;

use strict;
use utf8;

use Switch;
use Template::Extract;
use Regexp::Bind qw(bind global_bind);
use Text::CSV;
use Data::Dumper;

sub new {
    my $class = shift;
    my $method = shift;
    if(ref($_[0])){
	$method = shift;
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
       Text::CSV
       ),
       ;
}

my $te = Template::Extract->new;
my $csv = Text::CSV->new;

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
	case 'Text::CSV::Array' {
	    my $i = 0;
	    foreach my $line (split /\n+/, $document){
		if($csv->parse($line)){
		    for my $column ($csv->fields){
			push @{$r->[$i]}, $column;
		    }
		}
		$i++;
	    }
	    $r ;
	}
	case /^Text::CSV(?:::Hash)?$/ {
	    my $i = 0;
	    my @field_name;
	    if($csv->parse($template)){
		@field_name = $csv->fields;
	    }
	    foreach my $line (split /\n+/, $document){
		if($csv->parse($line)){
		    my $count = 0;
		    for my $column ($csv->fields){
			$r->[$i]->{@field_name ? $field_name[$count] : $count} = $column;
			$count++;
		    }
		}
		$i++;
	    }
	    $r ;
	}
	case 'XML::XPath' {
	}
	else {
	    die "Unknown extraction method is given.\n";
	}
    }
    $r;
}

1;
