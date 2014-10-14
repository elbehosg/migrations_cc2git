#!/usr/bin/env perl

use strict;
use warnings;
use v5.10;
use lib './lib';
use Migrations::Parameters;

my %expected = (
    a1 => { mandatory => 1, getopt => 'a1=s', },
    a2 => { mandatory => 1, getopt => 'a2=i', },
    a3 => { optional  => 1, getopt => 'a3!', default => 0, },
    a4 => { mandatory_unless => [ 'a5' ], getopt => 'a4', },
    a5 => { mandatory_unless => [ 'a4' ], getopt => 'a5', },
    a6 => { optional  => 1, getopt => 'a6', default => 0, exclude => [ 'a7', 'a8' ], },
    a7 => { optional  => 1, getopt => 'a7', exclude => [ 'a6' ], },
    a8 => { optional  => 1, getopt => 'a8!', default => 1, },
    );
my %opt;
my $r;
%opt = ( a1 => 'foo', a2 => 42, a4 => 1 );
$r = Migrations::Parameters::validate_arguments(\%opt,\%expected);

say "r = $r";
while ( my ($k,$v) = each %opt ) {
    say "$k --> $v";
}

exit 0;

