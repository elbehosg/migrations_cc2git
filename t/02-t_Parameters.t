#! perl

use strict;
use warnings;
use Test::More tests => 10;

BEGIN {
        use_ok("Migrations::Parameters");
}


my @list;
#----- Migrations::Parameters::list_for_getopt() -----
eval {
  @list = Migrations::Parameters::list_for_getopt();
};
# expect failure
ok($@, "Call Migrations::Parameters::list_for_getopt without parms");

eval {
  @list = Migrations::Parameters::list_for_getopt("a string");
};
# expect failure
ok($@, "Call Migrations::Parameters::list_for_getopt with a scalar");

eval {
  @list = Migrations::Parameters::list_for_getopt([ qw ( array ref ) ]);
};
# expect failure
ok($@, "Call Migrations::Parameters::list_for_getopt with a array ref");

eval {
  @list = Migrations::Parameters::list_for_getopt(
    {
      arg1 => { mandatory => 1, getopt => "arg1=s"},
      arg2 => { optional  => 1,                    default => 0 },
      arg3 => { optional  => 1, getopt => "arg3!", default => 0 },
    }
 );
};
# expect success
ok(!$@, "Call Migrations::Parameters::list_for_getopt with a hash ref");
my ($v1,$v2,$v3) = sort @list;
my $res = ($v1 eq 'arg1=s' and $v2 eq 'arg3!' and !defined $v3 );
ok( $res, "Migrations::Parameters::list_for_getopt(arg1,arg2,arg3)");
@list = Migrations::Parameters::list_for_getopt( { } );
ok( scalar @list == 0, "Call Migrations::Parameters::list_for_getopt with {}");



#----- Migrations::Parameters::validate_arguments() -----
eval {
  Migrations::Parameters::validate_arguments();
};
# expect failure
ok($@, "Call Migrations::Parameters::validate_arguments() without parms");

eval {
  my ($a,$b);
  Migrations::Parameters::validate_arguments($a,$b);
};
# expect failure
ok($@, "Call Migrations::Parameters::validate_arguments() badly typed parms");

eval {
  my (%a,%b);
  Migrations::Parameters::validate_arguments(\%a,\%b);
};
# expect success
ok(!$@, "Call Migrations::Parameters::validate_arguments() empty parameters");


print "\n";

END {
        done_testing();
}

__END__

