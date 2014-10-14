#! perl

use strict;
use warnings;
use lib 't/lib';
use Test::Mock::Clearcase;
use Test::More;# tests => 20;

use Data::Dumper;

BEGIN {
    use_ok('Migrations::Clearcase');
}

diag("\nTesting Clearcase-related functions, mocking Clearcase...");
my $mock = Test::Mock::Clearcase->new ();

my @r = Migrations::Clearcase::cleartool('-ver');
ok(scalar @r > 2, '04.01.01 - Migrations::Clearcase::cleartool(-ver)');
ok($r[0] == 0, '04.01.02 - Migrations::Clearcase::cleartool(-ver)');
ok($r[1] eq 'ClearCase version 8.0.0.01 (Wed Dec 28 01:01:29 EST 2011) (8.0.0.01.00_2011D.FCS)',  '04.01.03 - Migrations::Clearcase::cleartool(-ver)');

my $r = Migrations::Clearcase::region();
ok($r eq 'Dev_ice_ux', '04.01.04 - Migrations::Clearcase::region()');

$r = Migrations::Clearcase::registry();
ok($r eq 'dgcl04.info.si.socgen', '04.01.05 - Migrations::Clearcase::registry()');

$r = Migrations::Clearcase::is_a_pvob();
ok($r == 2, '04.02.01 - Migrations::Clearcase::is_a_pvob()');
$r = Migrations::Clearcase::is_a_pvob('');
ok($r == 2, '04.02.02 - Migrations::Clearcase::is_a_pvob("")');
$r = Migrations::Clearcase::is_a_pvob('this is not a valid vob tag');
ok($r == 2, '04.02.03 - Migrations::Clearcase::is_a_pvob("this is not a valid vob tag")');
$r = Migrations::Clearcase::is_a_pvob('/vobs/PVOB_MA');
ok($r == 0, '04.02.04 - Migrations::Clearcase::is_a_pvob("/vobs/PVOB_MA")   (PVOB)');
$r = Migrations::Clearcase::is_a_pvob('/vobs/MA1');
ok($r == 1, '04.02.05 - Migrations::Clearcase::is_a_pvob("/vobs/MA1")       (VOB)');
$r = Migrations::Clearcase::is_a_pvob('/vobs/MA');
ok($r == 2, '04.02.06 - Migrations::Clearcase::is_a_pvob("/vobs/MA")        (no tag)');


$r = Migrations::Clearcase::check_stream();
ok(!defined $r, '04.03.01 - Migrations::Clearcase::check_stream()');
$r = Migrations::Clearcase::check_stream('OPE_R9.1_Ass');
ok(!defined $r, '04.03.02 - Migrations::Clearcase::check_stream("OPE_R9.1_Ass")');
$r = Migrations::Clearcase::check_stream('stream:OPE_R9.1_Ass');
ok(!defined $r, '04.03.03 - Migrations::Clearcase::check_stream("stream:OPE_R9.1_Ass")');
$r = Migrations::Clearcase::check_stream('OPE_R9.1_Ass@');
ok(!defined $r, '04.03.04 - Migrations::Clearcase::check_stream("OPE_R9.1_Ass@")');
$r = Migrations::Clearcase::check_stream('stream:OPE_R9.1_Ass@');
ok(!defined $r, '04.03.05 - Migrations::Clearcase::check_stream("stream:OPE_R9.1_Ass@")');
$r = Migrations::Clearcase::check_stream('@/vobs/PVOB_MA');
ok(!defined $r, '04.03.06 - Migrations::Clearcase::check_stream("@/vobs/PVOB_MA")');

$r = Migrations::Clearcase::check_stream('OPE_R9.1_Ass@/vobs/PVOB_MA');
ok($r eq 'OPE_R9.1_Ass', '04.03.07 - Migrations::Clearcase::check_stream("OPE_R9.1_Ass@/vobs/PVOB_MA")');
$r = Migrations::Clearcase::check_stream('stream:OPE_R9.1_Ass@/vobs/PVOB_MA');
ok($r eq 'OPE_R9.1_Ass', '04.03.08 - Migrations::Clearcase::check_stream("stream:OPE_R9.1_Ass@/vobs/PVOB_MA")');
@r = Migrations::Clearcase::check_stream('OPE_R9.1_Ass@/vobs/PVOB_MA');
ok((scalar @r == 2 and $r[0] eq 'OPE_R9.1_Ass' and $r[1] eq '/vobs/PVOB_MA'), '04.03.09 - Migrations::Clearcase::check_stream("OPE_R9.1_Ass@/vobs/PVOB_MA")');

$r = Migrations::Clearcase::check_stream('OPE_R9.1_Ass@/vobs/MA1');
ok(!defined, '04.03.10 - Migrations::Clearcase::check_stream("OPE_R9.1_Ass@/vobs/MA1")');
$r = Migrations::Clearcase::check_stream('stream:OPE_R9.1_Ass@/vobs/MA1');
ok(!defined, '04.03.11 - Migrations::Clearcase::check_stream("stream:OPE_R9.1_Ass@/vobs/MA1")');
$r = Migrations::Clearcase::check_stream('no_such_a_stream@/vobs/PVOB_MA');
ok(!defined $r, '04.03.12 - Migrations::Clearcase::check_stream("no_such_a_stream@/vobs/PVOB_MA")');

$r = Migrations::Clearcase::compose_baseline();
ok(!defined $r, '04.04.01 - Migrations::Clearcase::compose_baseline()');
$r = Migrations::Clearcase::compose_baseline('PARTICULIER_Mainline@/vobs/PVOB_MA',);
ok(!defined $r, '04.04.02 - Migrations::Clearcase::compose_baseline("PARTICULIER_Mainline@/vobs/PVOB_MA",);');
$r = Migrations::Clearcase::compose_baseline(undef,'1.18.8.0-SNAPSHOT' );
ok(!defined $r, '04.04.03 - Migrations::Clearcase::compose_baseline(undef, "1.18.8.0-SNAPSHOT");');
$r = Migrations::Clearcase::compose_baseline('PARTICULIER_Mainline', '1.18.8.0-SNAPSHOT' );
ok(!defined $r, '04.04.04 - Migrations::Clearcase::compose_baseline("PARTICULIER_Mainline", "1.18.8.0-SNAPSHOT");');
$r = Migrations::Clearcase::compose_baseline('PARTICULIER_Mainline@/vobs/PVOB_MA', '1.18.0-SNAPSHOT');
ok(!defined $r, '04.04.05 - Migrations::Clearcase::compose_baseline("PARTICULIER_Mainline@/vobs/PVOB_MA", 1.18.0-SNAPSHOT");');


$r = Migrations::Clearcase::compose_baseline('PARTICULIER_Mainline@/vobs/PVOB_MA', '1.18.8.0-SNAPSHOT');

my $valid_baseline = '1.18.8.0-SNAPSHOT_Donnees_Client@/vobs/PVOB_MA,1.18.8.0-SNAPSHOT_socle-maven-particulier@/vobs/PVOB_MA,1.18.8.0-SNAPSHOT_Equipement@/vobs/PVOB_MA,1.18.8.0-SNAPSHOT_OME_TransfertPEA@/vobs/PVOB_MA,1.18.8.0-SNAPSHOT_Tableau_de_Bord@/vobs/PVOB_MA,1.18.8.0-SNAPSHOT_Mandataires@/vobs/PVOB_MA,1.18.8.0-SNAPSHOT_GDC_Credits@/vobs/PVOB_MA,1.18.8.0-SNAPSHOT_Mifid@/vobs/PVOB_MA,1.18.8.0-SNAPSHOT_Epargne@/vobs/PVOB_MA,1.18.8.0-SNAPSHOT_GDC_ExtensionTransfo@/vobs/PVOB_MA,1.18.8.0-SNAPSHOT_GDC_Cloture@/vobs/PVOB_MA,1.18.8.0-SNAPSHOT_GDC_Compte_Courant@/vobs/PVOB_MA,1.18.8.0-SNAPSHOT_dossier-client@/vobs/PVOB_MA,1.18.8.0-SNAPSHOT_Composant_Mifid@/vobs/PVOB_MA,1.18.8.0-SNAPSHOT_GDC_Credits_CT@/vobs/PVOB_MA,1.18.8.0-SNAPSHOT_par-communs@/vobs/PVOB_MA,1.18.8.0-SNAPSHOT_GDC_Epargne_CERS@/vobs/PVOB_MA,1.18.8.0-SNAPSHOT_Assurance_IARD@/vobs/PVOB_MA,1.18.8.0-SNAPSHOT_GDC_Package@/vobs/PVOB_MA,1.18.8.0-SNAPSHOT_Epargne_Logement@/vobs/PVOB_MA,1.18.8.0-SNAPSHOT_GDC_Titres@/vobs/PVOB_MA,1.18.8.0-SNAPSHOT_Cartes_Bancaires@/vobs/PVOB_MA,1.18.8.0-SNAPSHOT_bel@/vobs/PVOB_MA,1.18.8.0-SNAPSHOT_GDC_Services_en_Lignes_1@/vobs/PVOB_MA,1.18.8.0-SNAPSHOT_Services_en_Lignes_2@/vobs/PVOB_MA,1.18.8.0-SNAPSHOT_GDC_Client@/vobs/PVOB_MA,1.18.8.0-SNAPSHOT_Patrimoine@/vobs/PVOB_MA,1.18.8.0-SNAPSHOT_GDC_Contrat@/vobs/PVOB_MA,1.18.8.0-SNAPSHOT_integration-maven-particulier@/vobs/PVOB_MA,1.18.8.0-SNAPSHOT_Composant_Mandataires@/vobs/PVOB_MA,1.18.8.0-SNAPSHOT_GDC_Prospect@/vobs/PVOB_MA';

#diag("r = [" .($r //'undef'). ']');
ok((defined $r and $r eq $valid_baseline), '04.05.01 - Migrations::Clearcase::compose_baseline("PARTICULIER_Mainline@/vobs/PVOB_MA", "1.18.8.0-SNAPSHOT");');
@r = Migrations::Clearcase::compose_baseline('PARTICULIER_Mainline@/vobs/PVOB_MA', '1.18.8.0-SNAPSHOT');
ok((defined $r and scalar@r == 31), '04.05.01 - Migrations::Clearcase::compose_baseline("PARTICULIER_Mainline@/vobs/PVOB_MA", "1.18.8.0-SNAPSHOT");');

# test check_baseline()
$r = Migrations::Clearcase::check_baseline();
ok(!defined $r, '04.06.01 - Migrations::Clearcase::check_baseline()');
$r = Migrations::Clearcase::check_baseline('1.18.8.0-SNAPSHOT_Donnees_Client');
ok($r!=0, '04.06.02 - Migrations::Clearcase::check_baseline("1.18.8.0-SNAPSHOT_Donnees_Client")');
$r = Migrations::Clearcase::check_baseline('1.18.0-SNAPSHOT_Donnees_Client@/vobs/PVOB_MA');
ok($r!=0, '04.06.03 - Migrations::Clearcase::check_baseline("1.18.0-SNAPSHOT_Donnees_Client@/vobs/PVOB_MA")');
$r = Migrations::Clearcase::check_baseline('1.18.8.0-SNAPSHOT_Donnees_Client@/vobs/PVOB_MA');
ok($r==0, '04.06.04 - Migrations::Clearcase::check_baseline("1.18.8.0-SNAPSHOT_Donnees_Client@/vobs/PVOB_MA")');

# test make_stream()
$r = Migrations::Clearcase::make_stream();
ok(!defined $r, '04.07.01 - Migrations::Clearcase::make_stream()');
$r = Migrations::Clearcase::make_stream('no_baseline');
ok(!defined $r, '04.07.02 - Migrations::Clearcase::make_stream("no_baseline")');
$r = Migrations::Clearcase::make_stream(undef,'no_parent');
ok(!defined $r, '04.07.03 - Migrations::Clearcase::make_stream(undef,"no_parent")');
$r = Migrations::Clearcase::make_stream('fake_parent','fake_baseline');
ok(!defined $r, '04.07.04 - Migrations::Clearcase::make_stream("fake_parent","fake_baseline")');
@r = Migrations::Clearcase::make_stream('PARTICULIER_Mainline@/vobs/PVOB_MA','fake_baseline');
ok(!defined $r[0], '04.07.05 - Migrations::Clearcase::make_stream("PARTICULIER_Mainline@/vobs/PVOB_MA","fake_baseline")');
#diag("\$r[0] : [" . ($r[0] // 'undef') . "]");
#if ( scalar @r > 1 ){
    #diag("scalar \@r : " . (scalar @r));
    #diag("\$r[1] : [" . $r[1] . "]");
#}
$r = Migrations::Clearcase::make_stream('PARTICULIER_Mainline@/vobs/PVOB_MA','existing_new_name','_Mainline');
ok(!defined $r, '04.07.06 - Migrations::Clearcase::make_stream("PARTICULIER_Mainline@/vobs/PVOB_MA","existing_new_name", "_Mainline")');
$r = Migrations::Clearcase::make_stream('PARTICULIER_Mainline@/vobs/PVOB_MA', $valid_baseline );
diag("r = [" .($r //'undef'). ']');
ok((defined $r and ( $r eq 'stream:PARTICULIER_for_export_Dev@/vobs/PVOB_MA' )), '04.07.07 - Migrations::Clearcase::make_stream("PARTICULIER_Mainline@/vobs/PVOB_MA","valid_baseline")');

# test make_view()
$r = Migrations::Clearcase::make_view();
ok(!defined $r, '04.08.01 - Migrations::Clearcase::make_view()');

$r = Migrations::Clearcase::make_view('CCATIadm_PARTICULIER_Mainline');
ok(!defined $r, '04.08.02 - Migrations::Clearcase::make_view(CCATIadm_PARTICULIER_Mainline)');
$r = Migrations::Clearcase::make_view('CCATIadm_PARTICULIER_Mainline','','wrong_stgloc');
ok(!defined $r, '04.08.03 - Migrations::Clearcase::make_view(CCATIadm_PARTICULIER_Mainline,,wrong_stgloc)');
$r = Migrations::Clearcase::make_view('CCATIadm_PARTICULIER_Mainline','','viewstgloc');
ok(!defined $r, '04.08.04 - Migrations::Clearcase::make_view(CCATIadm_PARTICULIER_Mainline,,viewstgloc)');
$r = Migrations::Clearcase::make_view('CCATIadm_PARTICULIER_Mainline','bad_stream','wrong_stgloc');
ok(!defined $r, '04.08.05 - Migrations::Clearcase::make_view(CCATIadm_PARTICULIER_Mainline,bad_stream,wrong_stgloc)');
$r = Migrations::Clearcase::make_view('CCATIadm_PARTICULIER_Mainline','bad_stream','viewstgloc');
ok(!defined $r, '04.08.06 - Migrations::Clearcase::make_view(CCATIadm_PARTICULIER_Mainline,bad_stream,viewstgloc)');
$r = Migrations::Clearcase::make_view('CCATIadm_PARTICULIER_Mainline','stream:PARTICULIER_Mainline@/vobs/PVOB_MA','wrong_stgloc');
ok(!defined $r, '04.08.07 - Migrations::Clearcase::make_view(CCATIadm_PARTICULIER_Mainline,stream:PARTICULIER_Mainline@/vobs/PVOB_MA,wrong_stgloc)');
$r = Migrations::Clearcase::make_view('CCATIadm_PARTICULIER_Mainline','stream:PARTICULIER_Mainline@/vobs/PVOB_MA','viewstgloc');
ok(!defined $r, '04.08.08 - Migrations::Clearcase::make_view(CCATIadm_PARTICULIER_Mainline,stream:PARTICULIER_Mainline@/vobs/PVOB_MA,viewstgloc)');


$r = Migrations::Clearcase::make_view('x120248_new_view');
ok((defined $r and $r eq 'x120248_new_view'), '04.08.09 - Migrations::Clearcase::make_view(x120248_new_view)');
$r = Migrations::Clearcase::make_view('x120248_new_view','','wrong_stgloc');
ok(!defined $r, '04.08.10 - Migrations::Clearcase::make_view(x120248_new_view,,wrong_stgloc)');
$r = Migrations::Clearcase::make_view('x120248_new_view','','viewstgloc');
ok((defined $r and $r eq 'x120248_new_view'), '04.08.11 - Migrations::Clearcase::make_view(x120248_new_view,,viewstgloc)');
$r = Migrations::Clearcase::make_view('x120248_new_view','bad_stream','wrong_stgloc');
ok(!defined $r, '04.08.12 - Migrations::Clearcase::make_view(x120248_new_view,bad_stream,wrong_stgloc)');
$r = Migrations::Clearcase::make_view('x120248_new_view','bad_stream','viewstgloc');
ok(!defined $r, '04.08.13 - Migrations::Clearcase::make_view(x120248_new_view,bad_stream,viewstgloc)');
$r = Migrations::Clearcase::make_view('x120248_new_view','stream:PARTICULIER_Mainline@/vobs/PVOB_MA','wrong_stgloc');
ok(!defined $r, '04.08.14 - Migrations::Clearcase::make_view(x120248_new_view,stream:PARTICULIER_Mainline@/vobs/PVOB_MA,wrong_stgloc)');
$r = Migrations::Clearcase::make_view('x120248_new_view','stream:PARTICULIER_Mainline@/vobs/PVOB_MA','viewstgloc');
ok((defined $r and $r eq 'x120248_new_view'), '04.08.15 - Migrations::Clearcase::make_view(x120248_new_view,stream:PARTICULIER_Mainline@/vobs/PVOB_MA,viewstgloc)');


print "\n";

END {
    done_testing();
}

__END__

