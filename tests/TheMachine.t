#!/usr/bin/perl

use strict;
use warnings;
use Test::More 'no_plan';
use Test::Deep;
use FindBin;
use lib "$FindBin::Bin/..";
use TheMachine;

my $m = TheMachine->new( noload => 1, nosave => 1 );
ok( ref $m, "habe eine TheMachine" );
