#! perl

use strict;
use warnings;
use Test::Mock::Clearcase;
use Test::More;# tests => 20;

use Data::Dumper;

BEGIN {
    diag('Testing Clearcase-related functions, mocking Clearcase...'):
    use_ok('Migrations::Clearcase');
}

my $mock = Test::Mock::Clearcase->new ();

@r = Migrations::Clearcase::cleartool('-ver');
ok(scalar @r > 2, 'Migrations::Clearcase::cleartool(-ver)');
ok($r[0] == 0, 'Migrations::Clearcase::cleartool(-ver)');
ok($r[1] eq 'ClearCase version 8.0.0.01 (Wed Dec 28 01:01:29 EST 2011) (8.0.0.01.00_2011D.FCS)',  'Migrations::Clearcase::cleartool(-ver)');

$r = Migrations::Clearcase::region();
ok($r eq 'Dev_ice_ux', 'Migrations::Clearcase::region()');

$r = Migrations::Clearcase::registry();
ok($r eq 'dgcl04.info.si.socgen', 'Migrations::Clearcase::registry()');

$r = Migrations::Clearcase::is_a_pvob();
ok($r == 2, 'Migrations::Clearcase::is_a_pvob()');
$r = Migrations::Clearcase::is_a_pvob('');
ok($r == 2, 'Migrations::Clearcase::is_a_pvob("")');
$r = Migrations::Clearcase::is_a_pvob('this is not a valid vob tag');
ok($r == 2, 'Migrations::Clearcase::is_a_pvob("this is not a valid vob tag")');
$r = Migrations::Clearcase::is_a_pvob('/vobs/PVOB_MA');
ok($r == 0, 'Migrations::Clearcase::is_a_pvob("/vobs/PVOB_MA")   (PVOB)');
$r = Migrations::Clearcase::is_a_pvob('/vobs/MA1');
ok($r == 1, 'Migrations::Clearcase::is_a_pvob("/vobs/MA1")       (VOB)');
$r = Migrations::Clearcase::is_a_pvob('/vobs/MA');
ok($r == 2, 'Migrations::Clearcase::is_a_pvob("/vobs/MA")        (no tag)');


$r = Migrations::Clearcase::check_stream();
ok(!defined $r, 'Migrations::Clearcase::check_stream()');
$r = Migrations::Clearcase::check_stream('OPE_R9.1_Ass');
ok(!defined $r, 'Migrations::Clearcase::check_stream("OPE_R9.1_Ass")');
$r = Migrations::Clearcase::check_stream('OPE_R9.1_Ass@');
ok(!defined $r, 'Migrations::Clearcase::check_stream("OPE_R9.1_Ass@")');
$r = Migrations::Clearcase::check_stream('@/vobs/PVOB_MA');
ok(!defined $r, 'Migrations::Clearcase::check_stream("@/vobs/PVOB_MA")');

$r = Migrations::Clearcase::check_stream('OPE_R9.1_Ass@/vobs/PVOB_MA');
ok($r eq 'OPE_R9.1_Ass', 'Migrations::Clearcase::check_stream("OPE_R9.1_Ass@/vobs/PVOB_MA")');
@r = Migrations::Clearcase::check_stream('OPE_R9.1_Ass@/vobs/PVOB_MA');
ok((scalar @r == 2 and $r[0] eq 'OPE_R9.1_Ass' and $r[1] eq '/vobs/PVOB_MA'), 'Migrations::Clearcase::check_stream("OPE_R9.1_Ass@/vobs/PVOB_MA")');

$r = Migrations::Clearcase::check_stream('OPE_R9.1_Ass@/vobs/MA1');
ok(!defined, 'Migrations::Clearcase::check_stream("OPE_R9.1_Ass@/vobs/MA1")');
$r = Migrations::Clearcase::check_stream('no_such_a_stream@/vobs/PVOB_MA');
ok(!defined $r, 'Migrations::Clearcase::check_stream("no_such_a_stream@/vobs/PVOB_MA")');


print "\n";

END {
    done_testing();
}



__END__

from Migrations::Parameters


my @list;
#----- Migrations::Parameters::list_for_getopt() -----
eval {
  @list = Migrations::Parameters::list_for_getopt();
};
# expect failure
ok($@, 'Call Migrations::Parameters::list_for_getopt without parms');

eval {
  @list = Migrations::Parameters::list_for_getopt(
    {
      arg1 => { mandatory => 1, getopt => 'arg1=s'},
      arg2 => { optional  => 1,                    default => 0 },
      arg3 => { optional  => 1, getopt => 'arg3!', default => 0 },
    }
 );
};
# expect success
ok(!$@, 'Call Migrations::Parameters::list_for_getopt with a hash ref');
my ($v1,$v2,$v3) = sort @list;
my $res = ($v1 eq 'arg1=s' and $v2 eq 'arg3!' and !defined $v3 );
ok( $res, 'Migrations::Parameters::list_for_getopt(arg1,arg2,arg3)');
@list = Migrations::Parameters::list_for_getopt( { } );
ok( scalar @list == 0, 'Call Migrations::Parameters::list_for_getopt with {}');




my %expected = (
    a1 => { mandatory => 1, getopt => 'a1=s', },
    a2 => { mandatory => 1, getopt => 'a2=i', },
    a3 => { optional  => 1, getopt => 'a3!', default => 0, },
    a4 => { mandatory_unless => [ 'a5' ], getopt => 'a4', },
    a5 => { mandatory_unless => [ 'a4' ], getopt => 'a5', },
    a6 => { optional  => 1, getopt => 'a6', default => 0, exclude => [ 'a7', 'a8' ], },
    a7 => { optional  => 1, getopt => 'a7', exclude => [ 'a6' ], },
    a8 => { optional  => 1, getopt => 'a8!', default => 1, },
    );
my %opt;
my $i;
my $title;


sub my_test_report
{
    my $title = shift;  # string
    my $r = shift;      # real err code
    my $opt = shift;    # hash ref
    my @exp = @_;       # expected values for r, a1..

    my $i = 0;
    ok($r==$exp[0],                                                        $title . $i++);
    ok((defined $exp[$i] ? $opt->{a1} eq $exp[$i] : !defined $opt->{a1} ), $title . $i++);
    ok((defined $exp[$i] ? $opt->{a2} == $exp[$i] : !defined $opt->{a2} ), $title . $i++);
    ok((defined $exp[$i] ? $opt->{a3} == $exp[$i] : !defined $opt->{a3} ), $title . $i++);
    ok((defined $exp[$i] ? $opt->{a4} eq $exp[$i] : !defined $opt->{a4} ), $title . $i++);
    ok((defined $exp[$i] ? $opt->{a5} eq $exp[$i] : !defined $opt->{a5} ), $title . $i++);
    ok((defined $exp[$i] ? $opt->{a6} == $exp[$i] : !defined $opt->{a6} ), $title . $i++);
    ok((defined $exp[$i] ? $opt->{a7} == $exp[$i] : !defined $opt->{a7} ), $title . $i++);
    ok((defined $exp[$i] ? $opt->{a8} == $exp[$i] : !defined $opt->{a8} ), $title . $i++);

}

%opt = ( a1 => 'foo', a2 => 42, a4 => 1, );
$r = Migrations::Parameters::validate_arguments(\%opt,\%expected);
my_test_report('M::P::validate_arguments all fine 1.', $r, \%opt, ( 0, 'foo', 42, 0, 1, undef, 0, undef, 1 ) );

%opt = ( a1 => 'foo', a2 => 42, a5 => 1, );
$r = Migrations::Parameters::validate_arguments(\%opt,\%expected);
my_test_report('M::P::validate_arguments all fine 2.', $r, \%opt, ( 0, 'foo', 42, 0, undef, 1, 0, undef, 1 ) );

%opt = ( a1 => 'foo', a2 => 42, a3 => 1, a4 => 1, a5 => 1, a7 => 1, a8 => 1, );
$r = Migrations::Parameters::validate_arguments(\%opt,\%expected);
my_test_report('M::P::validate_arguments all fine 6.', $r, \%opt, ( 0, 'foo', 42, 1, 1, 1, 0, 1, 1 ) );

%opt = ( a2 => 42, a3 => 1, a4 => 1, );
$r = Migrations::Parameters::validate_arguments(\%opt,\%expected);
my_test_report('M::P::validate_arguments missing mandatory args 1.', $r, \%opt, ( 1, undef, 42, 1, 1, undef, 0, undef, 1 ) );

%opt = ( a1 => 'foo', a2 => 42, a3 => 1, );
$r = Migrations::Parameters::validate_arguments(\%opt,\%expected);
my_test_report('M::P::validate_arguments missing mandatory args 2.', $r, \%opt, ( 1, 'foo', 42, 1, undef, undef, 0, undef, 1 ) );

%opt = ( a1 => 'foo', a2 => 42, a3 => 1, a4 => 1, a6 => 1, a8 => 0, );
$r = Migrations::Parameters::validate_arguments(\%opt,\%expected);
my_test_report('M::P::validate_arguments exclusive args 3.', $r, \%opt, ( 2, 'foo', 42, 1, 1, undef, 1, undef, 0 ) );


__END__

