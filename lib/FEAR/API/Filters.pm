package FEAR::API::Filters;

use strict;
use utf8;
use Carp;
use Spiffy -base;
use Data::Dumper;
use FEAR::API::SourceFilter;
use Regexp::Common qw(whitespace);
our @EXPORT = qw($filter $filter_source);

field 'filter' => {};
field 'filter_source' => {};

sub create_filter;

my $prefix = 'sub { local $_ = shift; ';
my $postfix = '$_ }';

#================================================================================
filter strip_html {
    s/(?:<[^>]*>)+/ /g;
    s/$RE{ws}{crop}//g;
}

#================================================================================
filter html_to_null {
    s/(?:<[^>]*>)+//g;
    s/$RE{ws}{crop}//g;
}

#================================================================================
filter remove_attributes {
    s/<\s*(\w+)\s+[^>]*>/<$1>/g;
}

#================================================================================
filter remove_commas {
    s/,//go;
}

#================================================================================
filter remove_leading_trailing_spaces {
   s/$RE{ws}{crop}//g;
}

#================================================================================
filter remove_lt_spaces {
   s/$RE{ws}{crop}//g;
}

#================================================================================
filter remove_newlines {
   s/\n//go;
}

#================================================================================
use HTML::Entities;
filter decode_entities {
   decode_entities($_);
}

sub create_filter() {
  my $package = caller;
  my ($field, $snippet) = @_;
  my $source = $prefix . $snippet . $postfix;
  my $sub = eval $source;
  croak $@ if $@;
  no strict 'refs';
  ${"FEAR::API::Filters::filter_source"}->{$field} = $source;
  ${"FEAR::API::Filters::filter"}->{$field} = $sub;
}



1;
__END__
