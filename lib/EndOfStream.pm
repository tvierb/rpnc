package EndOfStream;

# this is one of the things laying on the stack
# the ref string is the type
# the value is its value
# the formatter will have the job to decide how to print it

use strict;
use warnings;
use Carp;

sub new
{
	my ($class)  = @_;
	my $self = bless( {}, $class );
	return $self;
}

1;
