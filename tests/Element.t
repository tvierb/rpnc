#!/usr/bin/perl

# low level tests for Element.pm

use strict;
use warnings;
use Test::More 'no_plan';
use Test::Deep;
use Data::Dumper;
use File::Temp qw(tempfile);
use FindBin;
use lib "$FindBin::Bin/../lib";
use Element;

my $e;
$e = Element->new( Element->OPERATOR, 'help' );
isa_ok( $e, 'Element' );
ok( $e->is( Element->OPERATOR ), 'operator element is of that type' );
ok( $e->is_help(), 'help-operator: is_help' );

$e = Element->new( Element->OPERATOR, 'q' );
isa_ok( $e, 'Element' );
ok( $e->is( Element->OPERATOR ), 'operator element is of that type' );
ok( $e->is_quit(), 'quit-operator (from q): is_quit' );

$e = Element->new( Element->OPERATOR, 'quit' );
ok( $e->is_quit(), 'quit-operator (from quit): is_quit' );

$e = Element->new( Element->ERROR, 'unknown error' );
ok( $e->is_error(), 'ERROR-element is detected' );
is( $e->value(), 'unknown error', 'error message is in the object' );

done_testing;

