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

# Below is stub documentation for your module. You better edit it!

=head1 NAME

FEAR::API::Filters - Named filters

=head1 DESCRIPTION

This package contains several preset named filters. You can use them
to clean or convert documents or results.

The filters include:


=head2 strip_html

  It strips html tags and turn them into whitespaces.

=head2 html_to_null

  It strips html tags and turn them into empty string;

=head2 remove_attributes

  It removes attributes in markups.

=head2 remove_commas

=head2 remove_leading_trailing_spaces, remove_lt_spaces

=head2 remove_newlines

=head2 decode_entities



=head1 COPYRIGHT

Copyright (C) 2006 by Yung-chung Lin (a.k.a. xern) <xern@cpan.org>

This package is free software; you can redistribute it and/or modify
it under the same terms as Perl i tself

=cut
