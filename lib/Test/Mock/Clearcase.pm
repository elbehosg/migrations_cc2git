package Test::Mock::Clearcase;

use 5.008008;
use strict;
use warnings;

use Test::Mock::Simple;
use Readonly;

our $VERSION = '0.0.1';



#------------------------------------------------
#
#    CONVENIENT FUNCTIONS AND VARIABLES
#    (because some 'hard wired returns' can be
#    deduced one from each others, and maybe in
#    case of updates, it'll be easier just
#    to update the "seed" than any single value.
#
#------------------------------------------------

#
# cleartool desc -fmt '%[components]NXp' stream:PARTICULIER_Mainline@/vobs/PVOB_MA
#
Readonly::Scalar my $var_components_NXp => 'component:Donnees_Client@/vobs/PVOB_CHOPIN
component:socle-maven-particulier@/vobs/PVOB_CHOPIN
component:Equipement@/vobs/PVOB_CHOPIN
component:rdv-relance-client-part-ejb@/vobs/PVOB_MA
component:ficp-war@/vobs/PVOB_CHOPIN
component:OME_TransfertPEA@/vobs/PVOB_CHOPIN
component:Tableau_de_Bord@/vobs/PVOB_CHOPIN
component:ficp-ejb@/vobs/PVOB_CHOPIN
component:Mandataires@/vobs/PVOB_CHOPIN
component:assurance-mrh@/vobs/PVOB_MA
component:GDC_Credits@/vobs/PVOB_CHOPIN
component:Mifid@/vobs/PVOB_CHOPIN
component:Epargne@/vobs/PVOB_CHOPIN
component:GDC_ExtensionTransfo@/vobs/PVOB_CHOPIN
component:GDC_Cloture@/vobs/PVOB_CHOPIN
component:GDC_Compte_Courant@/vobs/PVOB_CHOPIN
component:dossier-client@/vobs/PVOB_CHOPIN
component:Composant_Mifid@/vobs/PVOB_CHOPIN
component:GDC_Credits_CT@/vobs/PVOB_CHOPIN
component:par-communs@/vobs/PVOB_CHOPIN
component:GDC_Epargne_CERS@/vobs/PVOB_CHOPIN
component:bad@/vobs/PVOB_MA
component:Assurance_IARD@/vobs/PVOB_CHOPIN
component:GDC_Package@/vobs/PVOB_CHOPIN
component:Epargne_Logement@/vobs/PVOB_CHOPIN
component:GDC_Titres@/vobs/PVOB_CHOPIN
component:tracabilite-assurance@/vobs/PVOB_CHOPIN
component:Cartes_Bancaires@/vobs/PVOB_CHOPIN
component:bel@/vobs/PVOB_CHOPIN
component:GDC_Services_en_Lignes_1@/vobs/PVOB_CHOPIN
component:Services_en_Lignes_2@/vobs/PVOB_CHOPIN
component:GDC_Client@/vobs/PVOB_CHOPIN
component:Patrimoine@/vobs/PVOB_CHOPIN
component:GDC_Contrat@/vobs/PVOB_CHOPIN
component:integration-maven-particulier@/vobs/PVOB_CHOPIN
component:bilan-epargne@/vobs/PVOB_MA
component:Composant_Mandataires@/vobs/PVOB_CHOPIN
component:GDC_Prospect@/vobs/PVOB_CHOPIN
';

Readonly::Array my @var_valid_streams => (
    'stream:PARTICULIER_Mainline@/vobs/PVOB_MA',
    'stream:OPE_R9.1_Ass@/vobs/PVOB_MA',
    );

#------------------------------------------------
# components_Nxp()
#------------------------------------------------
sub components_NXp
{
   return wantarray ? ( split /\n/, $var_components_NXp ) : $var_components_NXp;
}

#------------------------------------------------
# components_Np()
#------------------------------------------------
sub components_Np
{
   my @NXp = split /\n/, $var_components_NXp;
   my @Np = map { m%^component:([^@]+?)@/vobs/PVOB_\w+$% ; $1} @NXp;
   return wantarray ? @Np : ( join "\n",@Np);
}
#------------------------------------------------

Readonly::Scalar my $var_baselines => '1.18.8.0-SNAPSHOT';
#------------------------------------------------
# baselines()
#------------------------------------------------
sub baselines
{
   my @bls = map { $var_baselines . '_' . $_ . '@/vobs/PVOB_MA' } components_Np();
   return wantarray ? @bls : ( join "\n", @bls );
}




#------------------------------------------------
#
#    MOCKED FEATURES
#
#------------------------------------------------


#------------------------------------------------
sub ct_bad_cmd
{
    my $s = 'cleartool: Error: Unrecognized command: "-booh"
';
    return wantarray ? (1, split (/\n/, $s)) : $s;
}
# end of ct_bad_cmd()
#------------------------------------------------

#------------------------------------------------
sub ct_ver
{
    my $s = 'ClearCase version 8.0.0.01 (Wed Dec 28 01:01:29 EST 2011) (8.0.0.01.00_2011D.FCS)
ClearCase version 8.0.0.02 (Thu Apr 05 18:31:09 EST 2012) (8.0.0.02.00_2012A.FCS)
ClearCase version 8.0.0.03 (Thu Jun 21 16:08:51 EST 2012) (8.0.0.03.00_2012B.FCS)
ClearCase version 8.0.0.04 (Thu Sep 13 15:30:21 EDT 2012) (8.0.0.04.00_2012C.FCS)
ClearCase version 8.0.0.05 (Wed Dec 12 19:09:45 EST 2012) (8.0.0.05.00_2012D.FCS)
ClearCase version 8.0.0.06 (Fri Mar 20 10:35:58 EST 2013) (8.0.0.06.00_2013A.FCS)
ClearCase version 8.0.0.07 (Tue Jun 11 00:01:08 EDT 2013) (8.0.0.07.00_2013B.FCS)
ClearCase version 8.0.0.08 (Mon Sep 23 00:01:21 EDT 2013) (8.0.0.08.00_2013C.FCS)
ClearCase version 8.0.0.09 (Wed Nov 27 20:31:10 EST 2013) (8.0.0.09.00_2013D.D131127)
@(#) MVFS version 8.0.0.9 (Mon Nov 18 14:51:11 2013)
cleartool                         8.0.0.9 (Tue Nov 26 13:51:09 2013)
db_server                         8.0.0.9 (Mon Nov 18 17:51:04 2013)
VOB database schema versions: 54, 80
';  
    return wantarray ? (0, split (/\n/, $s)) : $s;

}
# end of ct_ver()
#------------------------------------------------

#------------------------------------------------
sub ct_hostinfo
{
    my @parms = @_;

    my $e = 0;
    my $s = '';

    if ( scalar @parms == 0 ) { 
        $s = 'DGCLLX11: ClearCase 7.1.2.8 (Linux 2.6.18-348.1.1.el5 #1 SMP Fri Dec 14 05:25:59 EST 2012 x86_64)
';
    } elsif ( $parms[0] eq '-h' ) { 
        $s = 'Usage: hostinfo [-long] [-properties [-full]] [ hostname ...]
';
    } elsif ( $parms[0] eq '-l' ) { 
        $s = 'Client: DGCLLX11
  Product: ClearCase 7.1.2.8
  Operating system: Linux 2.6.18-348.1.1.el5 #1 SMP Fri Dec 14 05:25:59 EST 2012
  Hardware type: x86_64
  Registry host: dgcl04.info.si.socgen
  Registry region: Dev_ice_ux
  License host: dgcl04.info.si.socgen
';
    } elsif ( substr($parms[0], 0, 1) eq '-' ) { 
        $s = 'cleartool: Error: Unrecognized option "-hhj"
Usage: hostinfo [-long] [-properties [-full]] [ hostname ...]
';
        $e = 1;
    } else {
        $s = 'dgcl05: ClearCase 8.0.0.10-IFIX01 (AIX 1 7 00C7D9C74C00)
';
    }
    return wantarray ? ($e, split (/\n/, $s)) : $s;
}
# end of ct_hostinfo()
#------------------------------------------------

#------------------------------------------------
sub ct_desc
{
    my @parms = @_;

    my $e = 0;
    my $s = '';

SWITCH_DESC : {
    # a valid PVOB
    if ( $parms[0] eq 'vob:/vobs/PVOB_MA' ) {
        $s = 'versioned object base "/vobs/PVOB_MA"
  created 2006-08-24T14:29:28+02:00 by 999181599.Utilisa.C_CHOPIN@CUR079JDV008
  master replica: Seclin@/vobs/PVOB_MA
  replica name: Tigery
  project VOB
  VOB family feature level: 5
  VOB storage host:pathname "dgcl04.info.si.socgen:/Clearcase/vobs2/pvob_ma.vbs"
  VOB storage global pathname "/Clearcase/vobs2/pvob_ma.vbs"
  database schema version: 54
  modification by remote privileged user: allowed
  atomic checkin: disabled
  VOB ownership:
    owner CCATIadm
    group cc-ati
  promotion levels:
    REJECTED
    INITIAL
    BUILT
    TESTED
    RELEASED
  default promotion level: INITIAL
  Attributes:
    FeatureLevel = 5
    code_irt = "A1730"
  Hyperlinks:
    AdminVOB -> vob:/vobs/PVOB_CHOPIN
    AdminVOB <- vob:/vobs/MA1
';
        last;
    }

    # a valid VOB (no PVOB)
    if ( $parms[0] eq 'vob:/vobs/MA1' ) {
        $s = 'versioned object base "/vobs/MA1"
  created 2006-08-24T14:28:57+02:00 by 999181599.Utilisa.C_CHOPIN@CUR079JDV008
  master replica: Seclin@/vobs/MA1
  replica name: Tigery
  VOB family feature level: 5
  VOB storage host:pathname "dgcl04.info.si.socgen:/Clearcase/vobs2/vob_ma1.vbs"
  VOB storage global pathname "/Clearcase/vobs2/vob_ma1.vbs"
  database schema version: 54
  modification by remote privileged user: allowed
  atomic checkin: disabled
  VOB ownership:
    owner CCATIadm
    group cc-ati
  Attributes:
    FeatureLevel = 5
    code_irt = "A1730"
  Hyperlinks:
    AdminVOB -> vob:/vobs/PVOB_MA
';
        last;
    }

    # a not-tagged VOB
    if ( $parms[0] eq 'vob:/vobs/MA' ) {
        $s = 'cleartool: Error: Unable to determine VOB for pathname "/vobs/MA".
';
        $e = 1;
        last;
    }

#warn ">>\n";
#warn ">> [$_]\n" for (@parms);
#warn ">>\n";

    # a valid stream
    if ( $parms[0] eq '-s' and grep { $_ eq $parms[1] } @var_valid_streams ) {
        $s = $parms[1];
        $s =~ s/^stream://;
        $s =~ s/\@\/.*$//;
        $s .= '
';
        $e = 0;
        last;
    }

    # a wrong stream
    if ( $parms[0] eq '-s' and $parms[1] eq 'stream:no_such_a_stream@/vobs/PVOB_MA' ) {
        $s = 'cleartool: Error: stream not found: "no_such_a_stream".
';
        $e = 1;
        last;
    }

    # unplanned stream
    if ( $parms[0] eq '-s' and (substr($parms[1],0,7) eq 'stream:' ) ) {
        my $stream = $parms[1];
        $stream =~ s/^stream://; $stream =~ s/\@.+$//;
        $s = 'cleartool: Error: stream not found: "' . $stream . '".
';
        $e = 1;
    }


    }; # SWITCH_DESC

    return wantarray ? ($e, split (/\n/, $s)) : $s;
}
# end of ct_desc()
#------------------------------------------------

#------------------------------------------------
sub ct_lsstream
{
    my @parms = @_;

    my $e = 0;
    my $s = '';

SWITCH_LSSTREAM: {

    # a valid case
    if ( join(' ',@parms) eq "-fmt '%[components]NXp' stream:PARTICULIER_Mainline@/vobs/PVOB_MA" ) {
        $s = components_NXp();
my $to_remove_after_successfull_tests='component:Donnees_Client@/vobs/PVOB_CHOPIN
component:socle-maven-particulier@/vobs/PVOB_CHOPIN
component:Equipement@/vobs/PVOB_CHOPIN
component:rdv-relance-client-part-ejb@/vobs/PVOB_MA
component:ficp-war@/vobs/PVOB_CHOPIN
component:OME_TransfertPEA@/vobs/PVOB_CHOPIN
component:Tableau_de_Bord@/vobs/PVOB_CHOPIN
component:ficp-ejb@/vobs/PVOB_CHOPIN
component:Mandataires@/vobs/PVOB_CHOPIN
component:assurance-mrh@/vobs/PVOB_MA
component:GDC_Credits@/vobs/PVOB_CHOPIN
component:Mifid@/vobs/PVOB_CHOPIN
component:Epargne@/vobs/PVOB_CHOPIN
component:GDC_ExtensionTransfo@/vobs/PVOB_CHOPIN
component:GDC_Cloture@/vobs/PVOB_CHOPIN
component:GDC_Compte_Courant@/vobs/PVOB_CHOPIN
component:dossier-client@/vobs/PVOB_CHOPIN
component:Composant_Mifid@/vobs/PVOB_CHOPIN
component:GDC_Credits_CT@/vobs/PVOB_CHOPIN
component:par-communs@/vobs/PVOB_CHOPIN
component:GDC_Epargne_CERS@/vobs/PVOB_CHOPIN
component:bad@/vobs/PVOB_MA
component:Assurance_IARD@/vobs/PVOB_CHOPIN
component:GDC_Package@/vobs/PVOB_CHOPIN
component:Epargne_Logement@/vobs/PVOB_CHOPIN
component:GDC_Titres@/vobs/PVOB_CHOPIN
component:tracabilite-assurance@/vobs/PVOB_CHOPIN
component:Cartes_Bancaires@/vobs/PVOB_CHOPIN
component:bel@/vobs/PVOB_CHOPIN
component:GDC_Services_en_Lignes_1@/vobs/PVOB_CHOPIN
component:Services_en_Lignes_2@/vobs/PVOB_CHOPIN
component:GDC_Client@/vobs/PVOB_CHOPIN
component:Patrimoine@/vobs/PVOB_CHOPIN
component:GDC_Contrat@/vobs/PVOB_CHOPIN
component:integration-maven-particulier@/vobs/PVOB_CHOPIN
component:bilan-epargne@/vobs/PVOB_MA
component:Composant_Mandataires@/vobs/PVOB_CHOPIN
component:GDC_Prospect@/vobs/PVOB_CHOPIN';
        last;
    }

    # a valid case
    if ( join(' ',@parms) eq "-fmt '%[components]Np' stream:PARTICULIER_Mainline@/vobs/PVOB_MA" ) {
        $s = components_Np();
        last;
    }

    # a VOB, not a PVOB
    if ( ( join(' ',@parms) eq "-fmt '%[components]NXp' stream:PARTICULIER_Mainline@/vobs/MA1" ) or
         ( join(' ',@parms) eq "-fmt '%[components]Np' stream:PARTICULIER_Mainline@/vobs/MA1"  ) ) {
        $s = 'cleartool: Error: stream not found: "PARTICULIER_Mainline".
';
        $e = 1;
        last;
    }

    # not a VOB
    if ( ( join(' ',@parms) eq "-fmt '%[components]NXp' stream:PARTICULIER_Mainline@/vobs/VOB_MA" ) or
         ( join(' ',@parms) eq "-fmt '%[components]Np' stream:PARTICULIER_Mainline@/vobs/VOB_MA"  ) ) {
        $s = 'cleartool: Error: Unable to determine VOB for pathname "/vobs/VOB_MA".
';
        $e = 1;
        last;
    }

    # no PVOB, no view
    if ( ( join(' ',@parms) eq "-fmt '%[components]NXp' stream:PARTICULIER_Mainline" ) or
         ( join(' ',@parms) eq "-fmt '%[components]Np' stream:PARTICULIER_Mainline" ) ) {
        $s = 'cleartool: Error: Unable to determine VOB for pathname ".".
';
        $e = 1;
        last;
    }

    # not a stream
    if ( ( join(' ',@parms) eq "-fmt '%[components]NXp' stream:PARTICULIER_Mainl@/vobs/PVOB_MA" ) or
         ( join(' ',@parms) eq "-fmt '%[components]Np' stream:PARTICULIER_Mainl@/vobs/PVOB_MA" ) ) {
        $s = 'cleartool: Error: stream not found: "PARTICULIER_Mainl".
';
        $e = 1;
        last;
    }

    }; # SWITCH_LSSTREAM

    return wantarray ? ($e, split (/\n/, $s)) : $s;
}
# end of ct_lsstream()
#------------------------------------------------


#------------------------------------------------
sub ct_lsbl
{
    my @parms = @_;

    my $e = 0;
    my $s = '';

    return undef if ( $parms[0] ne '-s' );

SWITCH_LSBL: {

    # a valid case
    my @valid_baselines = qw (
1.18.8.0-SNAPSHOT_Donnees_Client@/vobs/PVOB_MA
1.18.8.0-SNAPSHOT_socle-maven-particulier@/vobs/PVOB_MA
1.18.8.0-SNAPSHOT_Equipement@/vobs/PVOB_MA
1.18.8.0-SNAPSHOT_OME_TransfertPEA@/vobs/PVOB_MA
1.18.8.0-SNAPSHOT_Tableau_de_Bord@/vobs/PVOB_MA
1.18.8.0-SNAPSHOT_Mandataires@/vobs/PVOB_MA
1.18.8.0-SNAPSHOT_GDC_Credits@/vobs/PVOB_MA
1.18.8.0-SNAPSHOT_Mifid@/vobs/PVOB_MA
1.18.8.0-SNAPSHOT_Epargne@/vobs/PVOB_MA
1.18.8.0-SNAPSHOT_GDC_ExtensionTransfo@/vobs/PVOB_MA
1.18.8.0-SNAPSHOT_GDC_Cloture@/vobs/PVOB_MA
1.18.8.0-SNAPSHOT_GDC_Compte_Courant@/vobs/PVOB_MA
1.18.8.0-SNAPSHOT_dossier-client@/vobs/PVOB_MA
1.18.8.0-SNAPSHOT_Composant_Mifid@/vobs/PVOB_MA
1.18.8.0-SNAPSHOT_GDC_Credits_CT@/vobs/PVOB_MA
1.18.8.0-SNAPSHOT_par-communs@/vobs/PVOB_MA
1.18.8.0-SNAPSHOT_GDC_Epargne_CERS@/vobs/PVOB_MA
1.18.8.0-SNAPSHOT_Assurance_IARD@/vobs/PVOB_MA
1.18.8.0-SNAPSHOT_GDC_Package@/vobs/PVOB_MA
1.18.8.0-SNAPSHOT_Epargne_Logement@/vobs/PVOB_MA
1.18.8.0-SNAPSHOT_GDC_Titres@/vobs/PVOB_MA
1.18.8.0-SNAPSHOT_Cartes_Bancaires@/vobs/PVOB_MA
1.18.8.0-SNAPSHOT_bel@/vobs/PVOB_MA
1.18.8.0-SNAPSHOT_GDC_Services_en_Lignes_1@/vobs/PVOB_MA
1.18.8.0-SNAPSHOT_Services_en_Lignes_2@/vobs/PVOB_MA
1.18.8.0-SNAPSHOT_GDC_Client@/vobs/PVOB_MA
1.18.8.0-SNAPSHOT_Patrimoine@/vobs/PVOB_MA
1.18.8.0-SNAPSHOT_GDC_Contrat@/vobs/PVOB_MA
1.18.8.0-SNAPSHOT_integration-maven-particulier@/vobs/PVOB_MA
1.18.8.0-SNAPSHOT_Composant_Mandataires@/vobs/PVOB_MA
1.18.8.0-SNAPSHOT_GDC_Prospect@/vobs/PVOB_MA
);

    for my $i ( @valid_baselines ) {
        if ( $parms[1] eq $i ) {
            $s = $i;
            $s =~ s/\@.*//;
            $s .= '
';
        last SWITCH_LSBL;
        }
    }

    # not a valid baseline
    $s = 'cleartool: Error: Unable to find baseline "'.$parms[1].'".
cleartool: Error: Unable to list baseline.
';
        $e = 1;
        last;

    }; # SWITCH_LSBL

    return wantarray ? ($e, split (/\n/, $s)) : $s;
}
# end of ct_lsbl()
#------------------------------------------------


#------------------------------------------------
sub ct_mkstream
{
    my @parms = @_;

    my $e = 0;
    my $s = '';

warn ">>>> $_\n" for @parms;
SWITCH_mkstream: {
      # a valid case

     1;
    };  # SWITCH_mkstream

    return wantarray ? ($e, split (/\n/, $s)) : $s;
}
# end of ct_mkstream()
#------------------------------------------------


#------------------------------------------------
sub ct_mkview
{
    my @parms = @_;

    my $e = 0;
    my $s = '';

SWITCH_mkview: {
      # a valid case

     1;
    };  # SWITCH_mkview

    return wantarray ? ($e, split (/\n/, $s)) : $s;
}
# end of ct_mkview()
#------------------------------------------------


#------------------------------------------------
sub ct_XXX
{
    my @parms = @_;

    my $e = 0;
    my $s = '';

SWITCH_XXX: {
      # a valid case

     1;
    };  # SWITCH_XXX

    return wantarray ? ($e, split (/\n/, $s)) : $s;
}
# end of ct_XXX()
#------------------------------------------------


#------------------------------------------------
#
# INIT OF TEST::MOCK::CLEARCASE
#
#------------------------------------------------

sub new {
    my $package = shift;
    my $class = (ref$package) || $package;

    my $self = {@_};
    bless($self, $class);

    my $mock = Test::Mock::Simple->new(module => 'Migrations::Clearcase');
    $self->{mock} = $mock;
    $mock->add(cleartool => \&mocked_cleartool);
    return $self;
}

#------------------------------------------------
# mocked_cleartool
#
# Return static strings depending on the 1 word of the 1st parm
# Return an error if the cleartool cmd has not been mocked
#
# Currently, it mocks:
# not_a_ct_command
# -ver
# hostinfo
# desc
# lsstream with specific parms
# lsbl -s 
#------------------------------------------------
sub mocked_cleartool
{
    my $cmd = shift // '';
    my @parms = @_;

    $cmd =~ s/\s+(.*)$//;
    my $fparms = $1;
    if ( defined  $fparms ) {
        my @first_parms = split(/\s+/, $fparms);
        unshift @parms, @first_parms;
    }
    # cleanup the parms by splitting them and removing extra spaces
    my @parms2 = ();
    for my $p ( @parms ) {
        my @sub_parms = split /\s+/, $p;
        for my $sp ( @sub_parms ) {
            $sp =~ s/^\s+//; $sp =~ s/\s+$//;
            push @parms2, $sp if length $sp;
        }
    }
    @parms = @parms2;

    return ct_bad_cmd()        if ( $cmd eq 'not_a_ct_command' );
    return ct_ver()            if ( $cmd eq '-ver'     );
    return ct_hostinfo(@parms) if ( $cmd eq 'hostinfo' );
    return ct_desc(@parms)     if ( $cmd eq 'desc'     );
    return ct_lsstream(@parms) if ( $cmd eq 'lsstream' );
    return ct_lsbl(@parms)     if ( $cmd eq 'lsbl'     );
    return ct_mkstream(@parms) if ( $cmd eq 'mkstream' );
    return ct_mkview(@parms)   if ( $cmd eq 'mkview'   );

    return undef;
}
# end of mocked_cleartool()
#------------------------------------------------


1;

__END__


