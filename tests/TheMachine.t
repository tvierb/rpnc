#!/usr/bin/perl

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

my $m = TheMachine->new( noload => 1, nosave => 1 );
ok( ref $m, "habe ein objekt" );
isa_ok( $m, "TheMachine" );
ok( ! ref $m->get_at_index(0), "nothing is on the stack" );
is( $m->count_stack(), 0, "no things are on the stack" );

$m->push( {type => Parser->NUMBER, value => 1234} );
is( $m->count_stack(), 1, "one thing is on the stack" );
ok( ref $m->get_at_index(0), "the thing on the stack is a ref" );
my $what = $m->pop();
note( Dumper( $what ) );
ok( ref $what, "popped a ref from stack" );
is( $what->{ value }, 1234, "value is 1234");

my $statefilecontent = "--- 
_version: 2
comment: statefile of the RPNC rpn calculator
flags: {}

revision: 20231213
stack: []
vars: {}
";


