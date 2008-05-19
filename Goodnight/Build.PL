use strict;
use warnings;
use Module::Build;
use version;

my $builder = Module::Build->new(
    module_name         => 'Goodnight',
    license             => 'perl',
    dist_author         => 'Robert Norris <rob@cataclysm.cx>',
    dist_version_from   => 'lib/Goodnight.pm',
    requires => {
        'Class::Std' => qv("0.0.9"),
        'Class::Constant' => '0.05',
    },
    build_requires => {
        'Test::More' => 0,
    },
    script_files => [ "script/goodnight" ],
    add_to_cleanup      => [ 'Goodnight-*' ],
);

$builder->create_build_script();
