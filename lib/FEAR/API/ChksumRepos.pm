package FEAR::API::ChksumRepos;

use strict;
use Carp;
use DB_File;
use Spiffy -Base;
use File::Temp qw/ :POSIX /;

field 'db_file';
field 'pool' => {};
field 'dbx';
field 'remove_on_destroy';

sub new() {
    my $self = bless {}, shift;
    my %opt = @_;
    $self->remove_on_destroy($opt{remove_on_destroy});
    $self->tie($opt{'file'});
    $self;
}

sub tie {
    my $file = shift;
    my $tmpfile = 
    $self->db_file( $file || File::Temp::tmpnam() || croak "Please specify one file" );
    $self->{'dbx'} =
	tie %{$self->{'pool'}}, 'DB_File', $self->{'db_file'},
	O_RDWR | O_CREAT, 0666, $DB_BTREE or croak $!;
}

sub add {
    my ($key, $value) = @_;
    $self->{pool}{$key} = ($value || 1) if $key;
}

sub value {
    my $key = shift;
    return $self->{pool}{$key} if $key;
}

sub del {
    my $key = shift;
    delete $self->{pool}{$key} if $key;
}

sub sync {
    $self->dbx->sync;
}

sub has {
    my $key = shift;
    return exists $self->{pool}{$key} if $key;
}

sub empty {
    $self->pool({});
    $self->sync;
}

sub remove {
    remove $self->db_file;
}

sub DESTROY {
    unlink $self->db_file if $self->{remove_on_destroy};
}

1;
