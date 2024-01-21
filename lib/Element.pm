package Element;

# this is one of the things laying on the stack

use strict;
use warnings;
use Carp;

use constant END_OF_STREAM => "end-of-stream";
use constant NUMBER => "number";
use constant FUNCTION => "function";
use constant STRING => "string";
use constant SYMBOL => "symbol";
use constant ERROR   => "error";

sub new
{
	my ($class, $type, $value) = @_;
	confess("type is not defined") unless defined $type;
	confess("value is not defined") unless defined $value;
	my $self = bless( {}, $class );
	$self->{ type }  = $type;
	$self->{ value } = $value;
	return $self;
}

sub value
{
	my $self = shift;
	return $self->{ value };
}

sub type
{
	my $self = shift;
	return $self->{ type };
}

sub is_quit
{
	my $self = shift;
	return 0 unless $self->is( Element->SYMBOL );
       	return 1 if ($self->{ value } eq "quit") || ($self->{ value } eq "q");
	return 0;
}

sub is_help
{
	my $self = shift;
	return 0 unless $self->is( Element->SYMBOL );
	return 1 if $self->value() eq 'help';
	return 1 if $self->value() eq '?';
	return 0;
}

sub is_symbol
{
	my $self = shift;
	return 1 if $self->is( Element->SYMBOL );
	return 0;
}

sub is
{
	my $self = shift;
	my $type = shift;
	return $self->{ type } eq $type ? 1 : 0;
}

sub is_error
{
	my $self = shift;
	return $self->is( Element->ERROR );
}

sub is_number
{
	my $self = shift;
	return $self->is( Element->NUMBER );
}

sub is_string
{
	my $self = shift;
	return $self->is( Element->STRING );
}

sub is_end
{
	my $self = shift;
	return $self->is( Element->END_OF_STREAM );
}

1;
