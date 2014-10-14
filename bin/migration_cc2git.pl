#!/usr/bin/env perl

use strict;
use warnings;
use v5.18;

use Getopt::Long qw(GetOptionsFromString);
use Pod::Usage qw(pod2usage);
use Log::Log4perl qw(:easy);
use Data::Dumper;
use File::Path qw(remove_tree);
use File::Temp;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Migrations::Parameters;
use Migrations::Clearcase;
use Migrations::Git;
use Migrations::Migrate;

our $VERSION = '1.0.0';



#------------------------------------------------
# undo_all
#
# Undo the ops that have created something until
# a fatal error occured
# The ops are processed in reverse order.
#
# IN:
#   array of { key, value } : 
#       key is the kind of the entity to undo (stream, view)
#       value is the name
#
# RETURN:
#   number of successfull undos
#
#------------------------------------------------
sub undo_all
{
    my @undo = @_;

    my @success = ();
    for my $u ( reverse @undo ) {
        my ($k, $v) = each %$u;
        if ( $k eq 'stream' ) {
            my ($e,$r) = Migrations::Clearcase::cleartool('rmstream ', '-force ', $v);
            if ( $e ) {
                ERROR "[E] Impossible de supprimer le stream $v.";
            } else {
                push @success, $u;
            }
            next;
        }
        if ( $k eq 'view' ) {
            my ($e,$r) = Migrations::Clearcase::cleartool('rmview ', '-tag ', $v);
            if ( $e ) {
                ERROR "[E] Impossible de supprimer la vue $v.";
            } else {
                push @success, $u;
            }
            next;
        }
        if ( $k eq 'file' ) {
            my $e = unlink $v;
            if ( $e != 1 ) {
                ERROR "[E] Impossible de le fichier $v ($!).";
            } else {
                push @success, $u;
            }
            next;
        }
    }
    return @success;
}
# end of undo_all()
#------------------------------------------------
my @undo = ();


#------------------------------------------------
# check_clearcase_status
#------------------------------------------------
sub check_clearcase_status
{
    my $opt = shift;
    my $data = shift;

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
INFO "[I] Recupération des composants Clearcase :";
my @components = Migrations::Clearcase::get_components($opt{stream});
if ( ! defined $components[0] ) {
    LOGDIE('[F] Impossible de récupérer la liste des composants de ' . $opt{stream} . '. Fatal.');
}
my @components_rootdir = Migrations::Clearcase::get_components_rootdir(@components);
if ( ! defined $components_rootdir[0] ) {
    LOGDIE('[F] Impossible de récupérer les rootdir des composants de ' . $opt{stream} . '. Fatal.');
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

}
# end of check_clearcase_status()
#------------------------------------------------


#------------------------------------------------
# check_git_status
#------------------------------------------------
sub check_git_status
{
}
# end of check_git_status()
#------------------------------------------------

#
#------------------------------------------------
# prepare_clearcase
#------------------------------------------------
sub prepare_clearcase
{
}
# end of prepare_clearcase()
#------------------------------------------------


#------------------------------------------------
# prepare_git
#------------------------------------------------
sub prepare_git
{
}
# end of prepare_git()
#------------------------------------------------


#------------------------------------------------
# transfer_data
#------------------------------------------------
sub transfer_data
{
}
# end of transfer_data()
#------------------------------------------------


#------------------------------------------------
# finalize_git
#------------------------------------------------
sub finalize_git
{
}
# end of finalize_git()
#------------------------------------------------


#------------------------------------------------
# cleanup
#------------------------------------------------
sub cleanup
{
}
# end of cleanup()
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
    tag => {
        mandatory_unless => [ 'baseline' ],
        exclude => [ 'baseline' ],
        getopt => 'tag=s',
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

Migrations::Migrate::init_logs();

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
    Migrations::Migrate::init_logs(">>".$opt{logfile});
    INFO '

-----------------------------------------------------------------------

';
} else {
    if ( $opt{logfile} eq '-' ) {
        $opt{logfile} = 'STDOUT';
    }
    Migrations::Migrate::init_logs($opt{logfile});
}

if ( exists $opt{bls} ) {
    my @bls = map { split(/,/, $_) } @{$opt{bls}};
    $opt{bls} = \@bls;
}

INFO "[I] Demarrage de la migration Clearcase --> Git";
INFO "[I] ";
my $parms = '[I] Parametres d\'appel :
';
for my $k ( sort keys %opt ) {
    my $d = Data::Dumper->new([$opt{$k}], [$k]);
    $d->Indent(0);
    $d->Terse(1);
    my $s = sprintf("[I]    %-12s %s\n",$k,$d->Dump);
    $parms .= $s;
}
$parms .= "[I]\n";

my $s = sprintf("[I] %-15s %s\n",'OS courant',$^O);
$parms .= $s . "[I]\n";

INFO $parms;

#
# VERIFICATIONS CLEARCASE, GIT
#


# on teste l'etat de git
INFO "[I] ";

INFO "[I] Est-ce que git est installe ?";
my $git = Migrations::Git::where_is_git();
if ( !defined $git ) {
    WARN "[W] Git n'est pas disponible.";
} else {
    INFO "[I] Git est $git";
}

INFO "[I] Est-ce que le depot local existe ?";
if ( ! Migrations::Git::check_local_repo($opt{repo}) ) {
    LOGDIE "[F] Le depot local $opt{repo} n'est pas un depot git. Abort.\n";
}
INFO "[I] Le depot $opt{repo} existe.";

INFO "[I] Est-ce que la branche d'import existe ?";
if ( ! Migrations::Git::check_branch($opt{repo}, $opt{branch}) ) {
    LOGDIE "[F] Le depot local $opt{repo} ne comporte pas de branche $opt{branch}. Abort.\n";
}
INFO "[I] La branche $opt{branch} existe dans le depot $opt{repo}.";

my $tag = ( exists $opt{baseline} ) ? $opt{baseline} : $opt{tag};
INFO "[I] Est-ce que le tag d'import existe ?";
if ( Migrations::Git::check_branch($opt{repo}, $tag) ) {
    LOGDIE "[F] Le depot local $opt{repo} comporte deja un tag $tag. Abort.\n";
}
INFO "[I] Le tag $tag n'existe pas dans le depot $opt{repo}.";



#
#   ON PREPARE LE TERRAIN
#

INFO "[I] Création du stream d'export";
# on cree le stream (-ro)
my $stream4export = Migrations::Clearcase::make_stream($opt{stream}, (join ',', @baselines));
if ( ! defined $stream4export ) {
    LOGDIE "[F] Impossible de creer le stream Clearcase pour l'export. Abort.";
}
push @undo, { stream => $stream4export };


# on cree la vue sur le stream
my $u = $ENV{USERNAME} // ( $ENV{LOGNAME} // ( $ENV{LOGNAME} // 'unknownuser' ) );
$s = substr($stream4export,7);
$s = substr($s, 0, index($s,'@'));
my $viewtag = Migrations::Clearcase::make_view($u . '_' . $s, $stream4export, 'viewstgloc');
if ( ! defined $viewtag ) {
    my $err = "[F] Impossible de creer la vue Clearcase pour l'export. Abort.";
    undo_all(@undo);
    LOGDIE $err;
}
push @undo, { view => $viewtag };


INFO "[I] Préparatif de la branche $opt{branch}.";
my $old_cwd = File::Spec->curdir;
chdir $opt{repo};
Migrations::Git::git('checkout', $opt{branch});
my %cc2git;
if ( -f 'matching_clearcase_git.txt' ) {
    my $r = Migrations::Migrate::read_matching_file(\%cc2git, File::Spec->catfile( File::Spec->splitdir($opt{repo}), 'matching_clearcase_git.txt'));
    LOGDIE("Cannot open 'matching_clearcase_git.txt' although -f says it's here. Abort.") unless ( defined $r );
    while ( my ($k, $v ) = each %cc2git ) {
        next if (index($v,'/') != -1 ); # no slash allowed in git part
        remove_tree($v);
    }
} else {
    # touch matching_clearcase_git.txt
    open my $f, '>', 'matching_clearcase_git.txt' or LOGDIE("Cannot create an empty 'matching_clearcase_git.txt'. Abort.");
    close $f;
    push @undo, { file =>  File::Spec->catfile( File::Spec->splitdir($opt{repo}), 'matching_clearcase_git.txt') };
}
#
# Assumption :
# the current directory does not contain any directory matching a Clearcase component


#
# MIGRATION PROPREMENT DITE
#

my $fname = Migrations::Migrate::build_migration_script($FindBin::Bin . '/../lib',\%opt, \@components_rootdir);
if ( defined $fname ) {
    INFO "[I] Script de migration cree : $fname";
    push @undo, { file => $fname };
} else {
    my $err = "[F] Erreur a la creation du script de migration. Abort.";
    undo_all(@undo);
    LOGDIE $err;
}


# cleartool setview -exec 
my ($e,$r) = Migrations::Clearcase::cleartool('setview ', '-exec ', $fname,  $viewtag);
print "e == > [$e]
r ==> [" . ($r // 'undef') . ']

';

INFO "[I] Ajout de l'import dans git";
Migrations::Git::git('add' ,'-A');
my $msg_commit = 'Import de la baseline ' . $tag . ' du stream ' . $opt{stream};
$msg_commit .= "

$parms

Baseline recomposée :
";
$msg_commit .= join '\n', @baselines;
$msg_commit .= "

Component rootdirs :
";
$msg_commit .= join '\n', @components_rootdir;
$msg_commit .= "

";

INFO "[I] Commit"; 
Migrations::Git::git('commit', '-m', 'Blablabla');
INFO "[I] Creation du label $tag";
Migrations::Git::git('tag', $tag);

exit 0;


# git co branch
# si matching_clearcase_git.txt existe
#     pour chaque composant :
#        rm -rf composant
# sinon
#    touch matching_clearcase_git.txt
#
# ct setview VUE
#    pour chaque composant_CC
#        si le composant_CC est dans matching_clearcase_git.txt
#             dest_comp = le correspondant de composant_CC dans matching_clearcase_git.txt
#        sinon
#             dest_comp = composantCC sans la VOB
#             si dest_comp existe deja : dest_comp <-- VOB_dest_comp
#             ajouter l'association composantCC <--> dest_comp dans matching_clearcase_git.txt
#        # assertion : on sait associer de facon unique composantCC et repertoire git
#        #             dans le depot local on est sur la branche d'import
#        cp composant_CC dans dest_comp
#    exit
#
# git -A && git commit && git tag
# git push
#


# on se met dans le bon context git
# on rince le répertoire

# (on se met dans le contexte de la vue) on extrait le contenu de la vue
# on copie recursivement depuis la vue vers le context git

# on git add / git commit / git push

# on implemente les differents steps :-)



INFO "[I] That's all folks!";

exit 0;

END {
    print "To END\n";
    print Dumper(\@undo);
}

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


