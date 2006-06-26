package FEAR::API::Extract::Base;

sub new {
    my $class = shift;
    bless { extor => $class->init() } => $class;
}

sub init {
    die "Please override this method in subclasses";
}

sub compile {
    die "Please override this method in subclasses";
}

sub extract {
    die "Please override this method in subclasses";
}


1;
