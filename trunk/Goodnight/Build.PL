use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Midnight',
    license             => 'perl',
    dist_author         => 'Robert Norris <rob@cataclysm.cx>',
    dist_version_from   => 'lib/Midnight.pm',
    requires => {
        'Class::Std' => 0,
        'Class::Constant' => '0.04',
    },
    build_requires => {
        'Test::More' => 0,
    },
    script_files => [ "script/midnight" ],
    add_to_cleanup      => [ 'Midnight-*' ],
);

$builder->create_build_script();
