package ElementFactory;

# this is one of the things laying on the stack

use strict;
use warnings;
use Element;

# sub new
# {
# my ($class, $type, $value) = @_;
# die("I need type")  unless defined( $type );
# die("I need value") unless defined( $value );
# return new Element( $type, $value );
# }

sub number
{
	my $value = shift;
	return Element->new( Element->NUMBER, $value );
}

sub operator
{
	my $value = shift;
	return Element->new( Element->OPERATOR, $value );
}

sub string
{
	my $value = shift;
	return Element->new( Element->STRING, $value );
}

sub symbol
{
	my $value = shift;
	return Element->new( Element->SYMBOL, $value );
}

sub end
{
	my $value = shift;
	return Element->new( Element->END_OF_STREAM, $value );
}

1;
