#! perl

use strict;
use warnings;
use lib 't/lib';
use Test::More;# tests => 11;

use Data::Dumper;
use Test::Environment::Git;
use File::Temp qw ( tmpnam );


BEGIN {
    use_ok('Migrations::Migrate');
}

diag("\nTesting Migration-related functions...");

my $h = {  'vob_ma3/donnees-personne-pp' => 'donnees-personne-pp',
           'vob_ma3/lcp' => 'lcp'
        };

my $fname = tmpnam();
diag ("\n    fname = $fname");

my $r = Migrations::Migrate::write_matching_file($h, $fname);
is($r, 0, "Migrations::Migrate::write_matching_file(\$h, $fname)");
{
    open my $fh, '<', $fname or die "Cannot open $fname: $!";
    my $str = '';
    <$fh>;
    while ( <$fh> ) { $str .= $_ };
    close $fh;
    is($str, 'vob_ma3/donnees-personne-pp|donnees-personne-pp
vob_ma3/lcp|lcp
', "Migrations::Migrate::write_matching_file(\$h, $fname)");
};

my $h2 = {};
$r = Migrations::Migrate::read_matching_file($h2,$fname);
is($r, 0, "Migrations::Migrate::read_matching_file(\$h2, $fname)");

#while ( my ($k, $v) = each %$h )  { diag("  h{$k} = $v" ); }
#while ( my ($k, $v) = each %$h2 ) { diag("  h2{$k} = $v"); }

while ( my ($k, $v) = each %$h ) {
   ok( exists($h2->{$k}), "Verif relecture du hash. Cle $k");
   is( $h2->{$k}, $v, "Verif relecture du hash. $k --> $v");
}
while ( my ($k, $v) = each %$h2 ) {
   ok( exists($h->{$k}), "Verif relecture du hash (2). Cle $k");
   is( $h->{$k}, $v, "Verif relecture du hash (2). $k --> $v");
}





$r = Migrations::Migrate::migrate_UCM();
is($r, 2, "Migrations::Migrate::migrate_ucm()");


print "\n";

END {
    if ( -f $fname) { unlink($fname) };
    done_testing();
}



__END__

