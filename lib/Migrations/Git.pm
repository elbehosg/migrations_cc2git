package Migrations::Git;

use strict;
use warnings;
use v5.18;

our $VERSION = '0.0.1';

use Carp;
use Log::Log4perl qw(:easy);
use File::Spec;

#------------------------------------------------
# 
# Git commands
# 
#------------------------------------------------

#------------------------------------------------
# where_is_git()
#   
# Locate cleartool (or cleartool.exe) :
# - in PATH
# - in /usr/bin   (unix-like only)
#
#  RETURN
#      fullpath to git (or git.exe) 
#      or
#      undef   if git cannot be find
#------------------------------------------------
sub where_is_git
{
    my $git = 'git';
    if ( $^O eq 'MSWin32' or $^O eq 'cygwin' ) {
        $git = 'git.exe';
    }

    if ( defined $ENV{'PATH'} ) {
        for my $p ( File::Spec->path() ) {
           my @d = File::Spec->splitdir($p) ;
           my $f = File::Spec->catfile(@d, $git);
           return $f if ( -x $f );
           return $f if ( -f $f and $^O eq 'cygwin' );
        }
    }

    my @d = File::Spec->splitdir('/usr/bin');
    my $f = File::Spec->catfile(@d, $git);
    return $f if ( -x $f );
    return $f if ( -f $f and $^O eq 'cygwin' );

    return undef;
}
# end of where_is_git()
#------------------------------------------------



#------------------------------------------------
# git
#
# Execute the command git with the given arguments
# ASSUME THE ARGUMENTS HAVE BEEN SANITIZED
#
# WARNINGS:
#    1. arguments have been sanitized
#    2. not suitable for interactive commands
#
# RETURN with or without argument;
#    undef is git command cannot be found
# RETURN without argument:
#    SCALAR: ''
#    ARRAY : ()
# RETURN with arguments:
#    SCALAR context:
#    what the command returned on STDOUT+STDERR
#
#    ARRAY context:
#    (undef) if git cannot be found
#    the return code of git as 1st element,
#    then each line of STDOUT+STDERR (1 line = 1 element)
# 
#------------------------------------------------
sub git
{
    state $GIT;
    if ( !defined $GIT ) {
        INFO "[I] Searching git...";
        $GIT = where_is_git();
        if ( !defined $GIT ) {
            return undef;
        }
        INFO "[I] git is $GIT";
    }

    if ( scalar @_ == 0 ) {
        INFO "[I] Calling: git <no args>";
        return wantarray ? () : '';
    }
    
    my @args = @_;
    INFO "[I] Calling: git " . ( join ' ',@args );

    # Assume the arguments have been sanitized
    # (They should not come from the user)
    my $cmd = join ' ', $GIT, @args;
    # cannot use open with a list because redirect of STDERR does not work
    # to improve, have a look on IPC::Open3 or IPC::Run or alike
    open my $git, '-|', $cmd . ' 2>&1'      or LOGDIE "[F] Cannot execute $cmd. Abort.";
    my @ret = <$git>;
    close $git;
    my $r = $? >>8;
    return wantarray ? ($r, @ret) : (join '', @ret);

}
# end of git()
#------------------------------------------------


#------------------------------------------------
# check_local_repo
#
# Check if the repo does exist on path
#
# IN:
#    $repo = the path to check
#
# RETURN in scalar context:
#    1 if the repo exist
#    0 if it does not
#
#------------------------------------------------
sub check_local_repo
{
    my $repo = shift;

    return 0 unless ( defined $repo );

    my $path;
    if ( ref $repo eq 'ARRAY' ) {
        $path = File::Spec->catdir(@$repo, '.git');
    } elsif ( scalar @_ ) {
        $path = File::Spec->catdir($repo, @_, '.git');
    } else {
        # we just append .git at the end of the path
        $path = File::Spec->catdir(File::Spec->splitdir($repo),'.git');;
    }

    return ( -d $path ? 1 : 0 );
}
# end of check_local_repo()
#------------------------------------------------


#------------------------------------------------
# check_remote_repo
#
# Check if the URL is a Git repository that one can access
#
# IN:
#    $url = the URL to check
#
# RETURN in scalar context:
#    1 if the repo exist and can be cloned
#    0 if not
#
#------------------------------------------------
sub check_remote_repo
{
    my $url = shift;
    my $user = shift // '';
    my $pass = shift // '';

    return 0 unless ( defined $url );
 
    if ( $user ne '') {
        unless ( $url =~ m%//:\w+(?:\w+)?@% ) {
            # unless URL already contains credentials:
            $url =~s%://%://$user:$pass\@%;
        }
    }
    my $repo = substr($url, index($url, '?'));

    my $ua = LWP::UserAgent->new( agent => 'Mozilla/5.0 (Windows NT 6.1; WOW64; rv:17.0) Gecko/20100101 Firefox/17.0');
    my $req = HTTP::Request->new(GET => "$url");
    my $res = $ua->request($req);
    #DEBUG "[D] [" . $req->uri . "] code : " . $res->code . "\n"; # commented out because it may display crendentials

    unless ( $res->is_success ) {
        WARN "[W] Error on [$url]: " . $res->status_line . "\n";
        return wantarray ? (0, $res->status_line) : 0;
    }

    my @l = split '\n',$res->content;
    shift @l;
    shift @l;

    if ( defined $l[0] ) {
        return 1 if ( substr($l[0], 8) eq $repo )
    }
    return 0;
}
# end of check_remote_repo()
#------------------------------------------------


#------------------------------------------------
#------------------------------------------------
sub clone_repo
{
    my $url = shift;
    my $dirname = shift;
    my $clone = shift;
    my $user = shift;
    my $pass = shift;

    # check args
    # check $path
    # check repo ?
    # clone
    # return 

}
# end of clone_repo()
#------------------------------------------------





1;

__DATA__


