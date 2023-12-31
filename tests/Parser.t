#!/usr/bin/perl

# low level tests for Parser.pm

use strict;
use warnings;
use Test::More 'no_plan';
use Test::Deep;
use Data::Dumper;
use File::Temp qw(tempfile);
use FindBin;
use lib "$FindBin::Bin/../lib";
use Element;
use Parser;

my $p = Parser->new( operators => ["clear", "+", "-", "drop", "/", "*", "q"] );
isa_ok( $p, "Parser" );

my $a = int(rand(10000));
my $b = int(rand(10000));
my $s = $a + $b;

my $stream = " $a  $b + mysymbol";
note("Test stream: $stream");
$p->set_stream( $stream );

my $e;
$e = $p->next_atom();
isa_ok( $e, "Element", "next_atom is an Element");
is( $e->type(), Element->NUMBER, "first element from stream is NUMBER" );
is( $e->value(), $a, "value of first element from stream is $a" );

ok( ! $e->is_end(), "->is_end() is not TRUE" );

$e = $p->next_atom();
isa_ok( $e, "Element", "next_atom is an Element");
is( $e->type(), Element->NUMBER, "second element from stream is NUMBER" );
is( $e->value(), $b, "value of second element from stream is $b" );

$e = $p->next_atom();
isa_ok( $e, "Element", "next_atom is an Element");
is( $e->type(), Element->OPERATOR, "third element from stream is OPERATOR" );
is( $e->value(), '+', "value is '+'" );

$e = $p->next_atom();
isa_ok( $e, "Element", "next_atom is an Element");
is( $e->type(), Element->SYMBOL, "next element from stream is SYMBOL" );
is( $e->value(), 'mysymbol', "value is 'mysymbol'" );

$e = $p->next_atom();
isa_ok( $e, "Element", "next_atom is an Element");
is( $e->type(), Element->END_OF_STREAM, "now end-of-stream" );
ok( $e->is_end(), "->is_end() is TRUE" );

$e = $p->next_atom();
isa_ok( $e, "Element", "next_atom called again is also end-of-stream Element");
is( $e->type(), Element->END_OF_STREAM, "also end-of-stream" );
ok( $e->is_end(), "->is_end() is TRUE" );

done_testing;

