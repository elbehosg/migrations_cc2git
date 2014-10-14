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

our $VERSION = '1.0';



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
                ERROR "Impossible de supprimer le stream $v.";
            } else {
                push @success, $u;
            }
            next;
        }
        if ( $k eq 'view' ) {
            my ($e,$r) = Migrations::Clearcase::cleartool('rmview ', '-tag ', $v);
            if ( $e ) {
                ERROR "Impossible de supprimer la vue $v.";
            } else {
                push @success, $u;
            }
            next;
        }
        if ( $k eq 'file' ) {
            my $e = unlink $v;
            if ( $e != 1 ) {
                ERROR "Impossible de le fichier $v ($!).";
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


#------------------------------------------------
# check_clearcase_status
#
# IN:
#   $opt = HASHref on the opt from command line
#                 and/or --input file
# IN/OUT:
#   $data : HASHref with data gathered from git /
#                 clearcase / %$opt
#
# RETURN:
#   nothing
#   verbose (via Log4perl)
#   but can LOGDIE
#------------------------------------------------
sub check_clearcase_status
{
    my $opt = shift;
    my $data = shift;

    INFO "Est-ce que Clearcase est installe ?";
    my $ct = Migrations::Clearcase::where_is_cleartool();
    if ( !defined $ct ) {
        WARN "Clearcase n'est pas disponible.";
    } else {
        INFO "Cleartool est $ct";
    }
    $data->{cleartool} = $ct;

    INFO "Est-ce que la stream est valide ?";
    my $stream   = Migrations::Clearcase::check_stream($opt->{stream});
    if ( defined $stream ) {
        INFO 'La stream ' . $opt->{stream} . ' est définie.';
    } else {
        WARN 'La stream fournie ('. $opt->{stream} . ') est incorrecte.';
    }
    INFO "";
    INFO "Recupération des composants Clearcase :";
    my @components = Migrations::Clearcase::get_components($opt->{stream});
    if ( ! defined $components[0] ) {
        LOGDIE('Impossible de récupérer la liste des composants de ' . $opt->{stream} . '. Fatal.');
    }
    $data->{components} = \@components;
    my @components_rootdir = Migrations::Clearcase::get_components_rootdir(@components);
    if ( ! defined $components_rootdir[0] ) {
        LOGDIE('Impossible de récupérer les rootdir des composants de ' . $opt->{stream} . '. Fatal.');
    }
    $data->{components_rootdir} = \@components_rootdir;

    INFO "";

    INFO "Est-ce que la baseline est valide ?";
    if ( exists $opt->{bls} and exists $opt->{baseline} ) {
        LOGDIE('bls et baseline en meme temps. Ca pue trop. J\'arrete tout.');
    }
    my @baselines = ();
    if ( exists $opt->{baseline} ) {
        @baselines = Migrations::Clearcase::compose_baseline($opt->{stream},$opt->{baseline});
        if ( !defined $baselines[0] ) {
            LOGDIE "La baseline fournie ($opt->{baseline}) ne convient pas. Fatal.";
        }
    } else {
        @baselines = grep { Migrations::Clearcase::check_baseline($_) == 0 } @{$opt->{bls}};
    }
    $data->{baselines} = \@baselines;

    INFO "Baseline recomposée :";
    INFO "  $_" for ( @baselines );

    INFO "";

}
# end of check_clearcase_status()
#------------------------------------------------


#------------------------------------------------
# check_git_status
#
# IN:
#   $opt = HASHref on the opt from command line
#                 and/or --input file
# IN/OUT:
#   $data : HASHref with data gathered from git /
#                 clearcase / %$opt
#
# RETURN:
#   nothing
#   verbose (via Log4perl)
#   but can LOGDIE
#------------------------------------------------
sub check_git_status
{
    my $opt = shift;
    my $data = shift;

    INFO "";
    INFO "Est-ce que git est installe ?";
    my $git = Migrations::Git::where_is_git();
    if ( !defined $git ) {
        WARN "Git n'est pas disponible.";
    } else {
        INFO "Git est $git";
    }
    $data->{git} = $git;
 
    INFO "Est-ce que le depot local existe ?";
    if ( ! Migrations::Git::check_local_repo($opt->{repo}) ) {
        LOGDIE "Le depot local $opt->{repo} n'est pas un depot git. Fatal.\n";
    }
    INFO "Le depot $opt->{repo} existe.";

    INFO "Est-ce que la branche d'import existe ?";
    if ( ! Migrations::Git::check_branch($opt->{repo}, $opt->{branch}) ) {
        LOGDIE "Le depot local $opt->{repo} ne comporte pas de branche $opt->{branch}. Fatal.\n";
    }
    INFO "La branche $opt->{branch} existe dans le depot $opt->{repo}.";

    $data->{tag} = ( exists $opt->{baseline} ) ? $opt->{baseline} : $opt->{tag};
    INFO "Est-ce que le tag d'import existe ?";
    if ( Migrations::Git::check_branch($opt->{repo}, $data->{tag}) ) {
        LOGDIE "Le depot local $opt->{repo} comporte deja un tag $data->{tag}. Fatal.\n";
    }
    INFO "Le tag $data->{tag} n'existe pas dans le depot $opt->{repo}.";
}
# end of check_git_status()
#------------------------------------------------

#
#------------------------------------------------
# prepare_clearcase
#
# IN:
#   $opt = HASHref on the opt from command line
#                 and/or --input file
# IN/OUT:
#   $data : HASHref with data gathered from git /
#                 clearcase / %$opt
#
# RETURN:
#   nothing
#   verbose (via Log4perl)
#   but can LOGDIE
#------------------------------------------------
sub prepare_clearcase
{
    my $opt = shift;
    my $data = shift;

    INFO "Création du stream d'export";
    # on cree le stream (-ro)
    my $stream4export = Migrations::Clearcase::make_stream($opt->{stream}, (join ',', @{$data->{baselines}}));
    if ( ! defined $stream4export ) {
        LOGDIE "Impossible de creer le stream Clearcase pour l'export. Abort.";
    }
    push @{$data->{undo}}, { stream => $stream4export };
    $data->{stream4export} = $stream4export;


    # on cree la vue sur le stream
    my $u = $ENV{USERNAME} // ( $ENV{LOGNAME} // ( $ENV{LOGNAME} // 'unknownuser' ) );
    my $s = substr($stream4export,7);
    $s = substr($s, 0, index($s,'@'));
    my $viewtag = Migrations::Clearcase::make_view($u . '_' . $s, $stream4export, 'viewstgloc');
    if ( ! defined $viewtag ) {
        my $err = "Impossible de creer la vue Clearcase pour l'export. Abort.";
        undo_all(@{$data->{undo}});
        LOGDIE $err;
    }
    $data->{user} = $u;
    $data->{viewtag} = $viewtag;
    push @{$data->{undo}}, { view => $viewtag };
}
# end of prepare_clearcase()
#------------------------------------------------


#------------------------------------------------
# prepare_git
#
# IN:
#   $opt = HASHref on the opt from command line
#                 and/or --input file
# IN/OUT:
#   $data : HASHref with data gathered from git /
#                 clearcase / %$opt
#
# RETURN:
#   nothing
#   verbose (via Log4perl)
#   but can LOGDIE
#------------------------------------------------
sub prepare_git
{
    my $opt = shift;
    my $data = shift;

    INFO "Préparatif de la branche $opt->{branch}.";
    my $old_cwd = File::Spec->curdir;
    chdir $opt->{repo};
    Migrations::Git::git('checkout', $opt->{branch});
    my %cc2git;
    if ( -f 'matching_clearcase_git.txt' ) {
        my $r = Migrations::Migrate::read_matching_file(\%cc2git, File::Spec->catfile( File::Spec->splitdir($opt->{repo}), 'matching_clearcase_git.txt'));
        LOGDIE("Cannot open 'matching_clearcase_git.txt' although -f says it's here. Abort.") unless ( defined $r );
        while ( my ($k, $v ) = each %cc2git ) {
            next if (index($v,'/') != -1 ); # no slash allowed in git part
            remove_tree($v);
        }
    } else {
        # touch matching_clearcase_git.txt
        open my $f, '>', 'matching_clearcase_git.txt' or LOGDIE("Cannot create an empty 'matching_clearcase_git.txt'. Abort.");
        close $f;
        push @{$data->{undo}}, { file =>  File::Spec->catfile( File::Spec->splitdir($opt->{repo}), 'matching_clearcase_git.txt') };
    }
    chdir $old_cwd;
}
# end of prepare_git()
#------------------------------------------------


#------------------------------------------------
# transfer_data
#
# IN:
#   $opt = HASHref on the opt from command line
#                 and/or --input file
# IN/OUT:
#   $data : HASHref with data gathered from git /
#                 clearcase / %$opt
#
# RETURN:
#   nothing
#   verbose (via Log4perl)
#   but can LOGDIE
#------------------------------------------------
sub transfer_data
{
    my $opt = shift;
    my $data = shift;

    my $fname = Migrations::Migrate::build_migration_script($FindBin::Bin . '/../lib',$opt, $data->{components_rootdir});
    if ( defined $fname ) {
        INFO "Script de migration cree : $fname";
        push @{$data->{undo}}, { file => $fname };
    } else {
        my $err = "Erreur a la creation du script de migration. Abort.";
        undo_all(@{$data->{undo}});
        LOGDIE $err;
    }

    # cleartool setview -exec 
    INFO "Debut de l'import des donnees de Clearcase vers Git...";
    my ($e,@r) = Migrations::Clearcase::cleartool('setview ', '-exec ', $fname,  $data->{viewtag});
    if ( $e ) {
        FATAL "Erreur lors de l'extraction de donnees par cleartool setview -exec $fname $data->{viewtag}";
        for my $r ( @r ) {
            FATAL "> $r";
        }
        LOGDIE("Fatal.");
    } else {
        for my $r ( @r ) {
            INFO "> $r";
        }
    }
    INFO "Import reussi";

    INFO "Ajout de l'import dans git";
    my ($sout, $serr);
    ($e, $sout, $serr) = Migrations::Git::git('add' ,'-A');
    if ( $e ) {
        FATAL "Erreur lors de l'import sous git par 'git add -A'.";
        for my $r ( split "\n", $sout ) {
            FATAL "> $r";
        }
        FATAL "";
        for my $r ( split "\n", $serr ) {
            FATAL "> $r";
        }
        LOGDIE("Fatal.");
    }
    INFO "Ajout dans git reussi";
    push @{$data->{undo}}, { git_add_A =>  '???' };

}
# end of transfer_data()
#------------------------------------------------


#------------------------------------------------
# finalize_git
#
# IN:
#   $opt = HASHref on the opt from command line
#                 and/or --input file
# IN/OUT:
#   $data : HASHref with data gathered from git /
#                 clearcase / %$opt
#
# RETURN:
#   nothing
#   verbose (via Log4perl)
#   but can LOGDIE
#------------------------------------------------
sub finalize_git
{
    my $opt = shift;
    my $data = shift;

    #--------------
    $data->{msg_commit} = 'Import de la baseline ' . $data->{tag} . ' du stream ' . $opt->{stream};
    $data->{msg_commit} .= "

$data->{parms}

Baseline recomposée :
";
    $data->{msg_commit} .= join "\n", @{$data->{baselines}};
    $data->{msg_commit} .= "

Component rootdirs :
";
    $data->{msg_commit} .= join "\n", @{$data->{components_rootdir}};
    $data->{msg_commit} .= "

";
    #--------------

    INFO "Commit de l'import"; 
    my ($e, $sout, $serr) = Migrations::Git::git('commit', '-m', $data->{msg_commit});
    if ( $e ) {
        my $headline = substr($data->{msg_commit}, 0, 40);
        FATAL "Erreur lors du commit sous git par 'git commit -m" . $headline . "...'.";
        for my $r ( split "\n", $sout ) {
            FATAL "> $r";
        }
        FATAL "";
        for my $r ( split "\n", $serr ) {
            FATAL "> $r";
        }
        LOGDIE("Fatal.");
    }
    INFO "Commit reussi";
    push @{$data->{undo}}, { git_commit =>  '???' };

    INFO "Creation du label $data->{tag}";
    ($e, $sout, $serr) = Migrations::Git::git('tag', $data->{tag});
    if ( $e ) {
        FATAL "Erreur lors de la creation du tag par 'git tag ".$data->{tag} . "'.";
        for my $r ( split "\n", $sout ) {
            FATAL "> $r";
        }
        FATAL "";
        for my $r ( split "\n", $serr ) {
            FATAL "> $r";
        }
        LOGDIE("Fatal.");
    }
    INFO "Tag pose";
    push @{$data->{undo}}, { git_tag =>  '???' };

}
# end of finalize_git()
#------------------------------------------------


#------------------------------------------------
# cleanup
#
# IN:
#   $opt = HASHref on the opt from command line
#                 and/or --input file
# IN/OUT:
#   $data : HASHref with data gathered from git /
#                 clearcase / %$opt
#
# RETURN:
#   nothing
#   verbose (via Log4perl)
#   but can LOGDIE
#------------------------------------------------
sub cleanup
{
    my $opt = shift;
    my $data = shift;

    my @list = ();
    for my $u ( reverse @{$data->{undo}} ) {
        my ($k, $v) = each %$u;
        if ( $k eq 'stream' ) {
            my ($e,$r) = Migrations::Clearcase::cleartool('rmstream ', '-force ', $v);
            if ( $e ) {
                ERROR "Impossible de supprimer le stream $v.";
            } else {
                INFO "Stream $v supprime.";
            }
            next;
        }
        if ( $k eq 'view' ) {
            my ($e,$r) = Migrations::Clearcase::cleartool('rmview ', '-tag ', $v);
            if ( $e ) {
                ERROR "Impossible de supprimer la vue $v.";
            } else {
                INFO "Vue $v supprimee.";
            }
            next;
        }
        if ( $k eq 'file' and $v =~ m/migrate_\w{6}\.pl/i ) {
            my $e = unlink($v);
            if ( $e != 1 ) {
                ERROR "Erreur lors de la suppression du script de migration $v.";
            } else {
                INFO "Fichier $v supprime.";
            }
            next;
        }
        push @list, $u;
    }
    $data->{undo} = \@list;
    
}
# end of cleanup()
#------------------------------------------------



#------------------------------------------------
#
#  VALID PAREMETERS
#
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

#------------------------------------------------
#
#   MAIN
#
#------------------------------------------------

my %opt;  # for what comes from command line or alike
my %data; # for what is computed from git, clearcase, %opt...

#------------------------------------------------
# Init log system
#------------------------------------------------

Migrations::Migrate::init_logs();

#------------------------------------------------
# Handle arguments and parameters
#------------------------------------------------

my @valid_args = Migrations::Parameters::list_for_getopt(\%expected_args);

GetOptions(\%opt, @valid_args, "help|usage|?", "man") || pod2usage(2);

pod2usage(1)  if ($opt{help});
pod2usage(-exitval => 0, -verbose => 2)  if ($opt{man});

#   
# --input ?
#   
if ( exists $opt{input} ) { 
    # GetOpt ensures $opt{input} has a value
    open my $fh, '<', $opt{input} or die 'Cannot read ' . $opt{input} . " (from --input): $!. Abort.\n";
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
    # TODO: que faire de $ret (code retour) et $args (arguments hors @$...) ???

    # Priorities for args is default value < --input file < command line :
    while ( my ($k, $v ) = each %input ) {
        $opt{$k} = $v unless ( exists $opt{$k} );
    }
} # end --input

my $ret = Migrations::Parameters::validate_arguments(\%opt, \%expected_args);
if ( $ret ) {
    $! = $ret;
    LOGDIE 'Error(s) with the arguments. Abort.';
}

if ( -e $opt{logfile} ) {
    WARN "$opt{logfile} already exists. Will be appended.";
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

#------------------------------------------------
# Let's go
#------------------------------------------------

INFO "Demarrage de la migration Clearcase --> Git";
my ($y,$m,$d,$H,$M) = (localtime)[5,4,3,2,1];
my $s = sprintf("%04d-%02d-%02d %02d:%02d", $y+100,$m+1,$d,$H,$M);
$data{start_time} = $s;
INFO "  ($s)";
INFO "";
$data{parms} = 'Parametres d\'appel :
';
for my $k ( sort keys %opt ) {
    my $d = Data::Dumper->new([$opt{$k}], [$k]);
    $d->Indent(0);
    $d->Terse(1);
    my $s = sprintf("   %-12s %s\n",$k,$d->Dump);
    $data{parms} .= $s;
}
$data{parms} .= "[I]\n";

$s = sprintf("%-15s %s\n",'OS courant',$^O);
$data{parms} .= $s . "[I]\n";

INFO $data{parms};

#------------------------------------------------
# Check Clearcase and Git status
#------------------------------------------------

check_clearcase_status(\%opt, \%data);
check_git_status(\%opt, \%data);


#------------------------------------------------
# Create a clean environment to transfer the files
#------------------------------------------------

prepare_clearcase(\%opt, \%data);
prepare_git(\%opt, \%data);

# Assumption :
# the current directory does not contain any directory matching a Clearcase component

#------------------------------------------------
# Transfer the data to git
#------------------------------------------------
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
#        cp -r composant_CC dans dest_comp
#    exit
#
# git -A
# git commit -m 'Import de la BL du stream '
# git tag BL
#

transfer_data(\%opt, \%data);
finalize_git(\%opt, \%data);

#------------------------------------------------
# Cleanup
#------------------------------------------------

cleanup(\%opt, \%data);


INFO "That's all folks!";
($y,$m,$d,$H,$M) = (localtime)[5,4,3,2,1];
$s = sprintf("%04d-%02d-%02d %02d:%02d", $y+100,$m+1,$d,$H,$M);
$data{end_time} = $s;
INFO "  ($s)";

exit 0;

END {
    DEBUG "To END\n";
    DEBUG Dumper(\@{$data{undo}});
}

__END__

 
=pod
 
=encoding UTF-8
 
=head1 NAME
 
migration_cc2git.pl - migrate (ie import) a "baseline" from a Clearcase VOB to a Git repository

 
=head1 VERSION
 
version 1.0
 
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


