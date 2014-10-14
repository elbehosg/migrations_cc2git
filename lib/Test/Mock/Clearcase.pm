package Test::Mock::Clearcase;

use 5.008008;
use strict;
use warnings;

use Test::Mock::Simple;

our $VERSION = '0.0.1';



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
    if ( $parms[0] eq '-s' and $parms[1] eq 'stream:OPE_R9.1_Ass@/vobs/PVOB_MA' ) {
        $s = 'OPE_R9.1_Ass
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

    }; # SWITCH_DESC

    return wantarray ? ($e, split (/\n/, $s)) : $s;
}
# end of ct_desc()
#------------------------------------------------

#------------------------------------------------
sub ct_XXX
{
    my @parms = @_;

    my $e = 0;
    my $s = '';

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

    return ct_bad_cmd()        if ( $cmd eq 'not_a_ct_command' );
    return ct_ver()            if ( $cmd eq '-ver'  );
    return ct_hostinfo(@parms) if ( $cmd eq 'hostinfo' );
    return ct_desc(@parms)     if ( $cmd eq 'desc'  );

    return undef;
}
# end of mocked_cleartool()
#------------------------------------------------



__END__


