package FEAR::API::Closure;

use Spiffy -base;
use FEAR::API::SourceFilter;

use strict;
no warnings 'redefine';
our @EXPORT = qw(
		 _field
		 _chain
		 _alias

		 @field_subs
		 @chain_subs

		 _init
		 _init_field_subs
		 _init_chain_subs
		);

our @field_subs;
our @chain_subs;


use FEAR::API::Translate;

#================================================================================
# Closure generation
#================================================================================

sub _field() {
    my $package = caller;
    my ($field, $default) = @_;
    no strict 'refs';
    push @field_subs, $field;
#    print "field '$field' => $default\n";
    push @{$package.'::EXPORT_BASE'}, $field;

    *{;no strict 'refs';
      \*{"${package}::$field"}} =
	sub {
	    &__know_myself__;
	    $__this_field__ = $field;
	    &__translate_and_return__;
	    $self->{$field} = shift if defined $_[0];
	    if( not defined $self->{$field} ){
	      $self->{$field} = $default;
	    }
	    return $self->{$field};
	};

}


sub _chain() {
    my $package = caller;
    my ($field, $default) = @_;

    no strict 'refs';
    push @chain_subs, $field;
    push @{$package.'::EXPORT_BASE'}, $field;
#    print "chain '$field' => $default\n";

    *{;no strict 'refs';
      \*{"${package}::$field"}} =
	sub {
	    &__know_myself__;
	    $__this_field__ = $field;
	    &__translate_and_return_self__;
	    $self->{$field} = shift if defined $_[0];
	    if( not defined $self->{$field} ){
	      $self->{$field} = $default;
	    }
	    return $self;
	};
}


# Aliases are created for commonly-used subs that are tedious in name
sub _alias($$) {
    my $package = caller;
    my ($alias, $sub) = @_;
    no strict 'refs';
    *{;no strict 'refs';
      $package.'::'.$alias} = \&{$package.'::'.$sub};
    push @{$package.'::EXPORT_BASE'}, $alias;
}

sub _init {
    foreach my $s (@{$_[0]}){
      $self->$s();
    }
}

sub _init_field_subs {
    $self->_init(\@field_subs);
    $self;
}

sub _init_chain_subs {
    $self->_init(\@chain_subs);
    $self;
}


1;
__END__
