package TheMachine;

use strict;
use warnings;
use Data::Dumper;
use YAML::Syck;

use constant SAVEFILE_VERSION => 2;
sub new
{
	my $classname = shift;
	my %params = @_;
	my $self = bless({}, $classname);

	$self->{ stack } = [];
	$self->{ vars  } = {};
	$self->{ flags } = {}; # TODO config vars (output format)
	$self->{ errors} = []; # collected errors, cleared when printed
	$self->{ loop  } = 4e4;
	$self->{ do_load_state } = ($params{'noload'} // 0) ? 0 : 1; # default: load_state
	$self->{ do_save_state } = ($params{'nosave'} // 0) ? 0 : 1;
	$self->{ statefile } = $params{statefile} // $ENV{"HOME"} . "/.rpnc";
	$self->load_state() if $self->{ do_load_state };
	$self->{ reserved } = {};
	map { $self->{ reserved }->{$_} = 1 } ("sin", "cos", "inv", "swap", "swp", "drop", "dup", "clear", "clr", "pi");
	return $self;
}

# --------------------------------------------------------
# load the machine state of last session
# TODO let the main package load the state and put it into the machine with setters
sub load_state
{
	my ($self) = @_;
	return unless -f $self->{ statefile };
	# print "Loading state from file '" . $self->{ statefile } . "'\n";
	my $state = LoadFile( $self->{ statefile } );
	my $version = $state->{_version} // "-1";
	if ($version != $self->SAVEFILE_VERSION)
	{
		die("state file version mismatch. I found >$version< but I need >" . $self->SAVEFILE_VERSION . "<");
	}

	$self->{ stack } = $state->{ stack };
	$self->{ vars  } = $state->{ vars  };
	$self->{ flags } = $state->{ flags };
}

# --------------------------------------------------------
# push or better unshift element to stack
sub push
{
	my ($self, $atom) = @_;
	unshift( @{ $self->{ stack } }, $atom );
}

# --------------------------------------------------------
sub save_state
{
	my ($self) = @_;
	my $state = {
		_version => $self->SAVEFILE_VERSION,
		stack => $self->{ stack },
		vars  => $self->{ vars  },
		flags => $self->{ flags },
		revision => main->REVISION,
		comment => "statefile of the RPNC rpn calculator",
	};
	# print "Saving state " . Dumper( $state );
	DumpFile( $self->{ statefile }, $state );
}

# --------------------------------------------------------
sub shutdown
{
	my ($self) = @_;
	$self->save_state() if $self->{ do_save_state };
}

# --------------------------------------------------------
sub do
{
	my ($self, $atom) = @_;
	my $type = $atom->{ type };
	if ($type eq Parser->OPERATOR)
	{
		$self->operate( $atom );
	}
	elsif ($type eq Parser->NUMBER)
	{
		$self->push( $atom );
	}
	else {
		$self->error("Unknown atom type '$type' with value '" . $atom->{ value } . "'. Skipped.");
	}
}

# --------------------------------------------------------
sub error
{
	my ($self, $message) = @_;
	CORE::push( @{ $self->{errors} }, $message );
}


# --------------------------------------------------------
# add two number of type Parser->NUMBER
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
		$self->push( {type => Parser->NUMBER, value => $a->{ value } + $b->{ value } } );
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
				$self->push( {type => Parser->NUMBER, value => $a->{ value } / $b->{ value } } );
			}
		}
		else {
			$self->push( {type => Parser->NUMBER, value => $a->{ value } * $b->{ value } } );
		}
	}
}

# --------------------------------------------------------
# -- : --
# TODO implement test
sub drop
{
	my $self = shift;
	if (scalar @{ $self->{ stack }} > 0)
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
	if ($index->{ type } ne Parser->NUMBER)
	{
		$self->error("expected index to element on stack but popped a non-number");
		return;
	}
	$index = $index->{ value };
	my $elem = get_at_index( $index );
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
	if ($self->idx_is_number(0) && $self->idx_is_number(1))
	{
		return 1;
	}

	$self->error( "not two numbers on stack" );
	return 0;
}

# is stack place #3 there and is it a number?
# is it counting from 0? yes (why? because it is the index of the element)
sub idx_is_number
{
	my ($self, $index) = @_;
	return 0 if scalar@{ $self->{ stack }} >= ($index + 1);
	return 0 if ($self->{ stack }->[ $index ]->{ type } ne Parser->NUMBER);
	return 1;
}

# --------------------------------------------------------
sub operate
{
	my ($self, $atom) = @_;
	my $type = $atom->{ type };
	my $operation = $atom->{ value };
	if ($type eq Parser->OPERATOR)
	{
		if ($operation eq "+")
		{
			$self->add();
			return;
		}
		elsif ($operation eq "-")
		{
			$self->add( invert => 1 );
			return;
		}
		elsif ($operation eq "*")
		{
			$self->mul();
			return;
		}
		elsif ($operation eq "/")
		{
			$self->mul( invert => 1 );
			return;
		}
		elsif (($operation eq "drop") || ($operation eq "d"))
		{
			$self->drop();
			return;
		}
		elsif (($operation eq "copy") || ($operation eq "cp"))
		{
			$self->copy();
			return;
		}
		elsif ($operation eq "swap")
		{
			if (scalar @{ $self->{ stack }} >= 2)
			{
				my $b = shift( @{ $self->{ stack }} );
				my $a = shift( @{ $self->{ stack }} );
				$self->push( $b );
				$self->push( $a );
			}
		}
		elsif (($operation eq "clear") || ($operation eq "clr"))
		{
			$self->{ stack } = [];
		}
		else {
			die("unknown operation >$operation<");
		}
	}
	else
	{
		die("Unknown type '$type' in ->operate");
	}
}

# ----------------------------------------------------------------------------
sub show
{
	my ($self) = shift;

	my $vars = $self->{ vars };
	if (scalar keys %{ $vars })
	{
		my $s = "";
		map { $s .= "$_=" . $vars->{ $_ } . " " } sort keys %{ $vars };
		print "VARS: " . substr($s, 0, -1) . "\n";
	}
	
	print "Stack:\n";
	my $stack = $self->{ stack };
	# print "stack in wrong order :-) : " . Dumper($stack);
	my $number = scalar @{ $stack };
	
	for (my $i = $number - 1; $i >= 0; $i--)
	{
		my $atom = $stack->[ $i ];
		if ($atom->{type} eq Parser->NUMBER)
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
