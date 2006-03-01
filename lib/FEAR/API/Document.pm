package FEAR::API::Document;

use strict;
use Carp;
use Spiffy -base;
use FEAR::API::Closure;
use File::MMagic;
use FEAR::API::SourceFilter;
use Encode;
use Text::Iconv;
use MIME::Base64;
use Digest::MD5 qw(md5);

chain 'document';
alias content => 'document';
field 'title';
field 'type';


sub length {
  CORE::length($self->{document});
}
alias size => 'length';

sub as_string {
  $self->{document};
}

sub is_utf8 {
  Encode::is_utf8($self->{document});
}

chain_sub utf8_on {
  Encode::_utf8_on($self->{document});
}

chain_sub utf8_off {
  Encode::_utf8_off($self->{document});
}

chain_sub iconv_from {
  my $converter =
    Text::Iconv
    ->new((shift() || croak "please input encoding"), 'UTF-8') or croak $!;
  $self->{document} = $converter->convert($self->{document});
  $self->utf8_on;
}



chain_sub append {
  $self->{document} .= shift;
  return $self;
}

chain_sub clear {
  $self->{document} = undef;
  return $self;
}

sub type {
    File::MMagic->new->checktype_contents($self->{document});
}


# $self->diff(\$text);
# $self->diff($filename);
# $self->diff(\$text, \$output);
# $self->diff($filename, $output_file);
sub diff {
}


sub guess_encoding {
}

######################################################################
# Compression / Decompression
######################################################################

use Compress::Zlib;
chain_sub try_compress {
  my $td = Compress::Zlib::memGzip $self->{document};
  $self->{document} = $td if $td;
}

chain_sub try_decompress {
  my $td = Compress::Zlib::memGunzip $self->{document};
  $self->{document} = $td if $td;
}

######################################################################
# MIME methods
######################################################################

sub MIME_encode {
    $self->utf8_off;
    $self->{document} = encode_base64 $self->{document};
}

sub MIME_decode {
  $self->{document} = decode_base64 $self->{document};
  $self->utf8_on;
}

######################################################################
# Testing methods
######################################################################

sub match {
  my $pattern = shift;
  $self->{document} =~ /$pattern/;
}

sub title_is {
}

sub title_like {
}

sub title_unlike {
}

sub content_is {
  $self->{document} eq shift;
}

sub content_contains {
  my $pattern = shift;
  $self->{document} =~ /$pattern/;
}

sub content_lacks {
  my $pattern = shift;
  $self->{document} !~ /$pattern/;
}

sub content_like {
}

sub content_unlike {
}

sub has_tag {
}

sub has_tag_like {
}

######################################################################
# Shell-like methods
######################################################################

sub sort($&) {
  my $self = shift;
  my $code = shift;
  if(ref $code eq 'CODE'){
    return join qq/\n/, CORE::sort{$code->($_)} split /\n/, $self->{document};
  }
  else {
    return join qq/\n/, CORE::sort split /\n/, $self->{document};
  }
}

sub map($&) {
  my $self = shift;
  my $code = shift;
  if(ref $code eq 'CODE'){
    return join qq/\n/, CORE::map{$code->($_)} split /\n/, $self->{document};
  }
  elsif(ref $code eq 'Regexp') {
    return join qq/\n/, CORE::map{m($code)} split /\n/, $self->{document};
  }
}

sub grep($&) {
  my $self = shift;
  my $code = shift;
  if(ref $code eq 'CODE'){
    return join qq/\n/, CORE::grep{$code->($_)} split /\n/, $self->{document};
  }
  elsif(ref $code eq 'Regexp') {
    return join qq/\n/, CORE::grep{m($code)} split /\n/, $self->{document};
  }
}

sub uniq {
  my %h;
  return join qq/\n/, grep{Encode::_utf8_off $_;
			   !$h{md5 $_}++} split /\n/, $self->{document};
}

########################################
# d is for destructive
####################
chain_sub d_map {
  $self->{document} = $self->map(@_);
}

chain_sub d_grep {
  $self->{document} = $self->grep(@_);
}

chain_sub d_sort {
  $self->{document} = $self->sort(@_);
}

chain_sub d_uniq {
  $self->{document} = $self->uniq(@_);
}


######################################################################
# Conversion methods
######################################################################

use File::Temp qw/ :POSIX /;
use XML::XPath;
use XML::XPath::XMLParser;


sub _convert_via_tmpfiles {
    my $command = shift;
    my $outputfile = shift;
    my ($fh, $file) = tmpnam();
    close $fh;
    if($outputfile){
	eval "`$command $outputfile`";
	$self->{document} = io(eval $outputfile)->all;
    }
    else {
	$self->{document} = eval "`$command`";
    }
    $self->try_to_utf8;
    unlink $file;
}

sub html_to_xhtml {
    my ($fh, $file) = tmpnam();
    print {$fh} $self->{document};
    close $fh;
    local $/;
    $self->{document} = `tidy -q -utf8 -asxhtml -numeric < $file`;
    unlink $file;
}


chain_sub xpath {
    my $t;
    my $xp = XML::XPath->new(xml => $self->{document});
    my $cnt = 0;
    foreach (@_){
	my $nodeset = $xp->find($_);
	foreach my $node ($nodeset->get_nodelist) {
	    $t .=
		(@_ > 1 ? "[% PATH_$cnt $_ %]\n" : undef).
		XML::XPath::XMLParser::as_string($node).
		"\n".
		(@_ > 1 ? "[% END %]" : undef).
		"\n\n"
		;
	    $cnt++;
	}
    }
    $self->{document} = $t;
}


1;

__END__
