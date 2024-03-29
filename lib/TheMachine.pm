package TheMachine;

use strict;
use warnings;
use Data::Dumper;
use Number;
use String;
use Operator;

use constant SAVEFILE_VERSION => 2;
sub new
{
	my $classname = shift;
	my %params = @_;
	my $self = bless({}, $classname);

	$self->{ stack } = [];
	$self->{ defs  } = {};
	$self->{ vars  } = {};
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
		$self->push( Number->new( $a->{ value } + $b->{ value } ) );
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
				$self->push( Number->new( $a->{ value } / $b->{ value } ));
			}
		}
		else {
			$self->push( Number->new( $a->{ value } * $b->{ value } ));
		}
	}
	else {
		$self->error("stack underflow");
	}
}

# --------------------------------------------------------
# Store a number or string (from stack) into a named field
#
# value
# "string"
# (sto)
sub store
{
	my $self = shift;
	if ($self->count_stack() < 2)
	{
		$self->error("stack underflow");
		return;
	}
	my $label = $self->pop();
	if (ref $label ne "String")
	{
		$self->push( $label );
		$self->error("there must be the name (string)");
		return;
	}
	my $thing = $self->pop();
	$self->{vars}->{$label->value()} = $thing->clone();
	$self->push($thing);
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
	if (ref $index ne "Number")
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
	if (ref $elem eq "Number")
	{
		$self->push( Number->new( $elem->value() )); # clone
	}
	elsif (ref $elem eq "String")
	{
		$self->push( String->new( $elem->value() )); # clone
	}
	else {
		$self->error("Cannot copy that thing.");
	}
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

	my $has = 0;
	$has++ if ref $self->{stack}->[ 0 ] eq "Number";
	$has++ if ref $self->{stack}->[ 1 ] eq "Number";
	return $has == 2 ? 1 : 0;
}


# --------------------------------------------------------
sub do
{
	my ($self, $op) = @_;
	die("Cannot handle " . Dumper($op)) if ref $op ne "Operator";
	# Symbols are internal symbols/operators or values or programs defined by the user.
	my $what = $op->{ value };
	if ($what eq "+")
	{
		$self->add();
		return;
	}
	elsif ($what eq "-")
	{
		$self->add( invert => 1 );
		return;
	}
	elsif ($what eq "*")
	{
		$self->mul();
		return;
	}
	elsif ($what eq "/")
	{
		$self->mul( invert => 1 );
		return;
	}
	elsif ($what eq "dup")
	{
		if ($self->count_stack() >= 1)
		{
			my $a = $self->pop();
			$self->push( $a );
			$self->push( $a );
		}
		return;
	}
	elsif (($what eq "drop") || ($what eq "d"))
	{
		$self->drop();
		return;
	}
	elsif (($what eq "copy") || ($what eq "cp"))
	{
		$self->copy();
		return;
	}
	elsif ($what eq "swap")
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
	elsif (($what eq "clear") || ($what eq "clr"))
	{
		$self->{ stack } = [];
		return;
	}
	elsif ($what eq "sto")
	{
		$self->store();
		return;
	}

	## 2. or is it defined in our defs?
	#elsif (defined( $self->{ defs }->{ $what } ))
	#{
	#	# a list of Element objects
	#	# copy them on the stack:
	#	my $subroutine = $self->{ defs }->{ $what };
	#	foreach my $e (@$subroutine)
	#	{
	#		$self->push( $e );
	#	}
	#	return;
	#}
	print "WARNING unknown symbol >$what<. Skipped.\n"; # die?
}

# ----------------------------------------------------------------------------
sub show
{
	my $self = shift;

	my $vars = $self->{ vars };
	if (scalar keys %{ $vars })
	{
		my $s = "";
		map { $s .= "$_=" . $vars->{ $_ }->value() . " " } sort keys %{ $vars };
		print "VARS: " . substr($s, 0, -1) . "\n";
	}
	
	print "Stack:\n";
	my $stack = $self->{ stack };
	# print "stack in wrong order :-) : " . Dumper($stack);
	my $number = scalar @{ $stack };
	
	for (my $i = $number - 1; $i >= 0; $i--)
	{
		my $atom = $stack->[ $i ];
		if (ref $atom eq "Number")
		{
			printf("  %2s : %s\n", '#' . $i, $atom->{value}); # TODO add format
		}
		elsif (ref $atom eq "String")
		{
			printf("  %2s : %s\n", '#' . $i, ">>" . $atom->{value} . "<<"); # TODO add format
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
