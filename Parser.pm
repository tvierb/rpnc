package Parser;

use strict;
use warnings;

use constant END_OF_STREAM => "end-of-stream";
use constant NUMBER => "number";
use constant OPERATOR => "operator";
use constant STRING => "string";
use constant SYMBOL => "symbol";
use constant UNKNOWN => "unknown";

# static function
sub next_atom
{
	my $stream = shift;
	$stream =~ s/^ //g;
	if (! length($stream))
	{
		return [{type => Parser->END_OF_STREAM, value => "moo"}, ""];
	}
	if ($stream =~ /^(-[0-9]+([\.][0-9]+)?)(.*)/)
	{
		return [{type => Parser->NUMBER, value => $1}, $3]; # negative number
	}
	elsif ($stream =~ /^([0-9]+([\.][0-9]+)?)(.*)/)
	{
		return [{type => Parser->NUMBER, value => $1}, $3]; # positive number
	}
	elsif ($stream =~ /^([\/\*\-\+])(.*)/)
	{
		return [{type => Parser->OPERATOR, value => $1}, $2]; # operator
	}
	elsif ($stream =~ /^(clr|clear|vars|q|dump|drop|d|swap|copy|cp)(.*)/)
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
