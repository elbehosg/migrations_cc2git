#! perl

use strict;
use warnings;
use lib 't/lib';
use Test::More tests => 13;

use Data::Dumper;
use Test::Environment::Git;

BEGIN {
    use_ok('Migrations::Git');
}

diag("\nTesting Git-related functions...");

my $git = Migrations::Git::where_is_git();
if ( defined $git ) {
    diag("git found at [$git]");
    ok(-x $git, "git is known.");
} else {
    ok(1, 'Cannot find git neither in PATH nor /usr/bin (*nix only).');
}

SKIP: {
    skip 'git is not installed.', 11 if ( ! defined $git);
    
    my $r = Migrations::Git::git('--booh');
    is($r, 'Unknown option: --booh
usage: git [--version] [--help] [-C <path>] [-c name=value]
           [--exec-path[=<path>]] [--html-path] [--man-path] [--info-path]
           [-p|--paginate|--no-pager] [--no-replace-objects] [--bare]
           [--git-dir=<path>] [--work-tree=<path>] [--namespace=<name>]
           <command> [<args>]
', 'Migrations::Git::git(--booh)');
    my @r = Migrations::Git::git('--booh');
    ok(scalar @r == 7, 'Migrations::Git::git(--booh)');
    is($r[0], '129', 'Migrations::Git::git(-booh)');
    is($r[1], 'Unknown option: --booh
', 'Migrations::Git::git(-booh)');

    @r = Migrations::Git::git('--version');
    ok(scalar @r == 2, 'Migrations::Git::git(--version)');
    is($r[0], '0', 'Migrations::Git::git(--version)');
    is(substr($r[1],0, 12), 'git version ', 'Migrations::Git::git(--version)');
    ok($r[0] == 0, 'Migrations::Git::git(--version)');

    diag("Initialize a test repo...");
    my $repo = Test::Environment::Git->new('make_test');
    $repo->InitRepo();
    $repo->CommitA();
    $repo->CommitB();
    $repo->CommitC();
    $r = Migrations::Git::check_local_repo();
    is($r, '0', 'Migrations::Git::check_local_repo()');
diag("---------------------------");
    $r = Migrations::Git::check_local_repo($repo->{dirname});
    is($r, '0', 'Migrations::Git::check_local_repo(repo->{dirname})');
    $r = Migrations::Git::check_local_repo($repo->{fullname});
    is($r, '1', 'Migrations::Git::check_local_repo(repo->{fullname})');
}

print "\n";

END {
    done_testing();
}



__END__

