#!/usr/bin/perl

use strict;
use warnings;
use Test::More 'no_plan';
use Test::Deep;
use Data::Dumper;
use File::Temp qw(tempfile);
use FindBin;
use lib "$FindBin::Bin/../lib";
use TheMachine;
use Parser;

my $m = TheMachine->new( noload => 1, nosave => 1 );
my $p = Parser->new();

ok( ref $m, "habe ein objekt" );
isa_ok( $m, "TheMachine" );
ok( ! ref $m->get_at_index(0), "nothing is on the stack" );
is( $m->count_stack(), 0, "no things are on the stack" );

$m->push( $p->as_number( 1234 ) );
is( $m->count_stack(), 1, "one thing is on the stack" );
ok( ref $m->get_at_index(0), "the thing on the stack is a ref" );
my $what = $m->pop();
# note( Dumper( $what ) );
ok( ref $what, "popped a ref from stack" );
is( $what->{ value }, 1234, "value is 1234");

$m->{ operators } = {"sin" => 1};
my $ops = $m->operators();
is(ref $ops, "ARRAY", "got arrayref of operators");
is( @{$ops}[0], "sin", "the operator defined was found (1)");
ok( defined( $m->{ operators }->{ sin }), "the operator defined was found");

$m = TheMachine->new( noload => 1, nosave => 1 );
$m->push( $p->as_number( 15 ) );
is( $m->count_stack(), 1, "one thing is on the stack again" );
ok( $m->idx_is_of_type( 0, Parser->NUMBER ), "element at #0 is a NUMBER" );

$m->push( $p->as_number( -15 ) );
ok( $m->idx_is_of_type( 1, Parser->NUMBER ), "element at #1 is also a NUMBER" );
ok( $m->has_two_numbers(), "has_two_numbers() ist true" );
note( Dumper( $m->{ stack } ) );

$m->add();
is( $m->count_stack(), 1, "adding two numbers results in a single stack elememt" );
my $e = $m->pop();
is( ref $e, "HASH", "thing on tstack is hashref");
is( $e->{type}, Parser->NUMBER, "thing is a number");
is( $e->{value}, 0, "thing is zero");

# TODO this fails

#my $statefilecontent = "--- 
#_version: 2
#comment: statefile of the RPNC rpn calculator
#flags: {}
#
#revision: 20231213
#stack: []
#vars: {}
#";

done_testing;
