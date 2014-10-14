#! perl

use strict;
use warnings;
use Test::More  tests => 4;

BEGIN {
        use_ok("Migrations::Parameters");
        use_ok("Migrations::Clearcase");
        use_ok("Migrations::Git");
        use_ok("Migrations::Migrate");
}

print "\n";

END {
        done_testing();
}

__END__

