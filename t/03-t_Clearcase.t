#! perl

use strict;
use warnings;
use Test::More tests => 7;

use Data::Dumper;

BEGIN {
    use_ok('Migrations::Clearcase');
}

diag("\nTesting Clearcase-related functions...");

my $ct = Migrations::Clearcase::where_is_cleartool();
if ( defined $ct ) {
    diag("cleartool found at [$ct]");
    ok(-x $ct, "cleartool is known.");
} else {
    ok(1, "Cannot find cleartool neither in PATH, ATRIA_HOME/bin nor /usr/atria/bin (*nix only).");
}

SKIP: {
    skip 'clearcase is not installed.', 5 if ( ! defined $ct);
    
    my $r = Migrations::Clearcase::cleartool('-booh');
    is($r, 'cleartool: Error: Unrecognized command: "-booh"
', 'Migrations::Clearcase::cleartool(-booh)');
    my @r = Migrations::Clearcase::cleartool('-booh');
    ok(scalar @r == 2, 'Migrations::Clearcase::cleartool(-booh)');
    ok( ($r[0] == 1 and $r[1] eq 'cleartool: Error: Unrecognized command: "-booh"
'), 'Migrations::Clearcase::cleartool(-booh)');

    @r = Migrations::Clearcase::cleartool('-ver');
    ok(scalar @r > 2, 'Migrations::Clearcase::cleartool(-ver)');
    ok($r[0] == 0, 'Migrations::Clearcase::cleartool(-ver)');
}

print "\n";

END {
    done_testing();
}



__END__

