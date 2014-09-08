use strict;
use warnings;
use ExtUtils::MakeMaker;

# Module to monitor and to report license usage, allowing multiple sources of information

WriteMakefile(
    NAME           => 'Licenses',
    AUTHOR         => 'Laurent Boivin (LBO) <laurent.boivin-ext@socgen.com>',
    VERSION_FROM   => 'bin/migration_cc2git.pl',
    PL_FILES       => {},
    BUILD_REQUIRES => {
        'Test::More'          => 0.98,
        'Test::Mock::Simple' => '0.04',
        'Readonly'           => '2.00',
    },
    PREREQ_PM  => {
        #'Moo' => 1.000008,
        'Log::Log4perl' => 1.44,
        'File::Spec' => 3.40,
        'Getopt::Long' => 2.39,
        'Pod::Usage' => 1.61,
        'List::MoreUtils' => 0.33,
    },
    MIN_PERL_VERSION => 5.010000,
    META_MERGE => {
        resources => {
            #repository => 'http://github.com/elbehosg//',
        },
    },
    LICENSE   => 'perl',
    EXE_FILES => [ ],
    dist      => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Migrations-*' },
);

