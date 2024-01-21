package Operator;

# this is one of the things laying on the stack
# the ref string is the type
# the value is its value
# the formatter will have the job to decide how to print it

use strict;
use warnings;
use Carp;

sub new
{
	my ($class, $value, $info) = @_;
	confess("value is not defined") unless defined $value;
	my $self = bless( {}, $class );
	$self->{ value } = $value;
	$self->{ info } = $info // "Some operator";
	return $self;
}

sub value
{
	my $self = shift;
	return $self->{ value };
}

1;
