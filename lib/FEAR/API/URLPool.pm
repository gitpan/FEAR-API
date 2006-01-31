package FEAR::API::URLPool;

use strict;
use Carp;
use DB_File;
use Spiffy -Base;
use File::Temp qw/ :POSIX /;
use DB_File;

field 'db_file';
field 'pool' => {};
field 'dbx';

sub new() {
    my $self = super;
    $self->tie;
    $self;
}

sub tie {
    my $tmpfile = tmpnam();
    $self->db_file(shift|| $tmpfile || croak "Please specify one file");
    $self->{dbx} =
	tie %{$self->{pool}}, 'DB_File', $self->{db_file},
	O_RDWR|O_CREAT, 0666, $DB_BTREE;
}

sub add {
    $self->{pool}{shift()} = 1 if $_[0];
}

sub sync {
    $self->dbx->sync;
}

sub has {
    exists $self->{pool}{shift()};
}

sub empty {
    $self->pool({});
    $self->sync;
}

sub DESTROY {
    unlink $self->db_file;
}

1;
