package Test::Environment::Git;

use strict;
use warnings;
use v5.18;

our $VERSION = '0.0.1';

use File::Spec;
use File::Path qw(remove_tree);
use IPC::Run;


sub new
{
    my $class = shift;
    my $reponame = shift // 'testrepo';
    my $persistent = shift // 0;

    my $self = {};
    $self->{basename} = $reponame;
    $self->{dirname} = File::Spec->tmpdir();
    $self->{fullname} = File::Spec->catdir(File::Spec->splitdir($self->{dirname}), $reponame);
    $self->{persistent} = $persistent;

    bless $self, $class;
    return $self;
}

sub DESTROY
{
    my $self = shift;
    unless ( $self->{persistent} ) {
        $self->ResetRepo();
    }
}

sub TestIfGitExists
{
    my $self = shift;
    my ($in,$out,$err);
    eval {
        IPC::Run::run([ 'git' ,'--version' ] ,\$in,\$out,\$err); 
    };
    return ($@) ? 0 : 1;
}

sub GitAdd
{
    my $self = shift;
    my @elt = @_;

    if ( scalar @elt == 0 ) {
        @elt = ('-A');
    }
    my ($in,$out,$err);
    my @cmd = ( 'git', 'add', @elt );
    my $ret = IPC::Run::run(\@cmd,\$in,\$out,\$err); 
    $self->{last_stdout} = $out;
    $self->{last_stderr} = $err;
    return $ret;
}

sub GitCommit
{
    my $self = shift;
    my $comment = shift // 'no comment';
    my ($in,$out,$err);
    my @cmd = ( 'git', 'commit', '-m', $comment );
    my $ret = IPC::Run::run(\@cmd,\$in,\$out,\$err); 
    $self->{last_stdout} = $out;
    $self->{last_stderr} = $err;
    return $ret;
}

sub GitBranch
{
    my $self = shift;
    my $branch = shift;
    die 'GitBranch called without branch name to create' unless ( defined $branch and $branch ne '' );
    my ($in,$out,$err);
    my @cmd = ( 'git', 'branch', $branch );
    my $ret = IPC::Run::run(\@cmd,\$in,\$out,\$err); 
    $self->{last_stdout} = $out;
    $self->{last_stderr} = $err;
    return $ret;
}

sub InitRepo
{
    my $self = shift;
    return undef if ( ! $self->TestIfGitExists() );

    my $old = File::Spec->curdir;
    chdir($self->{dirname});
    my ($in,$out,$err);
    my @cmd = ( 'git', 'init', $self->{'basename'} );
    my $ret = IPC::Run::run(\@cmd,\$in,\$out,\$err); 
    $self->{last_stdout} = $out;
    $self->{last_stderr} = $err;
    chdir($old);
    return $ret;
}

sub Branch
{
    my $self = shift;

    my $old = File::Spec->curdir;
    chdir($self->{fullname});
    $self->GitBranch(@_);
    chdir($old);
}

sub CommitA
{
    my $self = shift;

    my $old = File::Spec->curdir;
    chdir($self->{fullname});
    open my $f, '>', 'file1.txt' or die "Cannot create file1.txt in $self->{fullname}. Abort.\n";
    for my $i ( 1..5 ) {
        $_ = <DATA>;
        print $f $_;
    }
    close $f;
    open $f, '>', '.gitignore' or die "Cannot create .gitignore in $self->{fullname}. Abort.\n";
    print $f 'Makefile
*.swp
MYMETA.json
MYMETA.yml
blib
pm_to_blib
';
    close $f;

    $self->GitAdd();
    $self->GitCommit('A');
    chdir($old);
}

sub CommitB
{
    my $self = shift;

    my $old = File::Spec->curdir;
    chdir($self->{fullname});
    mkdir 'dir1';
    chdir('dir1');
    open my $f, '>', 'file2.txt' or die "Cannot create file2.txt in $self->{fullname} / dir1 . Abort.\n";
    for my $i ( 1..5 ) {
        $_ = <DATA>;
        print $f $_;
    }
    close $f;

    chdir('..');
    $self->GitAdd();
    $self->GitCommit('B');
    chdir($old);
}

sub CommitC
{
    my $self = shift;

    my $old = File::Spec->curdir;
    chdir($self->{fullname});
    open my $f, '>', 'file1.txt' or die "Cannot modify file1.txt in $self->{fullname}. Abort.\n";
    for my $i ( 1..3 ) {
        $_ = <DATA>;
        print $f $_;
    }
    print $f "\n";
    print $f "\n";
    for my $i ( 1..3 ) {
        $_ = <DATA>;
        print $f $_;
    }

    close $f;
    $self->GitAdd();
    $self->GitCommit('C');
    chdir($old);
}

sub ResetRepo
{
    my $self = shift;
    my $old = File::Spec->curdir;
    chdir($self->{dirname});
    if ( -d $self->{basename} ) {
        remove_tree ($self->{basename}, { error => $self->{last_err} });
    }
    chdir($old);
}



1;

__DATA__


Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut luctus sollicitudin 
posuere. Nulla facilisi. Vestibulum vitae fermentum neque, nec rhoncus tellus. 
Quisque bibendum malesuada ligula, sit amet maximus massa commodo ut. Proin 
quis urna ante. Nulla volutpat leo velit, at placerat dui rutrum a. Vestibulum 
vulputate rhoncus lectus vel vestibulum. 
Duis varius, eros eget iaculis pellentesque, enim odio elementum est, 
et euismod sapien erat sit amet ipsum. Ut fringilla, sapien et porttitor 
feugiat, lectus lorem sollicitudin lectus, non consequat elit massa sed sem. 
Nam sodales eget magna in convallis. Sed bibendum vel erat et accumsan. 
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut luctus sollicitudin 
posuere. Nulla facilisi. Vestibulum vitae fermentum neque, nec rhoncus tellus. 
Quisque bibendum malesuada ligula, sit amet maximus massa commodo ut. 
Duis malesuada molestie lorem eu pellentesque. Nunc volutpat euismod 
risus nec fermentum. Nam ac libero in urna tristique auctor sed rutrum nulla. 
Praesent augue urna, fermentum id massa sed, mattis varius nisi. Ut 
condimentum vehicula felis vel imperdiet. In eu ante sit amet purus aliquet 
fermentum. Pellentesque id quam fermentum est tempus lacinia non sed felis. 
Integer euismod augue turpis. Nullam rhoncus magna vel lacus vehicula molestie. 



