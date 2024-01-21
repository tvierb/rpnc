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
use Element;

my $m = TheMachine->new( noload => 1, nosave => 1 );

ok( ref $m, "habe ein objekt" );
isa_ok( $m, "TheMachine" );
ok( ! ref $m->get_at_index(0), "nothing is on the stack" );
is( $m->count_stack(), 0, "no things are on the stack" );


$m = TheMachine->new( noload => 1, nosave => 1 );
note('pushing a number');
$m->push( Element->new( Element->NUMBER, 13 ) );
is( $m->count_stack(), 1, "there is exact one item on the stack" );

note('pushing another number');
$m->push( Element->new( Element->NUMBER, -13 ) );
ok( $m->has_two_numbers(), "has_two_numbers() ist true" );
is( $m->count_stack(), 2, "count_stack == 2" );

$m->add();
is( $m->count_stack(), 1, "adding two numbers results in a single stack element" );
my $e = $m->pop();
isa_ok( $e, "Element", "thing on stack was an Element");
ok( $e->is( Element->NUMBER ), "thing is a number");
is( $e->value(), 0, "13 + -13 is 0");


done_testing;
