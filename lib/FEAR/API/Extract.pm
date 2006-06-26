package FEAR::API::Extract;

use strict;
use utf8;

use Data::Dumper;
use File::Spec::Functions qw(catfile splitpath);

my $extractor_path = __FILE__;
$extractor_path =~ s/\.pm$//o;


sub new {
    my $class = shift;
    my $method = shift;

    my $extractor_file = catfile($extractor_path, $method) . '.pm';
    $extractor_file =~ s/::/./go;
    require $extractor_file;

    my $extractor_package = 'FEAR::API::Extract::'.$method;

    my $r = bless {
		   method => $method,
		   extor => $extractor_package->new(),
		  } => $class;
    return $r;
}

sub new_all {
    return
	map { $_ => __PACKAGE__->new($_) } 
        map {
		$_ = (splitpath($_))[2];
		s/\.pm$//o;
		s/\./::/go;
		$_
        }
	grep{ !m(/Base\.pm$)o }
        glob catfile($extractor_path, '*.pm');
}

sub extract {
    my $self = shift;
    my %arg = @_;
    my $template = $arg{template};
    my $document = $arg{document};
    my $r;

    $r = $self->{extor}->extract(\$template, \$document);
    return $r;
}

1;
