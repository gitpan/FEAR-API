package FEAR::API::Extract::Text::CSV;

use strict;
use base 'FEAR::API::Extract::Base';

use Text::CSV;

sub init {
    Text::CSV->new();
}

sub extract {
    my $self = shift;
    my $template_ref = shift;
    my $document_ref = shift;

    my $csv = $self->{extor};

    my $i = 0;
    my @field_name;
    if ($csv->parse($$template_ref)) {
	@field_name = $csv->fields;
    }

    my $r;
    foreach my $line (split /\n+/, $$document_ref) {
	if ($csv->parse($line)) {
	    my $count = 0;
	    for my $column ($csv->fields) {
		$r->[$i]->{@field_name ? $field_name[$count] : $count} = $column;
		$count++;
	    }
	}
	$i++;
    }
    return $r ;
}

1;

