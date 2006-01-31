package FEAR::API::Link;
use strict;
no warnings 'redefine';
use Spiffy -base;
use WWW::Mechanize::Link;
our @ISA = qw(WWW::Mechanize::Link);


package WWW::Mechanize::Link;

use strict;
no warnings 'redefine';
use FEAR::API::SourceFilter;

sub new;
sub new{
    my $class = shift;
    my %p;
    my ($url,$text,$name,$tag,$base,$attrs,$referer);

    if ( ref $_[0] eq 'HASH' ) {
        %p =  %{ $_[0] }; 
        $url  = $p{url};
        $text = $p{text};
        $name = $p{name};
        $tag  = $p{tag};
        $base = $p{base};
        $attrs = $p{attrs};
	$referer = $p{referer};
    }
    else {
        ($url,$text,$name,$tag,$base,$attrs,$referer) = @_; 
    }

    my $self = [$url,$text,$name,$tag,$base,$attrs,$referer];

    bless $self, $class;

    return $self;
}

sub referer {
  $self->[6] = shift if @_;
  $self->[6];
}

sub is_local_link {
  my $base = $self->base->as_string;
  $self->url =~ m(^\w+://\Q$base\E);
}


1;
__END__
