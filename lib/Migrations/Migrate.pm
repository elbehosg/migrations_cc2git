package Migrations::Migrate;

#TODO: comments and documentation

use strict;
use warnings;
use v5.18;

our $VERSION = '0.0.1';

use Log::Log4perl qw(:easy);
use File::Spec;
use File::Basename;
use File::Copy::Recursive  qw(dircopy);

use Migrations::Clearcase;


#------------------------------------------------
# init_logs()
#
# Initialize Log::Log4perl
# (this  function is here to be available from the ct setview -exe script)
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


#------------------------------------------------
# build_migration_script
#
# IN:
#    $libdir: $FindBin::Bin . "/../lib"
#    $opt : HASHref on the options of the main program
#    $dirs: ARRAYref on the directories to copy from CC to Git
#
# OUT:
#    the filename of the script
#    or undef in case of error
#
#------------------------------------------------
sub build_migration_script
{
    my $libdir = shift;
    my $opt    = shift;
    my $dirs   = shift;

    return undef unless ( defined $libdir and ref($libdir) eq ''      );
    return undef unless ( defined $opt    and ref($opt)    eq 'HASH'  );
    return undef unless ( defined $dirs   and ref($dirs)   eq 'ARRAY' );
    return undef unless ( exists $opt->{logfile} and exists $opt->{repo} );
    return undef unless ( scalar @$dirs ) ;

    my $fh = File::Temp->new(UNLINK => 0, TEMPLATE => 'migrate_XXXXXX', SUFFIX => '.pl', TMPDIR => 1);
    print $fh "#!$^X

use Log::Log4perl qw(:easy);
use lib \"$libdir\";
use Migrations::Migrate;
";

    print $fh '

if ( -f '. $opt->{logfile} . ' ) {
    Migrations::Migrate::init_logs(">>'. $opt->{logfile} . '");
} else {
    # mainly if logfile is STDOUT or SDTERR
    Migrations::Migrate::init_logs("'. $opt->{logfile} . '");
}

my $r = Migrations::Migrate::migrate_UCM("'. $opt->{repo}.'",';
    print $fh join (',', map { "'".$_."'" } @$dirs);
    print $fh ');

if ( $r == 0 ) {
    INFO "[I] Migration succeeded.";
} elsif ( $r == 1 ) {
    WARN "[W] Migration succeeded with warnings.";
} else {
    ERROR "[E] Migration failed.";
}
exit 0;

__END__


';
    $fh->close();

    if ( chmod(0755,$fh->filename) != 1 ) {
        ERROR "[E] Cannot chmod 0755 $fh";
        # ? return undef or not
        # if return undef, unlink the file
        unlink $fh->filename;
        return undef;
    }

    return $fh->filename;
}
# end of build_migration_script()
#------------------------------------------------


#------------------------------------------------
#------------------------------------------------
sub read_matching_file
{
    #TODO
    my $hash = shift;
    my $file = shift;
    return undef if ( !defined $hash and ref($hash) ne 'HASH' );
    return undef if ( !defined $file and ref($file) ne '' );

    open my $fh, '<', $file or return $!;
    DEBUG "[D] (read_matching_file) Opening [$file]";
    while ( <$fh> ) {
        # clean comments and spaces at the beginning and end of the line
        s/^\s+//; s/#.*//; s/\s+//; 
        # ignore empty lines
        next unless length;
        my ($k,$v) = split /\|/;
        $k =~ s/\s+$//;
        $v =~ s/^\s+//;
        $hash->{$k} = $v;
        DEBUG "[D] (read_matching_file) h{$k} = [$v]";
    }
    close $fh;
    return 0;
}
#------------------------------------------------

#------------------------------------------------
#------------------------------------------------
sub write_matching_file
{
    #TODO
    my $hash = shift;
    my $file = shift;
    return undef if ( !defined $hash and ref($hash) ne 'HASH' );
    return undef if ( !defined $file and ref($file) ne '' );

    open my $fh, '>', $file or return $!;
    my ($M,$H, $d, $m, $y) = (localtime)[1,2,3,4,5];
    my $date = sprintf("# Updated on %04d-%02d-%02d %02d:%02d\n", ($y+1900), ($m+1), $d, $H, $M);
    print $fh $date;
    for my $k ( sort keys %$hash ) {
        # for + sort so that line order is predictable for make test
        print $fh $k . '|' . $hash->{$k} . "\n";
    }
    close $fh or return undef;
    return 0;
}
#------------------------------------------------

#------------------------------------------------
# view context mandatory
#
# the baseline to export is selected by the view
# ==> no need to give it as parameter
#
# $target: the local repository
# @compCC: list of components (format: vob/component)
#
# RETURNS :
# 0 if all is OK
# 1 if WARNings
# 2 if ERRORs (including wrong args and wrong context)
#
#------------------------------------------------
sub migrate_UCM
{
    my $target = shift;
    my @compCC = @_;    # array of full 
    my $return = 0;

    return 2 unless ( defined $target and $target );
    return 2 unless ( scalar @compCC );
    my $ctxt = Migrations::Clearcase::check_view_context();
    if ( !defined $ctxt or $ctxt ) {
        ERROR "[E] Not in a view context.";
        return 2;
    }
    DEBUG "[D] target = [$target]";

    my $matching = {};
    my $r = read_matching_file($matching, File::Spec->catfile( File::Spec->splitdir($target), 'matching_clearcase_git.txt'));
    while ( my ($k,$v) = each %$matching ) {
        DEBUG "[D] matching{$k} = [$v]";
    }

    my $dirty_bit = 0;
    my @error_comp = ();
    for my $compCC ( @compCC ) {
        my $vob  = dirname($compCC);
        my $comp = basename($compCC);
        chdir ($vob); ## CHDIR
        my $dest_comp;
        if ( exists $matching->{$compCC} ) {
            $dest_comp = File::Spec->catdir(File::Spec->splitdir($target), $matching->{$compCC});
            DEBUG "[D] [$compCC]=[$vob]/[$comp] ---> [$dest_comp]";
        } else {
            $dest_comp = File::Spec->catdir(File::Spec->splitdir($target), $comp);
            if ( -d $dest_comp ) {
                $dest_comp = File::Spec->catdir(File::Spec->splitdir($target), $vob . '_' . $comp);
                my $idx = 0;
                while ( -d $dest_comp ) {
                    $dest_comp = File::Spec->catdir(File::Spec->splitdir($target), $vob . '_' . $comp . '_' . $idx);
                    $idx++;
                }
            }
            $matching->{$compCC} = basename($dest_comp);
            $dirty_bit++;
            DEBUG "[D] [$compCC]=[$vob]/[$comp] ---> [$dest_comp]   (2)";
        }
        my ($df, $d, $depth ) = dircopy($comp, $dest_comp);  # copy $comp/file ---> $dest_comp/file
        if ( defined $df ) {
            INFO "[I] Migration of $compCC to $dest_comp :";
            INFO "[I]     $df file(s) and directory(-ies)";
            INFO "[I]     with $d directory(-ies)";
            INFO "[I]     and depth of $depth level(s)";
            INFO "[I]";
        } else {
            $return = 2 unless $return;
            push @error_comp, { $compCC => $dest_comp };
            ERROR "[E] Error during the migration of component $compCC to $dest_comp.";
            ERROR "[E] At least one file/directory cannot be copied.";
        }
    } # for $compCC

    if ( $dirty_bit ) {
        # new entries in the matching file, let's save it
        my $r = write_matching_file($matching, File::Spec->catfile( File::Spec->splitdir($target), 'matching_clearcase_git.txt') );
        if ( !defined $r or $r ne '0' ) {
            $return = 1 unless $return;
            WARN "[W] Cannot save the matching file. $dirty_bit were added.";
            WARN "[W] Here's the hash table:";
            WARN "[W]    (in CC)  --> (in Git)";
            while ( my ($k,$v) = each %$matching ) {
                WARN "[W]    $k  --> $v";
            }
            WARN "[W] <-- END -->";
        }
    }
    if ( scalar @error_comp ) {
        $return = 2 unless $return;
        my $was = ( scalar @error_comp == 1 ) ? ' was' : 's were';
        ERROR "[E] " . (scalar @error_comp) . " component$was not copied:";
        for my $c ( @error_comp ) {
            ERROR "[E]     $c    not copied to $target";
        }
        ERROR "[E]";
    }

    return $return;
}
# end of migrate_UCM()
#------------------------------------------------


1;

__DATA__


