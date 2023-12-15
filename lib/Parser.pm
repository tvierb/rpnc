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
	return $self;
}

# add something to detect in the stream:
sub add_operator
{
	my $self = shift;
	my $op = shift;
	$op =~ s/([^a-zA-Z0-9])/\\$1/g; # escape + - / *
	push( @{ $self->{ regexp_operators }}, $op );
}

# generate regexp to detect operators / functions
# returns a string
sub ops_regexp
{
	my $self = shift;
	return join("|", @{ $self->{ regexp_operators } } );
}


# non static function
# returns next Element and the rest of the stream
# returns Element->END_OF_STREAM when nothing is left
sub next_atom
{
	my $self = shift;
	my $stream = shift;
	$stream =~ s/^ //g;
	my $opreg = $self->ops_regexp();
	if (! length($stream))
	{
		return [ ElementFactory::end("moo"), ""];
	}
	if ($stream =~ /^(-[0-9]+([\.][0-9]+)?)(.*)/)
	{
		return [ ElementFactory::number( $1 ), $3]; # negative number
	}
	elsif ($stream =~ /^([0-9]+([\.][0-9]+)?)(.*)/)
	{
		return [ ElementFactory::number( $1 ), $3]; # positive number
	}
	elsif (defined($opreg) && ($stream =~ /^($opreg)(.*)/))
	{
		return [ ElementFactory::operator( $1 ), $2]; # internal operation
	}
	elsif ($stream =~ /^"([^"]*)"(.*)/)
	{
		return [ ElementFactory::string( $1 ), $2]; # string object
	}
	elsif ($stream =~ /^'([^']*)'(.*)/)
	{
		return [ ElementFactory::string( $1 ), $2]; # string object
	}
	elsif ($stream =~ /^([a-zA-Z][a-zA-Z0-9_]*)(.*)/)
	{
		return [ ElementFactory::symbol( $1 ), $2]; # string object
	}
	return [ ElementFactory::unknown( $stream ), ""];
}
1;
