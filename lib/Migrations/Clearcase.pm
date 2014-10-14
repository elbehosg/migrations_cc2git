package Migrations::Clearcase;

use strict;
use warnings;
use v5.18;

our $VERSION = '0.0.1';

use Carp;
use Log::Log4perl qw(:easy);

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
    if ( $^O eq 'MSWin32' ) {
        if ( defined $ENV{'PATH'} ) {
            for my $p ( split ';', $ENV{'PATH'} ) {
                if ( -x $p . '\cleartool.exe' ) {
                    return $p . '\cleartool.exe';
                }
            }
        }
        if ( defined $ENV{ATRIA_HOME} ) {
            return $ENV{ATRIA_HOME} . '\bin\cleartool.exe' if ( -x $ENV{ATRIA_HOME} . '\bin\cleartool.exe' );
        }
    } else {
        # Assume cygwin, linux or AIX
        if ( defined $ENV{'PATH'} ) {
            for my $p ( split ':', $ENV{'PATH'} ) {
                if ( -x $p . '/cleartool' ) {
                    return $p . '/cleartool';
                }
            }
        }
        if ( defined $ENV{ATRIA_HOME} ) {
            return $ENV{ATRIA_HOME} . '/bin/cleartool' if ( -x $ENV{ATRIA_HOME} . '/bin/cleartool' );
        }
        return '/usr/atria/bin/cleartool' if ( -x '/usr/atria/bin/cleartool' );
    }
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
            return wantarray ? ( undef ) : undef;
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
# end of set_cleartool()
#------------------------------------------------

1;

__DATA__


