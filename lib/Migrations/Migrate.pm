package Migrations::Migrate;

#TODO: comments and documentation

use strict;
use warnings;
use v5.18;

our $VERSION = '1.0';

use Log::Log4perl qw(:easy);
use File::Spec;
use File::Basename;
use File::Copy::Recursive  qw(dircopy);
use File::Find::Rule::DirectoryEmpty ;
use File::Touch;

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
                                layout   => '[%p{1}][%d{HH:mm}] %m%n',
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

if ( -f "'. $opt->{logfile} . '" ) {
    Migrations::Migrate::init_logs(">>'. $opt->{logfile} . '");
} else {
    # mainly if logfile is STDOUT or SDTERR
    Migrations::Migrate::init_logs("'. $opt->{logfile} . '");
}

my $r = Migrations::Migrate::migrate_UCM("'. $opt->{repo}.'",';
    print $fh join (',', map { "'".$_."'" } @$dirs);
    print $fh ');

if ( $r == 0 ) {
    INFO "Migration succeeded.";
} elsif ( $r == 1 ) {
    WARN "Migration succeeded with warnings.";
} else {
    ERROR "Migration failed.";
}
exit 0;

__END__


';
    $fh->close();

    if ( chmod(0755,$fh->filename) != 1 ) {
        ERROR "Cannot chmod 0755 $fh";
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
    DEBUG "(read_matching_file) Opening [$file]";
    while ( <$fh> ) {
        # clean comments and spaces at the beginning and end of the line
        s/^\s+//; s/#.*//; s/\s+//; 
        # ignore empty lines
        next unless length;
        my ($k,$v) = split /\|/;
        $k =~ s/\s+$//;
        $v =~ s/^\s+//;
        $hash->{$k} = $v;
        DEBUG "(read_matching_file) h{$k} = [$v]";
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
# empty_dirs
#
# Add a empty file in empty directories so that
# git can add them to source control
#
# $target: the local repository
#
# RETURNS :
# 0 if all is OK
# 1 if WARNings (less .empty4git touch-ed than empty dirs)
# 2 if ERRORs (including wrong args and wrong context)
#
#------------------------------------------------
sub empty_dirs
{
    my $target = shift;
    my $exclude_dot_git = shift // 1;

    return 2 if ( ! defined $target );
    return 2 if ( ! -d $target );
    return 2 if ( ($exclude_dot_git != 0) and ($exclude_dot_git != 1) );

    my @empty_dirs = File::Find::Rule->directoryempty->in($target);
    DEBUG "" . (scalar @empty_dirs) . " empty dirs found.";
    DEBUG "   $_" for @empty_dirs;

    return 0 if ( scalar @empty_dirs  == 0 );

    my @empty4git;
    if ( $exclude_dot_git ) {
        @empty4git = map { File::Spec->catdir(File::Spec->splitdir($_), '.empty4git') } grep { ! /\.git/ } @empty_dirs;
    } else {
        @empty4git = map { File::Spec->catdir(File::Spec->splitdir($_), '.empty4git') } @empty_dirs;
    }
    DEBUG "" . (scalar @empty4git) . " .empty4git to be touched.";
    DEBUG "   $_" for @empty4git;

    return 0 if ( scalar @empty4git == 0 );

    my $count = touch(@empty4git);
    DEBUG "$count .empty4git touched.";
    if ( $count != scalar @empty4git ) {
        WARN "Seulement $count fichier(s) .empty4git cree(s) alors qu'on en attendait " . ( scalar @empty4git ) . ".";
        return 1;
    }

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
        ERROR "Not in a view context.";
        return 2;
    }
    DEBUG "target = [$target]";

    my $matching = {};
    my $r = read_matching_file($matching, File::Spec->catfile( File::Spec->splitdir($target), 'matching_clearcase_git.txt'));
    while ( my ($k,$v) = each %$matching ) {
        DEBUG "matching{$k} = [$v]";
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
            DEBUG "[$compCC]=[$vob]/[$comp] ---> [$dest_comp]";
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
            DEBUG "[$compCC]=[$vob]/[$comp] ---> [$dest_comp]   (2)";
        }
        my ($df, $d, $depth ) = dircopy($comp, $dest_comp);  # copy $comp/file ---> $dest_comp/file
        if ( defined $df ) {
            INFO "Migration of $compCC to $dest_comp :";
            INFO "    $df file(s) and directory(-ies)";
            INFO "    with $d directory(-ies)";
            INFO "    and depth of $depth level(s)";
            INFO "";
        } else {
            $return = 2 unless $return;
            push @error_comp, { $compCC => $dest_comp };
            ERROR "Error during the migration of component $compCC to $dest_comp.";
            ERROR "At least one file/directory cannot be copied.";
        }
    } # for $compCC
    empty_dirs($target);

    if ( $dirty_bit ) {
        # new entries in the matching file, let's save it
        my $r = write_matching_file($matching, File::Spec->catfile( File::Spec->splitdir($target), 'matching_clearcase_git.txt') );
        if ( !defined $r or $r ne '0' ) {
            $return = 1 unless $return;
            WARN "Cannot save the matching file. $dirty_bit were added.";
            WARN "Here's the hash table:";
            WARN "   (in CC)  --> (in Git)";
            while ( my ($k,$v) = each %$matching ) {
                WARN "   $k  --> $v";
            }
            WARN "<-- END -->";
        }
    }
    if ( scalar @error_comp ) {
        $return = 2 unless $return;
        my $was = ( scalar @error_comp == 1 ) ? ' was' : 's were';
        ERROR "" . (scalar @error_comp) . " component$was not copied:";
        for my $c ( @error_comp ) {
            ERROR "    $c    not copied to $target";
        }
        ERROR "";
    }

    return $return;
}
# end of migrate_UCM()
#------------------------------------------------


1;

__DATA__


