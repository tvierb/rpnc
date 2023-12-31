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

my $stream = " $a  $b +";
note("Test stream: $stream");
$p->set_stream( $stream );

my $e;
$e = $p->next_atom();
isa_ok( $e, "Element", "next_atom is an Element");
is( $e->type(), Element->NUMBER, "first element from stream is NUMBER" );
is( $e->value(), $a, "value of first element from stream is $a" );

$e = $p->next_atom();
isa_ok( $e, "Element", "next_atom is an Element");
is( $e->type(), Element->NUMBER, "second element from stream is NUMBER" );
is( $e->value(), $b, "value of second element from stream is $b" );

$e = $p->next_atom();
isa_ok( $e, "Element", "next_atom is an Element");
is( $e->type(), Element->OPERATOR, "third element from stream is OPERATOR" );
is( $e->value(), '+', "value is '+'" );

done_testing;

