use 5.032001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Bridge::Flower',
    VERSION_FROM      => 'lib/Bridge/Flower.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {JSON=>0}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/Bridge/Flower.pm', # retrieve abstract from module
    AUTHOR            => 'Robin Barker r.m.barker@btinternet.com',
    LICENSE           => 'perl',
    #Value must be from legacy list of licenses here
    #https://metacpan.org/pod/Module::Build::API
    EXE_FILES         => [qw(bin/flower)],
);
