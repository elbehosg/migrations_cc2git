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
# ASSUME THE ARGUMENTS HAVE BEEN SANITIZED
#
# WARNINGS:
#    1. arguments have been sanitized
#    2. not suitable for interactive commands
#
# RETURN with or without argument;
#    undef is cleartool command cannot be found
# RETURN without argument:
#    SCALAR: ''
#    ARRAY : ()
# RETURN with arguments:
#    SCALAR context:
#    what the command returned on STDOUT+STDERR
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
    $s=~ s/^stream://;   # in case of...
    my ($err,@desc) = cleartool('desc -s stream:'.$s.'@'.$p);
    return undef if ( ! defined $err );
    return undef if $err ;

    return wantarray ? ($s,$p) : $s;
}
#------------------------------------------------


#------------------------------------------------
# check_baseline()
#
# Check if the baseline is valid (exists in Clearcase)
#
# RETURN
#     undef if cleartool cannot be found or no arg is provided
#     0 if the baseline exists
#     1 if not  (ie cleartool lsbl -s xxx  does not know xxx)
# 
#------------------------------------------------
sub check_baseline
{
    my $baseline = shift;

    return undef unless ( defined $baseline );

    my ($e) = cleartool('lsbl -s ', $baseline);
    return $e;
}
#------------------------------------------------


#------------------------------------------------
# compose_baseline()
#
# Compose the baseline using a X.Y.Z-SNAPSHOT notation
# to obtain a comp1_X.Y.Z-SNAPSHOT,comp2_X.Y.Z-SNAPSHOT
# string (or an array).
#
# Assumes cleartool does exists!
#
# RETURN (scalar context)
#     undef if the stream is invalid or cleartool doesn't exist or
#           if there's no such a X.Y.Z-SNAPSHOT on the stream
#     comp1_X.Y.Z-SNAPSHOT,comp2_X.Y.Z-SNAPSHOT,comp3_X.Y.Z-SNAPSHOT
#           if everything's ok
#
# RETURN (array context)
#     (undef) if the stream is invalid or cleartool doesn't exist or
#             if there's no such a X.Y.Z-SNAPSHOT on the stream
#     (comp1_X.Y.Z-SNAPSHOT,comp2_X.Y.Z-SNAPSHOT,comp3_X.Y.Z-SNAPSHOT)
#           if everything's ok
# 
#------------------------------------------------
sub compose_baseline
{
    my $stream = shift;
    my $baseline = shift;

    return undef unless ( defined $stream and defined $baseline );
    return undef unless ( defined check_stream($stream) );

    my $pvob = $stream;
    substr($pvob, 0, index($pvob,'@',0)+1) = '';
    # force $stream to be : stream:xxxx@PVOB
    $stream =~ s/^stream://;
    $stream = "stream:$stream";

    my ($e, @comps) = cleartool("lsstream -fmt '%[components]Np' " . $stream);
    # should not fail as check_stream($stream) validated it as stream:
    return undef unless defined $e;
    return undef if $e;

    my @bls = ();
    for my $c ( @comps ) {
        chomp $c;
        $c =~ s/^component://;
        my $cc = $baseline .'_' . $c . '@' . $pvob ;
        #my $cc = $baseline .'_' . $c;
        my ($e, $bl) = cleartool('lsbl -s ', $cc);
        if ( !defined $e or $e ) {
            WARN "[W] No baseline '$baseline' for component '$c' ($cc).";
        } else {
            push @bls, $cc;
        }
    }

    return undef unless scalar @bls;
    return wantarray ? @bls : ( join ',',@bls);
}
# end of compose_baseline()
#------------------------------------------------


#------------------------------------------------
# make_stream()
#
# Create a read-only stream has child of the 
# given stream on the given set of baselines
# The name of the new stream is build by replacing
# the known extension by '_for_export_Dev'
#
# IN:
#    $parent: the name of the existing parent
#        stream (stream:xxx@pvob OR xxx@pvob)
#
#    $baseline: a coma separated list of baselines
#        for the foundation baseline of the new stream
#
# RETURN:
#    undef if the stream has not been created
#    the name of the new stream if it succeeds
#    In array context, undef is followed by the
#    cleartool error messages.
#
#------------------------------------------------
sub make_stream
{
    my $parent   = shift;
    my $baseline = shift;
    my $suffix   = shift // '_for_export_Dev';   # the _Dev is due to the trigger that allow only a few suffices for the stream name

    return undef unless ( defined $parent and defined $baseline );
    return undef unless ( defined check_stream($parent) );

warn ">>\n";
    my $pvob = $parent;
    substr($pvob, 0, index($pvob,'@',0)+1) = '';
    # force $parent to be : stream:xxxx@PVOB
    $parent =~ s/^stream://;
    $parent = "stream:$parent";

    my $new = $parent;
    substr($new, index($new,'@',0)) = '';
    $new    =~ s/_(ass|dev|mainline|int)?$//i;
    $new   .= $suffix . '@' . $pvob;
    warn ">> [$parent] [$pvob] [$suffix] new = [$new]\n";
    my  $r = check_stream($new);
warn ">> r = " .($r // 'undef' )."\n";
    return undef if ( defined check_stream($new) );
warn ">> new = [$new]\n";

    my ($e,@r) = cleartool('mkstream -in ', $parent, ' -readonly -baseline ', $baseline, $new);
    if (defined $e and $e == 0 ) {
        # success
        return $new;
    } elsif ( defined $e and $e ) {
        # cleartool mkstream complained
        return wantarray ? (undef, @r) : undef;
    } else {
        # other error
        return undef;
    }
}
# end of make_stream()
#------------------------------------------------


#------------------------------------------------
# make_view()
#
# Create a view on the given stgloc
# If a stream is given, create the view on that steam
#
# IN:
#    $tag: the name of the view
#    $stgloc: the name of the storage loc
#    $stream: the name of the stream (or undef)
#
# RETURN:
#    undef if the view has not been created
#    the tag of the new view if it succeeds
#    In array context, undef is followed by the
#    cleartool error messages.
#
#------------------------------------------------
sub make_view
{
    my $tag    =  shift;
    my $stgloc = shift // 'viewstgloc';
    my $stream = shift;

    return undef unless ( defined $tag and defined $stgloc );

    if ( defined $stream ) {
        return undef unless ( defined check_stream($stream) );

        # force $stream to be : stream:xxxx@PVOB
        $stream =~ s/^stream://;
        $stream = "stream:$stream";
    }

    my ($e,@r) = cleartool('mkview -tag ', $tag, (defined $stream ? '-stream '.$stream.' ' : '' ), ' -stgloc ', $stgloc);
    if (defined $e and $e == 0 ) {
        # success
        return $tag;
    } elsif ( defined $e and $e ) {
        # cleartool mkstream complained
        return wantarray ? (undef, @r) : undef;
    } else {
        # other error
        return undef;
    }
}
# end of make_view()
#------------------------------------------------


1;

__DATA__


