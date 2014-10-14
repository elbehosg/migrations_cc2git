package Migrations::Migrate;

use strict;
use warnings;
use v5.18;

our $VERSION = '0.0.1';

use Carp;
use Log::Log4perl qw(:easy);
use File::Spec;
use IPC::Run;
use LWP::UserAgent;

use Migrations::Clearcase;
use Migrations::Git;


sub read_matching_file
{
    #TODO
    my %hash;
    return \%hash;
}

sub write_matching_file
{
    #TODO
    my $hash = shift;
    my $file = shift;
    return undef if ( !defined $hash and ref($hash) ne 'HASH' );
    return undef if ( !defined $file and ref($file) ne '' );
    return 0;
}

# view context mandatory
sub migrate_UCM
{
    my $target = shift;
    my @compCC = @_;    # array of full 

    return undef unless ( defined $target and $target );
    return undef unless (scalar @compCC
    my $ctxt = Migrations::Clearcase::check_view_context();
    return undef if ( !defined $ctxt or $ctxt );

    my $maching = read_matching_file(File::Spect->catfile( File::Spect->splitdir($target), 'matching_clearcase_git.txt' );
    for my $compCC ( @compCC ) {
        
        if ( exists $maching->{$compCC} ) {
            $dest_comp = File::Spect->catdir(File::Spect->splitdir($target), $maching->{$compCC});
        } else {
            
        }
    }
}




1;

__DATA__


