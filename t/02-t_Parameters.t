#! perl

use strict;
use warnings;
use Test::More ; #tests => 5;

BEGIN {
        use_ok("Migrations::Parameters");
}

eval {
  my %opt;
  my @m;
  my @o;
  my @e;
  Migrations::Parameters::command_line_analysis(\%opt, \@m, \@o, \@e);
};
ok(!$@, "Call Migrations::Parameters::command_line_analysis w/o parms");
#if($@) {
#ok(0, "Call Migrations::Parameters::command_line_analysis w/o parms");
#} else {
#ok(1, "Call Migrations::Parameters::command_line_analysis w/o parms");
#}

print "\n";

END {
        done_testing();
}

__END__

