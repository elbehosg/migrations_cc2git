package Migrations::Git;

use strict;
use warnings;
use v5.18;

our $VERSION = '1.0';

use Carp;
use Log::Log4perl qw(:easy);
use File::Spec;
use IPC::Run;
use LWP::UserAgent;

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
#    what the command returned on STDOUT or 
#        on STDERR if there's nothing on STDOUT
#    or undef if the command cannot be run
#
#    ARRAY context:
#    the return code of IPC::Run::run(git,arg1,arg2)  as 1st element,
#    STDOUT as 2nd arg, STDERR as 3rd arg
#    If IPC::Run::run() raises an execption, it returns (undef,$@)
# 
#------------------------------------------------
sub git
{
    state $GIT;
    if ( !defined $GIT ) {
        INFO "Searching git...";
        $GIT = where_is_git();
        if ( !defined $GIT ) {
            return undef;
        }
        INFO "git is $GIT";
    }

    if ( scalar @_ == 0 ) {
        INFO "Calling: git <no args>";
        return wantarray ? () : '';
    }
    
    my @args = @_;
    INFO "Calling: git " . ( join ' ',@args );

    # Assume the arguments have been sanitized
    # (They should not come from the user)
    my ($in,$r,$out,$err);
    my @cmd = ( $GIT, @args );
    eval {
        # /!\ run() and finish() return TRUE when all subcommands exit with a 0 result code
        #     and raise an exception on errors
        $r = IPC::Run::run(\@cmd,\$in,\$out,\$err);
    };
    if ( $@ ) {
        return wantarray ? (undef, $@) : undef;
    } else {
        return wantarray ? (0,$out,$err) : ($out||$err);
    }
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
    my $repo = substr($url, index($url, '?')+1);

    my $ua = LWP::UserAgent->new( agent => 'Mozilla/5.0 (Windows NT 6.1; WOW64; rv:17.0) Gecko/20100101 Firefox/17.0');
    my $req = HTTP::Request->new(GET => "$url");
    my $res = $ua->request($req);
    #DEBUG "[" . $req->uri . "] code : " . $res->code . "\n"; # commented out because it may display crendentials
    DEBUG "[url hidden] code        : " . $res->code . "\n";
    DEBUG "[url hidden] status_line : " . $res->status_line . "\n";
    DEBUG "[url hidden] content     : " . $res->content . "\n";

    unless ( $res->is_success ) {
        WARN "Error on [$url]: " . $res->status_line . "\n";
        return wantarray ? ($res->code, $res->status_line) : $res->code ;
    }

    my @l = split '\n',$res->content;
    shift @l;
    shift @l;

    for my $r ( @l ) {
        return 1 if ( substr($r, 5) eq $repo );
    }
    return 0;
}
# end of check_remote_repo()
#------------------------------------------------


#------------------------------------------------
# check_branch
#
# Check if the branch exists in the local repo
#
# IN:
#    $repo   = the local repo
#    $branch = the branch in the local repo (or not)
#
# RETURN:
#    1 if the branch exists in the repo
#    0 if not
#    0 if the repo does not exist
#    undef if an argument is missing
#
#------------------------------------------------
sub check_branch
{
    my $repo   = shift;
    my $branch = shift;

    return undef unless ( defined $repo and defined $branch);
    return 0 unless ( check_local_repo($repo) );

    my $return = 4;
    my $cwd = File::Spec->curdir();
    chdir $repo;
    my ($r,$o,$e) = git('branch', '--list');
    if ( length $o ) {
        $return=grep { substr($_,2) eq $branch } split ('\n', $o);
    } else {
        $return = 0;
    }
    chdir $cwd;

    return $return;
}
# end of check_branch()
#------------------------------------------------


#------------------------------------------------
# check_tag
#
# Check if the tag exists in the local repo
#
# IN:
#    $repo = the local repo
#    $tag  = the tag in the local repo (or not)
#
# RETURN:
#    1 if the tag exists in the repo
#    0 if not
#    0 if the repo does not exist
#    undef if an argument is missing
#
#------------------------------------------------
sub check_tag
{
    my $repo   = shift;
    my $tag = shift;

    return undef unless ( defined $repo and defined $tag);
    return 0 unless ( check_local_repo($repo) );

    my $return = 4;
    my $cwd = File::Spec->curdir();
    chdir $repo;
    my ($r,$o,$e) = git('tag');
    if ( length $o ) {
        $return=grep { $_ eq $tag } split ('\n', $o);
    } else {
        $return = 0;
    }
    chdir $cwd;

    return $return;
}
# end of check_tag()
#------------------------------------------------





1;

__DATA__


