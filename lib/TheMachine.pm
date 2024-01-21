package TheMachine;

use strict;
use warnings;
use Data::Dumper;
use Element;

use constant SAVEFILE_VERSION => 2;
sub new
{
	my $classname = shift;
	my %params = @_;
	my $self = bless({}, $classname);

	$self->{ stack } = [];
	$self->{ defs  } = {};
	$self->{ flags } = {}; # TODO config vars (output format)
	$self->{ errors} = []; # collected errors, cleared when printed
	$self->{ loop  } = 4e4;
	return $self;
}

# --------------------------------------------------------
# push or better unshift element to stack
sub push
{
	my ($self, $atom) = @_;
	unshift( @{ $self->{ stack } }, $atom );
}

# --------------------------------------------------------
sub shutdown
{
}

# --------------------------------------------------------
sub error
{
	my ($self, $message) = @_;
	CORE::push( @{ $self->{errors} }, $message );
}


# --------------------------------------------------------
# add two numbers of type Parser->NUMBER
sub add
{
	my $self = shift;
	my %params = @_;
	my $invert = defined($params{"invert"}) && $params{invert} ? 1 : 0;
	if ($self->has_two_numbers())
	{
		my $b = shift( @{ $self->{ stack } } );
		$b->{value} = -1 * $b->{value} if $invert;
		my $a = shift( @{ $self->{ stack } } );
		$self->push( Element->new( Element->NUMBER, $a->{ value } + $b->{ value } ) );
	}
	else {
		$self->error("stack underflow");
	}
}

# --------------------------------------------------------
sub mul
{
	my $self = shift;
	my %params = @_;
	my $invert = defined($params{"invert"}) && $params{invert} ? 1 : 0;
	if ($self->has_two_numbers())
	{
		my $b = shift( @{ $self->{ stack } } ); # consume atoms
		my $a = shift( @{ $self->{ stack } } ); # consume
		if ($invert)
		{
			if ($b->{ value } == 0)
			{
				$self->error("division by zero");
			}
			else {
				$self->push( Element->new( Element->NUMBER, $a->{ value } / $b->{ value } ));
			}
		}
		else {
			$self->push( Element->new( Element->NUMBER, $a->{ value } * $b->{ value } ));
		}
	}
	else {
		$self->error("stack underflow");
	}
}

# --------------------------------------------------------
# -- : --
# TODO implement test
sub drop
{
	my $self = shift;
	if ($self->count_stack() > 0)
	{
		shift( @{ $self->{ stack } } ); # consume
	}
}

# index : element at index
# TODO implement test
sub get_at_index
{
	my ($self, $index) = @_;
	return $self->{ stack }->[ $index ]; # can be undefined

	#print STDERR "index=$index\n";
	#if (scalar @{ $self->{ stack }} >= ($index + 1))
	#{
	#	return $self->{ stack }->[ $index ];
	#}
}

# TODO implement test
sub pop
{
	my $self = shift;
	my $elem = $self->get_at_index( 0 );
	if (defined($elem))
	{
		$self->drop();
	}
	return $elem;
}

sub count_stack
{
	my $self = shift;
	return scalar @{ $self->{ stack } };
}

# --------------------------------------------------------
# copy stack element idx and push it on stack
#
# #2  3.14
# #1  234
# #0  0.3
#
# now: "3 cp":
#
# #3  15
# #2  12
# #1  3
# #0  cp
#
# -> will take the value of the element that is on index 3 after removing "cp" and "3".
sub copy
{
	my $self = shift;
	my $index = $self->pop();
	if (! $index->is_number())
	{
		$self->error("expected index to element on stack but popped a non-number");
		return;
	}
	$index = $index->value();
	my $elem = $self->get_at_index( $index );
	if (! defined($elem))
	{
		$self->error("no element on stack at index $index");
		return;
	}
	my %hash_copy = %{ $elem };
	$self->push( \%hash_copy );
}


# --------------------------------------------------------
sub has_two_numbers
{
	my $self = shift;
	if ($self->count_stack() < 2)
	{
		$self->error( "not two things on the stack" );
		return 0;
	}

	foreach my $id ( (0, 1) )
	{
		my $thing = $self->{ stack }->[ $id ];
		unless ($thing->is_number())
		{
			$self->error( "element #$id is not a number" );
			return 0;
		}
	}
	return 1;
}


# --------------------------------------------------------
sub operate
{
	my ($self, $atom) = @_;
	#my $type = $atom->{ type };
	if ($atom->is_number() || $atom->is_string())
	{
		$self->push( $atom );
		return;
	}
	elsif ($atom->is_symbol())
	{
		# Symbols are internal symbols/operators or values or programs defined by the user.
		# 1. check internal symbols like + - copy clear dup def sto end:
		my $symbol = $atom->{ value };
		if ($symbol eq "+")
		{
			$self->add();
			return;
		}
		elsif ($symbol eq "-")
		{
			$self->add( invert => 1 );
			return;
		}
		elsif ($symbol eq "*")
		{
			$self->mul();
			return;
		}
		elsif ($symbol eq "/")
		{
			$self->mul( invert => 1 );
			return;
		}
		elsif (($symbol eq "drop") || ($symbol eq "d"))
		{
			$self->drop();
			return;
		}
		elsif (($symbol eq "copy") || ($symbol eq "cp"))
		{
			$self->copy();
			return;
		}
		elsif ($symbol eq "swap")
		{
			if ($self->count_stack() >= 2)
			{
				my $b = $self->pop();
				my $a = $self->pop();
				$self->push( $b );
				$self->push( $a );
				return;
			}
		}
		elsif (($symbol eq "clear") || ($symbol eq "clr"))
		{
			$self->{ stack } = [];
			return;
		}

		# 2. or is it defined in our defs?
		elsif (defined( $self->{ defs }->{ $symbol } ))
		{
			# a list of Element objects
			# copy them on the stack:
			my $subroutine = $self->{ defs }->{ $symbol };
			foreach my $e (@$subroutine)
			{
				$self->push( $e );
			}
			return;
		}
		die("unknown symbol >$symbol<"); # die?
	}
	die("Unknown type >" . $atom->{ type } . "<");
}

# ----------------------------------------------------------------------------
sub show
{
	my $self = shift;

	my $defs = $self->{ defs };
	if (scalar keys %{ $defs })
	{
		my $s = "";
		map { $s .= "$_=" . $defs->{ $_ } . " " } sort keys %{ $defs };
		print "VARS: " . substr($s, 0, -1) . "\n";
	}
	
	print "Stack:\n";
	my $stack = $self->{ stack };
	# print "stack in wrong order :-) : " . Dumper($stack);
	my $number = scalar @{ $stack };
	
	for (my $i = $number - 1; $i >= 0; $i--)
	{
		my $atom = $stack->[ $i ];
		if ($atom->{type} eq Element->NUMBER)
		{
			printf("  %2s : %s\n", '#' . $i, $atom->{value}); # TODO add format
		}
		else {
			printf("  %2s : %s\n", '#' . $i, "unknown entity: " . Dumper($atom));
		}
	}
	print "  -empty-\n" unless $number;
	
	if (@{ $self->{ errors } } > 0)
	{
		map { print "ERROR: $_\n" } @{ $self->{ errors } };
		$self->{ errors } = [];
	}
	print "INPUT> ";
}

1;
