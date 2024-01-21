package Parser;

# the parser's job is to fetch characters from input and put things on the stack or commands to the command list/interpreter
use strict;
use warnings;
use Number;
use String;
use Operator;
use EndOfStream;

sub new
{
	my $class = shift;
	my %params = @_;
	my $self = bless( {}, $class );
	$self->{ stream } = '';
	return $self;
}

sub set_stream
{

	my ($self, $stream) = @_;
	$stream =~ s/^ //g;
	$self->{ stream } = $stream;
}


# non static function
# returns next Element and the rest of the stream
# returns Element->END_OF_STREAM when nothing is left
# 20231231: all except numbers and strings are SYMBOLs
sub next_atom
{
	my $self = shift;
	my $stream = $self->{ stream }; # string
	$stream =~ s/^\s+//g;
	if (! length($stream))
	{
		$self->{ stream } = '';
		return EndOfStream->new();
	}
	if ($stream =~ /^(-[0-9]+([\.][0-9]+)?)(.*)/)
	{
		$self->{ stream } = $3;
		return Number->new( $1 ); # negative number
	}
	elsif ($stream =~ /^([0-9]+([\.][0-9]+)?)(.*)/)
	{
		$self->{ stream } = $3;
		return Number->new( $1 ); # positive number
	}
	elsif ($stream =~ /^"([^"]*)"(.*)/)
	{
		$self->{ stream } = $2;
		return String->new( $1 ); # string object
	}
	elsif ($stream =~ /^'([^']*)'(.*)/)
	{
		$self->{ stream } = $2;
		return String->new( $1 ); # string object
	}
	elsif ($stream =~ /^([\+\-\*\/]{1})(.*)/)
	{
		$self->{ stream } = $2;
		return Operator->new( $1 ); # symbol
	}
	elsif ($stream =~ /^([a-zA-Z][a-zA-Z0-9_]*)(.*)/)
	{
		$self->{ stream } = $2;
		return Operator->new( $1 ); # symbol? variablename? subroutine name? I do not know by now
	}
	else {
		print "ERROR: Cannot get next element from stream '$stream'. Discaroding.\n";
		$self->{ stream } = '';
	}
	return EndOfStream->new();
}

1;
