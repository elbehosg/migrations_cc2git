#!/usr/bin/env perl

use strict;
use warnings;
use v5.18;

use Getopt::Long qw(GetOptionsFromString);
use Pod::Usage qw(pod2usage);

use FindBin;
use lib "$FindBin::Bin/../lib";

use Migrations::Parameters;
use Migrations::Clearcase;
use Migrations::Git;

our $VERSION = '1.0.0';


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
    output => {
        mandatory => 1,
        getopt => 'output=s',
        },
    baseline => {
        mandatory_unless => [ 'bls' ],
        getopt => 'baseline=s',
        },
    bls => {
        mandatory_unless => [ 'baseline' ],
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
        getopt => 'steps=@',
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

my %opt;
my @valid_args = Migrations::Parameters::build_list_for_getopt(\%expected_args);


GetOptions(\%opt, @valid_args, "help|usage|?", "man" ) || pod2usage(2);

pod2usage(1)  if ($opt{help});
pod2usage(-exitval => 0, -verbose => 2)  if ($opt{man});

use Data::Dumper;
say Data::Dumper->Dump([\%opt,\@ARGV], [qw(opt ARGV)]);


my $ret = Migrations::Parameters::validate_arguments(\%opt, \%expected_args);



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
    --output file : fichier de log (si file = - : STDOUT+STDERR)
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


