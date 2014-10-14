package Migrations::Clearcase;

use strict;
use warnings;
use v5.18;

our $VERSION = '0.1';

use Carp;
use Log::Log4perl qw(:easy);
use File::Spec;

#------------------------------------------------
#
# Clearcase commands
#
#------------------------------------------------

#------------------------------------------------
# where_is_cleartool()
#
# Locate cleartool (or cleartool.exe) :
# - in PATH
# - in ATRIA_HOME/bin
# - in /usr/atria/bin   (unix-like only)
#
#  RETURN
#      fullpath to cleartool (or cleartool.exe) 
#      or
#      undef   if cleartool cannot be find
#------------------------------------------------
sub where_is_cleartool
{
    my $ct = 'cleartool';
    if ( $^O eq 'MSWin32' or $^O eq 'cygwin' ) {
        $ct = 'cleartool.exe';
    }

    if ( defined $ENV{'PATH'} ) {
        for my $p ( File::Spec->path() ) {
           my @d = File::Spec->splitdir($p) ;
           my $f = File::Spec->catfile(@d, $ct);
           return $f if ( -x $f );
           return $f if ( -f $f and $^O eq 'cygwin' );
        }
    }
    if ( defined $ENV{'ATRIA_HOME'} ) {
        my @d = File::Spec->splitdir($ENV{ATRIA_HOME});
        my $f = File::Spec->catfile(@d, $ct);
        return $f if ( -x $f );
        return $f if ( -f $f and $^O eq 'cygwin' );
    }

    my @d = File::Spec->splitdir('/usr/atria/bin');
    my $f = File::Spec->catfile(@d, $ct);
    return $f if ( -x $f );
    return $f if ( -f $f and $^O eq 'cygwin' );

    return undef;
}
# end of where_is_cleartool()
#------------------------------------------------


#------------------------------------------------
# cleartool
#
# Execute the command cleartool with the given arguments
#
# WARNINGS:
#    1. arguments have been sanitized
#    2. not suitable for interactive commands
#
# RETURN without argument:
#    SCALAR: ''
#    ARRAY : ()
# RETURN with arguments:
#    SCALAR context:
#    undef if cleartool cannot be found
#    what the commabnd returned on STDOUT+STDERR
#
#    ARRAY context:
#    (undef) if cleartool cannot be found
#    the return code of cleartool as 1st element,
#    then each line of STDOUT+STDERR (1 line = 1 element)
# 
#------------------------------------------------
sub cleartool
{
    state $CLEARTOOL;
    if ( !defined $CLEARTOOL ) {
        INFO "[I] Searching cleartool...";
        $CLEARTOOL = where_is_cleartool();
        if ( !defined $CLEARTOOL ) {
            return undef;
        }
        INFO "[I] cleartool is $CLEARTOOL";
    }

    if ( scalar @_ == 0 ) {
        INFO "[I] Calling: cleartool <no args>";
        return wantarray ? () : '';
    }
    
    my @args = @_;
    INFO "[I] Calling: cleartool " . ( join ' ',@args );

    # Assume the arguments have been sanitized
    # (They should not come from the user)
    my $cmd = join ' ', $CLEARTOOL, @args;
    open my $ct, '-|', $cmd . ' 2>&1'      or LOGDIE "[F] Cannot execute $cmd. Abort.";
    my @ret = <$ct>;
    close $ct;
    my $r = $? >>8;
    return wantarray ? ($r, @ret) : (join '', @ret);

}
# end of cleartool()
#------------------------------------------------


#------------------------------------------------
# region()
#
# Returns the current Clearcase region
#
# Assumes cleartool does exists!
# 
#
# RETURN
#     undef if there's no cleartool
#     '' if the region cannot be defined
#     the region otherwise
#
#------------------------------------------------
sub region
{
    my ($err,@desc) = cleartool('hostinfo -l');
    return undef if ( !defined $err );
    return '' if $err;
    # length('  Registry region: ') == 19
    my ($r) = grep { substr($_,0,19) eq '  Registry region: ' } @desc;
    chomp $r;
    return substr($r, 19);
}
#------------------------------------------------


#------------------------------------------------
# registry()
#
# Returns the current Clearcase registry host
#
# Assumes cleartool does exists!
# 
#
# RETURN
#     undef if there's no cleartool
#     '' if the registry host cannot be defined
#     the registry host otherwise
#
#------------------------------------------------
sub registry
{
    my ($err,@desc) = cleartool('hostinfo -l');
    return undef if ( !defined $err );
    return '' if $err;
    # length('  Registry host: ') == 17
    my ($r) = grep { substr($_,0,17) eq '  Registry host: ' } @desc;
    chomp $r;
    return substr($r, 17);
}
#------------------------------------------------


#------------------------------------------------
# is_a_pvob()
#
# Check if $vob is a PVOB
#
# Assumes cleartool does exists!
# 
#
# RETURN
#     undef if there's no cleartool
#     0 if $vob is a PVOB
#     1 if $vob is a VOB, but not a PVOB
#     2 if $vob is not a VOB
#
#------------------------------------------------
sub is_a_pvob
{
    my $vob = shift;

    return 2 unless ( defined $vob and $vob ne '' and $vob !~ /\s/ );

    # is $p a PVOB?
    my ($err,@desc) = cleartool('desc vob:'.$vob);
    return undef if ( ! defined $err );
    return 2 if $err ;
    return 0 if ( grep { chomp; $_ eq '  project VOB' } @desc );
    return 1;
}
#------------------------------------------------


#------------------------------------------------
# check_stream()
#
# Check if the stream is valid :
# - contains a PVOB
# - exists in this PVOB
#
# Assumes cleartool does exists!
#
# RETURN (scalar context)
#     undef if the stream is invalid or cleartool doesn't exist
#     stream without the PVOB is the stream is valid
#
# RETURN (array context)
#     (undef) if the stream is invalid or cleartool doesn't exist
#     (stream, pvob) is the stream is valid
# 
#------------------------------------------------
sub check_stream
{
    my $stream = shift;

    return undef unless ( defined $stream );
    return undef unless ( $stream =~ /^([^@]+)\@(.+)$/ );

    my ($s,$p) = ($1,$2);
    return undef if ( $s eq '' or $p eq '');
    # is $p a PVOB?
    my $not_a_pvob = is_a_pvob($p);
    return undef if $not_a_pvob ;
    # $p is a PVOB

    # is $s a stream of $p?
    my ($err,@desc) = cleartool('desc -s stream:'.$stream);
    return undef if ( ! defined $err );
    return undef if $err ;

    return wantarray ? ($s,$p) : $s;
}
#------------------------------------------------


1;

__DATA__


