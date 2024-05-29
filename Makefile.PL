use 5.032001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Bridge::Flower',
    VERSION_FROM      => 'lib/Bridge/Flower.pm', # finds $VERSION
    PREREQ_PM         => {  JSON                    => 0, 
                            'Text::CSV'             => 2,
                        #   'Bridge::JSON::File'    => 0, 
                            'Math::Utils'           => 0,
                        }, 
    ABSTRACT_FROM     => 'lib/Bridge/Flower.pm', # retrieve abstract 
    AUTHOR            => 'Robin Barker r.m.barker@btinternet.com',
    LICENSE           => 'perl',
    #Value must be from legacy list of licenses here
    #https://metacpan.org/pod/Module::Build::API
    EXE_FILES         => [qw(bin/flower)],
);
