#! perl

use strict;
use warnings;
use lib 't/lib';
use Test::More;# tests => 11;

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
    skip 'git is not installed.', 9 if ( ! defined $git);
    
    my $r = Migrations::Git::git('--booh');
    is($r, 'Unknown option: --booh
usage: git [--version] [--help] [-C <path>] [-c name=value]
           [--exec-path[=<path>]] [--html-path] [--man-path] [--info-path]
           [-p|--paginate|--no-pager] [--no-replace-objects] [--bare]
           [--git-dir=<path>] [--work-tree=<path>] [--namespace=<name>]
           <command> [<args>]
', 'Migrations::Git::git(--booh)');
    my @r = Migrations::Git::git('--booh');
    is($r[0], 0, 'Migrations::Git::git(-booh)');
    is($r[1], '', 'Migrations::Git::git(-booh)');
    is($r[2], 'Unknown option: --booh
usage: git [--version] [--help] [-C <path>] [-c name=value]
           [--exec-path[=<path>]] [--html-path] [--man-path] [--info-path]
           [-p|--paginate|--no-pager] [--no-replace-objects] [--bare]
           [--git-dir=<path>] [--work-tree=<path>] [--namespace=<name>]
           <command> [<args>]
', 'Migrations::Git::git(-booh)');

    @r = Migrations::Git::git('--version');
    is($r[0], 0, 'Migrations::Git::git(--version)');
    is(substr($r[1],0, 12), 'git version ', 'Migrations::Git::git(--version)');
    #ok($r[0] == 0, 'Migrations::Git::git(--version)');

    diag("Initialize a test repo...");
    my $repo = Test::Environment::Git->new('make_test',0);
    $repo->InitRepo();
    $repo->CommitA();
    $repo->Branch('brA');
    $repo->Tag('tagsT1');
    $repo->CommitB();
    $repo->Branch('brAnchB');
    $repo->CommitC();
    $repo->Tag('tags/T4');
    $repo->Branch('branChC');
    $r = Migrations::Git::check_local_repo();
    is($r, '0', 'Migrations::Git::check_local_repo()');
    $r = Migrations::Git::check_local_repo($repo->{dirname});
    is($r, '0', 'Migrations::Git::check_local_repo(repo->{dirname})');
    $r = Migrations::Git::check_local_repo($repo->{fullname});
    is($r, '1', 'Migrations::Git::check_local_repo(repo->{fullname})');

    $r = Migrations::Git::check_branch();
    is($r, undef, 'Migrations::Git::check_branch()');
    $r = Migrations::Git::check_branch($repo->{fullname});
    is($r, undef, 'Migrations::Git::check_branch($repo->{fullname})');
    $r = Migrations::Git::check_branch('make_test22');
    is($r, undef, 'Migrations::Git::check_branch(make_test22)');
    $r = Migrations::Git::check_branch($repo->{fullname},'brAnchb');
    is($r, '0', 'Migrations::Git::check_branch(make_test,brAnchb)');
    $r = Migrations::Git::check_branch($repo->{fullname},'brA');
    is($r, '1', 'Migrations::Git::check_branch(make_test,brA)');

    $r = Migrations::Git::check_tag();
    is($r, undef, 'Migrations::Git::check_tag()');
    $r = Migrations::Git::check_tag($repo->{fullname});
    is($r, undef, 'Migrations::Git::check_tag($repo->{fullname})');
    $r = Migrations::Git::check_tag('make_test22');
    is($r, undef, 'Migrations::Git::check_tag(make_test22)');
    $r = Migrations::Git::check_tag($repo->{fullname},'tags/t4');
    is($r, '0', 'Migrations::Git::check_tag(make_test,tags/t4)');
    $r = Migrations::Git::check_tag($repo->{fullname},'tagsT1');
    is($r, '1', 'Migrations::Git::check_tag(make_test,tagsT1)');


    diag('Check a remote repo (testing)...');
    $r = Migrations::Git::check_remote_repo();
    is($r, '0', 'Migrations::Git::check_remote_repo()');
    $r = Migrations::Git::check_remote_repo('http://dgcllx12.dns21.socgen:8080/git/info?testing');
    is($r, '401', 'Migrations::Git::check_remote_repo(http://dgcllx12.dns21.socgen:8080/git?testing)');
    $r = Migrations::Git::check_remote_repo('http://dgcllx12.dns21.socgen:8080/git/info?testing)', 'x120248', '');
    is($r, '401', 'Migrations::Git::check_remote_repo(http://dgcllx12.dns21.socgen:8080/git/info?testing, x120248, )');
    $r = Migrations::Git::check_remote_repo('http://dgcllx12.dns21.socgen:8080/git/info?testing', 'x120248', '=eeB4oode');
    is($r, '1', 'Migrations::Git::check_remote_repo(http://dgcllx12.dns21.socgen:8080/git?testing, x120248, s3cr3t)');
}

print "\n";

END {
    done_testing();
}



__END__

