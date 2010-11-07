use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'HiRedis::Driver',
    VERSION_FROM      => 'lib/HiRedis/Driver.pm',
    PREREQ_PM         => {
        Test::Requires => 0, 
        Test::More => 0, 
        XSLoader => 0, 
        ExtUtils::ParseXS => 0, 
        ExtUtils::MakeMaker => 0, 
        Devel::PPPort => 0
    },
    DISTNAME        => 'HiRedis-Driver',
    LICENSE         => 'perl',  
    #ABSTRACT_FROM  => 'lib/HiRedis/Driver.pm', 
    AUTHOR         => 'Sivirinov Ivan <catamoose at yandex.ru>',
    LIBS              => [''],
    DEFINE            => '',
    INC               => '-I.',
    META_MERGE     => {
        resources => {
            repository => 'https://mrRico@github.com/mrRico/hiredis-driverxs.git',
        }
    },
    OBJECT          => 'Driver.o hiredis.o net.o sds.o',
    C               => ['Driver.c'],
    OPTIMIZE        => $ENV{'OPTIMIZE'}
);
