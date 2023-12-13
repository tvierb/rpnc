#!/usr/bin/perl

# Tests for Parser.pm

use strict;
use warnings;
use Test::More 'no_plan';
use Test::Deep;
use Data::Dumper;
use File::Temp qw(tempfile);
use FindBin;
use lib "$FindBin::Bin/..";
use TheMachine;
use Parser;

my $p = Parser->new( operators => ["clear", "+", "-", "drop", "/", "*"] );
isa_ok( $p, "Parser" );


my $r = int(rand(50000));
is_deeply( $p->next_atom( $r ), [{type => $p->NUMBER, value => $r}, ""], "next_atom($r) makes NUMBER");
is_deeply( $p->next_atom( "123 456" ), [{type => $p->NUMBER, value => 123}, " 456"], "next_atom($r) makes NUMBER and returns rest");
is_deeply( $p->next_atom( "-567" ), [{type => $p->NUMBER, value => -567}, ""], "next_atom($r) negative NUMBER");

# TODO operators shoud come from TheMachine object
foreach my $op ("+", "-", "*", "/", "clear", "drop")
{
	my $e = $p->next_atom( "$op hello" );
	is_deeply( $e, [{type => $p->OPERATOR, value => $op}, " hello"], "operator $op");
}
is_deeply( $p->next_atom(""), [{type => $p->END_OF_STREAM, value => "moo"}, ""], "detect end of stream");

is_deeply( $p->next_atom('"fische" "troeten"'), [{type => $p->STRING, value => "fische"}, ' "troeten"'], "find a string");
is_deeply( $p->next_atom('notpi'), [{type => $p->SYMBOL, value => "notpi"}, ''], "find a symbol");

# test with a calculator:
my $m = TheMachine->new(nosave => 1, noload => 1);
my $ops = $m->operators();
push( @$ops, 'q' ); # must be able to quit (is for rpnc program, not for cALCULATOR)
$p = Parser->new( operators => $ops );
is_deeply( $p->next_atom('q'), [{type => $p->OPERATOR, value => "q"}, ''], "find operator 'q'");

is_deeply( $p->as_number("-5.123"), {type => Parser->NUMBER, value => -5.123}, "make a number 1" );
is_deeply( $p->as_number("5.123"),  {type => Parser->NUMBER, value =>  5.123}, "make a number 2" );

done_testing;

