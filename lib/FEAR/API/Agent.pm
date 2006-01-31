package FEAR::API::Agent;
use strict;
use Spiffy -base;
use FEAR::API::SourceFilter;
use WWW::Mechanize;
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
    my $enc = encoding_from_http_message($self->res);
    $self->{content} = decode($enc => $self->content);
}

sub get_content {
  use Text::Iconv;
  my $url = shift;
  $self->get($url);
  if( $self->res->is_success ){
    $self->_convert_to_utf8;
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
	    } @{$self->{links}}
}


chain_sub keep_links {
  @{$self->{links}} = grep {
    @_ == 2 ?
      $_->[$name_to_number{$_[0]}] =~ /$_[1]/
	:
	  $_->[0] =~ /$_[0]/;
  } @{$self->{links}};
}

chain_sub remove_links {
  @{$self->{links}} = grep {
    @_ == 2 ?
      $_->[$name_to_number{$_[0]}] !~ /$_[1]/
	:
	  $_->[0] !~ /$_[0]/;
  } @{$self->{links}};
}




1;
__END__
