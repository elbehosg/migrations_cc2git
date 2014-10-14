#!/usr/bin/env perl

use strict;
use warnings;
use v5.18;

use Getopt::Long qw(GetOptionsFromString);
use Pod::Usage qw(pod2usage);
use Log::Log4perl qw(:easy);
use Data::Dumper;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Migrations::Parameters;
use Migrations::Clearcase;
use Migrations::Git;

our $VERSION = '1.0.0';



#------------------------------------------------
# init_logs()
#
# Initialize Log::Log4perl
#
# IN: 
#    logfile: the output of the logger
#------------------------------------------------
sub init_logs
{
    my $logfile = shift // "STDOUT";

    Log::Log4perl->easy_init( { level    => $DEBUG,
                                file     => $logfile,
                                layout   => '%m%n',
                              },
                            ); 


    # Log::Log4perl->easy_init( { level    => $DEBUG,
    #                             file     => ">>test.log",
    #                             category => "Migrations::Parameters",
    #                             layout   => '%F{1}-%L-%M: %m%n' },
    #                           { level    => $DEBUG,
    #                             file     => "STDOUT",
    #                             category => "main",
    #                             layout   => '%m%n' },
    #                         );

}
# end of init_logs()
#------------------------------------------------


#
# subkeys for an argument :
#     getopt => string    description of the arg for Getopt::Long::GetOptions
#     mandatory => 1      if the arg is mandatory
#     optional  => 1      if the arg is optional
#     default => something   default value for the args
#     mandatory_unless => [ arg1, arg2 ] if one of the arg, arg1, arg2 are mandatory
#     exclude => [ arg1, arg2 ] if presence of arg forbids presence of arg1 or arg2
#
my %expected_args = (
    stream => {
        mandatory => 1,
        getopt => 'stream=s',
        },
    repo => {
        mandatory => 1,
        getopt => 'repo=s',
        },
    branch => {
        mandatory => 1,
        getopt => 'branch=s',
        },
    logfile => {
        mandatory => 1,
        getopt => 'logfile=s',
        },
    baseline => {
        mandatory_unless => [ 'bls' ],
        exclude => [ 'bls' ],
        getopt => 'baseline=s',
        },
    bls => {
        mandatory_unless => [ 'baseline' ],
        exclude => [ 'baseline' ],
        getopt => 'bls=s@',
        },
    interactive => {
        optional => 1,
        getopt => 'interactive!',
        default => 0,
        },
    preview => {
        optional => 1,
        getopt => 'preview',
        default => 0,
        },
    step => {
        optional => 1,
        getopt => 'step=s@',
        default => 'all',
        },
    reset => {
        optional => 1,
        getopt => 'reset',
        default => 0,
        },
    push => {
        optional => 1,
        getopt => 'push!',
        default => 0,
        },
    input => {
        optional => 1,
        getopt => 'input=s',
        },
    verbose => {
        optional => 1,
        getopt => 'verbose+',
        default => 0,
        },
    
    );
# end of %expected_args

init_logs();

my %opt;
my @valid_args = Migrations::Parameters::list_for_getopt(\%expected_args);

GetOptions(\%opt, @valid_args, "help|usage|?", "man") || pod2usage(2);

pod2usage(1)  if ($opt{help});
pod2usage(-exitval => 0, -verbose => 2)  if ($opt{man});

#   
# --input ?
#   
if ( exists $opt{input} ) { 
    # GetOpt ensures $opt{input} has a value
    open my $fh, '<', $opt{input} or die '[F] Cannot read ' . $opt{input} . " (from --input): $!. Abort.\n";
    my $argv = ''; 
    while ( <$fh> ) { 
        # ignore comments and empty lines
        s/#.+//; s/^\s+//; s/\s+$//;
        next unless length ; 
        $argv .= ' ' . $_; 
    }   
    close $fh;
    my %input ;
    my ($ret, $args) = GetOptionsFromString($argv, \%input, @valid_args );
    # TODO: que faire de $ret (code retour) et $args (arguments hors @$...)

    # Priorities for args is default value < --input file < command line :
    while ( my ($k, $v ) = each %input ) {
        $opt{$k} = $v unless ( exists $opt{$k} );
    }
} # end --input

my $ret = Migrations::Parameters::validate_arguments(\%opt, \%expected_args);
if ( $ret ) {
    $! = $ret;
    LOGDIE '[F] Error(s) with the arguments. Abort.';
}

if ( -e $opt{logfile} ) {
    WARN "[W] $opt{logfile} already exists. Will be appended.";
    init_logs(">>".$opt{logfile});
    INFO '

-----------------------------------------------------------------------

';
} else {
    if ( $opt{logfile} eq '-' ) {
        $opt{logfile} = 'STDOUT';
    }
    init_logs($opt{logfile});
}

if ( exists $opt{bls} ) {
    my @bls = map { split(/,/, $_) } @{$opt{bls}};
    $opt{bls} = \@bls;
}

INFO "[I] Demarrage de la migration Clearcase --> Git";
INFO "[I] ";
INFO "[I] Parametres d'appel :";
for my $k ( sort keys %opt ) {
    my $d = Data::Dumper->new([$opt{$k}], [$k]);
    $d->Indent(0);
    $d->Terse(1);
    my $s = sprintf("[I]    %-12s %s\n",$k,$d->Dump);
    INFO $s;
}
INFO "[I] ";

my $s = sprintf("[I] %-15s %s\n",'OS courant',$^O);
INFO $s;
INFO "[I] ";

INFO "[I] Est-ce que Clearcase est installe ?";
my $ct = Migrations::Clearcase::where_is_cleartool();
if ( !defined $ct ) {
    WARN "[W] Clearcase n'est pas disponible.";
} else {
    INFO "[I] Cleartool est $ct";
}

INFO "[I] Est-ce que la stream est valide ?";
my $stream   = Migrations::Clearcase::check_stream($opt{stream});
if ( defined $stream ) {
    INFO '[I] La stream ' . $opt{stream} . ' est définie.';
} else {
    WARN '[W] La stream fournie ('. $opt{stream} . ') est incorrecte.';
}
INFO "[I] ";


INFO "[I] Est-ce que la baseline est valide ?";
if ( exists $opt{bls} and exists $opt{baseline} ) {
    LOGDIE('bls et baseline en meme temps. Ca pue trop. J\'arrete tout.');
}
my @baselines = ();
if ( exists $opt{baseline} ) {
    @baselines = Migrations::Clearcase::compose_baseline($opt{stream},$opt{baseline});
    if ( !defined $baselines[0] ) {
        LOGDIE "[F] La baseline fournie ($opt{baseline}) ne convient pas. Abort.";
    }
} else {
    @baselines = grep { Migrations::Clearcase::check_baseline($_) == 0 } @{$opt{bls}};
}

INFO "[I] Baseline recomposée :";
INFO "[I]   $_" for ( @baselines );

INFO "[I] ";

INFO "[I] Création du stream d'export";
# on cree le stream (-ro)
# on cree la vue sur le stream

# on teste l'etat de git
# on se met dans le bon context git
# on rince le répertoire

# (on se met dans le contexte de la vue) on extrait le contenu de la vue
# on copie recursivement depuis la vue vers le context git

# on git add / git commit / git push

# on implemente les differents steps :-)






INFO "[I] That's all folks!";

exit 0;

__END__

 
=pod
 
=encoding UTF-8
 
=head1 NAME
 
migration_cc2git.pl - migrate (ie import) a "baseline" from a Clearcase VOB to a Git repository

 
=head1 VERSION
 
version 0.0.1
 
=head1 SYNOPSIS
 

  migrationcc2git.pl [options]

  --help, --usage, -? : display this help

  Mandatory parameters:

    --stream stream@pvob : le stream source
    --baseline X.Y.Z-SNAPSHOT : le nom « générique » de la baseline
    --repo depot : le dépôt Git vers lequel les données migrent
    --branch branche : la branche Git qui reçoit les données
    --logfile file : fichier de log (si file = - : STDOUT+STDERR)
        Si absent : message d’erreur sur STDERR

  Optional parameters:

    --bls BL1,BL2,BL3 : la liste des « baseline x composant » séparés par une ,
        Défaut : est calculée en fonction de --baseline
    --interactive : on valide chaque étape
        Défaut : pas interactif
    --preview : affiche les opérations sans les exécuter
        Défaut : les opérations sont exécutées
    --steps : indique les étapes à exécuter (« depuis le début jusqu’à » ou « ces steps-là » ?)
        Défaut : toutes les étapes sont exécutées
    --reset : fait un peu de ménage pour permettre de revenir « à l’état initial » après avoir utilisé –steps
        Défaut : on ne fait pas reset
    --push : fait le push après le commit (« --push remote branch » ou juste « --push » ?)
        Défaut : pas de push
        credentials sur le serveur de référence ?
    --input file : fichier contenant les paramètres de la ligne de commande (« les » ou « des » ?)
        Défaut : pas de valeur par défaut
        Si un paramètre est défini dans --input et sur la ligne de commande, le paramètre de la ligne de commande a la priorité.
    --verbose : pour avoir tout les logs
        verbosity à définir avec et sans le flag


=head1 DESCRIPTION

migration_cc2git.pl uses a stream and a named baseline to create a view,
extract files and directories and copies that to a Git repository,
and commit this addition.

A tag is set on Git and a label/attribute/marker/whatever indicates that this
baseline in Clearcase has been imported.

 
=head1 BUGS
 
None reported.  (but give me the time to finish the script :-) )
 
=head1 SUPPORT
 
You can find documentation for this module with the perldoc command.
 
    perldoc migrationcc2git.pl
 
 
 
=head1 AUTHOR
 
Laurent Boivin, C<< <laurent.boivin-ext at socgen.com> >>
 
=head1 COPYRIGHT AND LICENSE
 
I've no idea
 
=cut


