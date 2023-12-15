package Parser;

# TODO the operators/functions clear|clr|vars|q»+|-... should be defined in TheMachine object with their regexps
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
	if (defined( $params{"operators"} ))
	{
		my @regexps = ();
		foreach my $op ( @{ $params{"operators"} } )
		{
			$self->add_operator( $op );
		}
	}
	return $self;
}

sub add_operator
{
	my $self = shift;
	my $op = shift;
	$op =~ s/([^a-zA-Z0-9])/\\$1/g; # escape + - / *
	push( @{ $self->{ regexp_operators }}, $op );
}

sub ops_regexp
{
	my $self = shift;
	return join("|", @{ $self->{ regexp_operators } } );
}

sub as_number
{
	my $self = shift;
	my $what = shift;
	return {type => Parser->NUMBER, value => $what};
}

# non static function
sub next_atom
{
	my $self = shift;
	my $stream = shift;
	$stream =~ s/^ //g;
	my $opreg = $self->ops_regexp();
	if (! length($stream))
	{
		return [{type => Parser->END_OF_STREAM, value => "moo"}, ""];
	}
	if ($stream =~ /^(-[0-9]+([\.][0-9]+)?)(.*)/)
	{
		return [ $self->as_number( $1 ), $3]; # negative number
	}
	elsif ($stream =~ /^([0-9]+([\.][0-9]+)?)(.*)/)
	{
		return [ $self->as_number( $1 ), $3]; # positive number
	}
	#elsif ($stream =~ /^([\/\*\-\+])(.*)/)
	#{
	#	return [{type => Parser->OPERATOR, value => $1}, $2]; # operator
	#}
	elsif (defined($opreg) && ($stream =~ /^($opreg)(.*)/))
	{
		return [{type => Parser->OPERATOR, value => $1}, $2]; # internal operation
	}
	elsif ($stream =~ /^"([^"]*)"(.*)/)
	{
		return [{type => Parser->STRING, value => $1}, $2]; # string object
	}
	elsif ($stream =~ /^'([^']*)'(.*)/)
	{
		return [{type => Parser->STRING, value => $1}, $2]; # string object
	}
	elsif ($stream =~ /^([a-zA-Z][a-zA-Z0-9_]*)(.*)/)
	{
		return [{type => Parser->SYMBOL, value => $1}, $2]; # vars/symbol
	}
	return [{type => Parser->UNKNOWN, value => $stream}, ""];
}
1;
