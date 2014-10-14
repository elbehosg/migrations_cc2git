package Migrations::Parameters;

use strict;
use warnings;
use v5.18;

our $VERSION = '0.0.1';

use Carp;
use List::MoreUtils qw(none any );

use Data::Dumper;

#------------------------------------------------
#
# Command line analysis
#
#------------------------------------------------

#------------------------------------------------
# list_for_getopt()
#
# Build a list of arguments to be given to 
# Getopt::Long::GetOptions(\%h, @l)-like
#
# IN:
#    $hash : HASH ref describing the valid arguments
#
# RETURN:
#    a list of string for G::L::GetOptions()
#
# DIE:
#    in case of (too) bad argument
#
# FORMAT of %$hash
#   $hash->{arg1 => { ... },
#           ...,
#          }
# with ... in:
#     getopt => string    description of the arg for Getopt::Long::GetOptions
#                         (alternate names go there)
#     mandatory => 1      if the arg is mandatory
#     optional  => 1      if the arg is optional
#     default => something   default value for the args
#     mandatory_unless => [ argA, argB ] if one of the arg1, argA, argB are mandatory
#     exclude => [ argA, argB. ] if presence of arg1 forbids presence of argA or argB
#
#------------------------------------------------
sub list_for_getopt
{
    my $hash = shift;

    die "[F] Parameter 'hash' in " . __PACKAGE__ . "::list_for_getopt() is required. Abort.\n" unless (defined $hash );
    die "[F] 'hash' in " . __PACKAGE__ . "::list_for_getopt() must be an HASH ref. Abort.\n"   unless (ref($hash) eq 'HASH');

    my @list = map { $_->{getopt} } grep  { exists $_->{getopt} } values %$hash;

    return @list;
}
# end of list_for_getopt()
#------------------------------------------------


#------------------------------------------------
# validate_arguments()
#
# Analyze the args from the command line:
# - check that mandatory args are set
# - fill optional args with default values is any
# - check consistancy between args
# - don't check anything against "real-life entities" (like an existing stream in Clearcase)
# 
# IN/OUT:
# $opt : ref to a hash filled by Getopt::Long::GetOptions() (or alike)
#        with the args from the command line
#        optional args with a default value may be added to %$opt if they
#        weren't explicit
# IN:
# $exptd : has ref describing the expected args (see list_for_getopt())
#
# RETURN:
#    0   if nothing's wrong
#    or the sum of the following:
#    1   mandatory argument missing
#    2   conflicting arguments
# 1024   other error (lazy dev!)
#
# DIE:
#    in case of (too) bad argument
#
#------------------------------------------------
sub validate_arguments
{
    my $opt       = shift;
    my $exptd     = shift;

    die "[F] Illegal argument 'opt' in "   . __PACKAGE__ ."::validate_arguments()\n" unless (defined $opt   and ref($opt)   eq 'HASH' );
    die "[F] Illegal argument 'exptd' in " . __PACKAGE__ ."::validate_arguments()\n" unless (defined $exptd and ref($exptd) eq 'HASH' );

    my $err = 0;
    #
    # Check if the mandatory parameters are set
    #
    my @missing = ();
    while ( my ($k,$v) = each %$exptd ) {
        if ( exists $v->{mandatory} and $v->{mandatory} and !exists $opt->{$k} ) {
            push @missing, $k;
        }
        if ( exists $v->{mandatory_unless} ) {
            if ( none { exists $opt->{$_} } @{ $v->{mandatory_unless} } ) {
                push @missing, $k unless exists $opt->{$k};
            }
        }
    }
    if ( scalar @missing ) {
        warn "[W] Missing mandatory arguments: " . ( join ',', @missing) . "\n";
        $err += 1;
    }

    #
    # Check if 2 args exclude each other
    #
    for my $k ( keys %$opt ) {
        if ( exists $exptd->{$k}->{exclude} ) {
            my @shouldnotbehere = @{ $exptd->{$k}->{exclude} };
            if ( any { exists $opt->{$_} } @shouldnotbehere ) {
                warn "[W] Conflicting arguments ($k and another one).\n";
                $err += 2;
                last;
            }
        }
    }

    #
    # Check if optional parameters are set
    #    Assign default options if not
    #
    while ( my ($k,$v) = each %$exptd ) {
        if ( exists $v->{default} and !exists $opt->{$k} ) {
            $opt->{$k} = $v->{default};
        }
    }

    return $err;
}
# end of validate_arguments()
#------------------------------------------------


1;

__DATA__


