package Goodnight::Location::FrozenWaste;

use warnings;
use strict;

use base qw(Goodnight::Location);

use Goodnight::Location::Feature;
use Goodnight::Location::Object;
use Goodnight::Map::Area;

my $instance;

sub get_instance {
    my ($class) = @_;

    if (not $instance) {
        $instance = $class->SUPER::new({
            game    => undef,
            x       => -1,
            y       => -1,
            feature => Goodnight::Location::Feature::FROZEN_WASTE,
            object  => Goodnight::Location::Object::NOTHING,
            area    => Goodnight::Map::Area::NOTHING,
            domain  => 0,
            special => 0,
        });
    }

    return $instance;
}

1;
