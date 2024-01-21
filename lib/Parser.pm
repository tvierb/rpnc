package Parser;

# TODO the operators/functions clear|clr|vars|q»+|-... should be defined in TheMachine object with their regexps
use strict;
use warnings;
use ElementFactory;

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
	$self->{ stream } = '';
	return $self;
}

sub set_stream
{

	my ($self, $stream) = @_;
	$stream =~ s/^ //g;
	$self->{ stream } = $stream;
}

# add something to detect in the stream:
sub add_operator
{
	my $self = shift;
	my $op = shift;
	$op =~ s/([^a-zA-Z0-9])/\\$1/g; # escape + - / *
	push( @{ $self->{ regexp_operators }}, $op );
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
		return ElementFactory::end("moo");
	}
	if ($stream =~ /^(-[0-9]+([\.][0-9]+)?)(.*)/)
	{
		$self->{ stream } = $3;
		return ElementFactory::number( $1 ); # negative number
	}
	elsif ($stream =~ /^([0-9]+([\.][0-9]+)?)(.*)/)
	{
		$self->{ stream } = $3;
		return ElementFactory::number( $1 ); # positive number
	}
	#elsif (defined($opreg) && ($stream =~ /^($opreg)(.*)/))
	#{
	#	$self->{ stream } = $2;
	#	return ElementFactory::operator( $1 ); # internal operation
	#}
	elsif ($stream =~ /^"([^"]*)"(.*)/)
	{
		$self->{ stream } = $2;
		return ElementFactory::string( $1 ); # string object
	}
	elsif ($stream =~ /^'([^']*)'(.*)/)
	{
		$self->{ stream } = $2;
		return ElementFactory::string( $1 ); # string object
	}
	elsif ($stream =~ /^([\+\-\*\/]{1})(.*)/)
	{
		$self->{ stream } = $2;
		return ElementFactory::symbol( $1 ); # symbol
	}
	elsif ($stream =~ /^([a-zA-Z][a-zA-Z0-9_]*)(.*)/)
	{
		$self->{ stream } = $2;
		return ElementFactory::symbol( $1 ); # symbol
	}
	else {
		print "no match in '$stream'\n";
	}

	print "ERROR: Cannot get next element from stream '$stream'. Discaroding.\n";
	$self->{ stream } = '';
	return;
}

1;
