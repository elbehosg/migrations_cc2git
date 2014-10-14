package Migrations::Parameters;

use strict;
use warnings;
use v5.18;

our $VERSION = '0.0.1';

use Carp;
use Getopt::Long qw(GetOptionsFromString);


#------------------------------------------------
#
# Command line analysis
#
#------------------------------------------------

sub command_line_analysis
{
    my $opt       = shift;
    my $mandatory = shift;
    my $optional  = shift;
    my $either    = shift;

    #
    # --input ?
    #
    if ( exists $opt->{input} ) {
        my $fname = $opt->{input}; # GetOpt ensures there's a value
        open my $fh, '<', $fname or die "[F] Cannot read $fname (from --input): $! . Abort.\n";
        my $argv = '';
        while ( <$fh> ) {
            # ignore comments and empty lines
            s/#.+//; s/^\s+//; s/\s+$//;
            next unless length ; 
            $argv .= ' ' . $_;
        }
        close $fh;
        my ($ret, $args) = GetOptionsFromString($argv, $opt, @$mandatory, @$optional, map {@$_}@$either);
        # TODO: que faire de $ret (code retour) et $args (arguments hors @$...)

        #say Data::Dumper->Dump([$opt], ['opt apres']);
    }

    #
    # Check if the mandatory parameters are set
    #
    my @missing = grep { ! exists $opt->{$_} } map { s/[!+|=].*//;$_ } @$mandatory;
    for my $i ( @$either ) {
        if ( grep { exists $opt->{$_} } grep { s/[!+|=].*// } @$i ) {
            next;
        }
        push @missing, ( join ' or ', @$i );
    }
    if ( scalar @missing ) {
        carp '[F] Missing mandatory arguments: ', (join ', ', @missing), ". Abort.\n";
    }

    #
    # Check if optional parameters are set
    #    Assign default options if not
    #
    for my $i ( map { s/[!+|=].*// ; $_} @$optional ) {
       1; 
    }
}


1;

__DATA__


