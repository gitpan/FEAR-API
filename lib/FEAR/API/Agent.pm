package FEAR::API::Agent;
use strict;
use Spiffy -base;
use FEAR::API::SourceFilter;
use WWW::Mechanize;
use Carp;
our @ISA = qw(WWW::Mechanize);

sub new() {
  my $self = super;
  $self->agent_alias('Windows IE 6');
  $self->cookie_jar({ file => "/tmp/fear-".time()."-cookies.txt" });
  $self->max_redirect(3);
  $self;
}

use Encode;
use HTML::Encoding 'encoding_from_http_message';
sub _convert_to_utf8 {
    if($self->res){
#	use Data::Dumper;
#	print Dumper $self->res;
	eval {
	    my $enc = encoding_from_http_message($self->res);
	    $self->{content} = decode($enc => $self->content);
	}
    }
}

sub force_content_type {
    $self->{forced_ct} = shift;
}

sub get_content {
  use Text::Iconv;
  my $url = shift;
  $self->get($url);
  if( $self->res->is_success ){
#      print $self->res->content_type,$/;
    if( $self->res->content_type =~ /text/o){
      $self->{ct} = $self->{forced_ct} if $self->{forced_ct};
      $self->_convert_to_utf8;
      # Since document is translated to UTF-8, so links MUST be re-extracted
      $self->_extract_links();
    }
    return $self->content;
  }
}

my %name_to_number = qw(url 0
			text 1
			name 2
			tag 3
			base 4
			attr 5
			referer 6
		       );

sub links {
  foreach my $link (@{$self->{links}}){
    $link->[0] = $link->url_abs()->as_string;
    $link->[6] = $self->uri; # referer
  }
  super;
}


chain_sub sort_links {
  @{$self->{links}} = 
      sort {
	  $_[0] ?
	      (
	       ref($_[0]) eq 'CODE' ?
	       $_[0]->($a, $b)
	       :
	       $a->[$name_to_number{$_[0]}] cmp $b->[$name_to_number{$_[0]}]
	       )
	      :
	      $a->[0] cmp $b->[0]
	  } $self->links;
}


chain_sub keep_links {
  my ($filter, $field);
  if(@_ == 2){
    $filter = $_[1];
    $field = $name_to_number{$_[0]};
  }
  else {
    $filter = $_[0];
    $field = 0;
  }
  @{$self->{links}} = grep {
      ref $filter eq 'CODE' ? $filter->($field) : $_->[$field] =~ /$filter/;
  } $self->links;
}

chain_sub remove_links {
  my ($filter, $field);
  if(@_ == 2){
    $filter = $_[1];
    $field = $name_to_number{$_[0]};
  }
  else {
    $filter = $_[0];
    $field = 0;
  }
  @{$self->{links}} = grep {
      not (
	   ref $filter eq 'CODE' ? $filter->($field) : $_->[$field] =~ /$filter/
	   );
  } $self->links;
}




1;
__END__
