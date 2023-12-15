package StackElement;

# this is one of the things laying on the stack

use strict;
use warnings;

use constant END_OF_STREAM => "end-of-stream";
use constant NUMBER => "number";
use constant OPERATOR => "operator";
use constant FUNCTION => "function";
use constant STRING => "string";
use constant SYMBOL => "symbol";
use constant UNKNOWN => "unknown";

sub new
{
	my $class = shift;
	my %params = @_;
	my $self = bless( {}, $class );
	die("I need type= and value=") unless defined( $params{"type"} ) && defined( $params->{ value });
	$self->{ type }  = $type;
	$self->{ value } = value;
	return $self;
}

sub is_op_quit
{
	my $self = shift;
	return unless $self->{ type } eq StackElement->OPERATOR;
	return unless (($self->{ value } eq "quit") || ($self->{ value } eq "q"));
	return 1;
}

sub is_number
{
	my $self = shift;
	return 1 if $self->{ type } eq StackElement->NUMBER;
}

1;
