package Midnight::Location::FrozenWaste;

use warnings;
use strict;

use base qw(Midnight::Location);

use Midnight::Location::Feature;
use Midnight::Location::Object;
use Midnight::Map::Area;

my $instance;

sub get_instance {
    my ($class) = @_;

    if (not $instance) {
        $instance = SUPER->new({
            game    => undef,
            x       => -1,
            y       => -1,
            feature => Midnight::Location::Feature::FROZEN_WASTE,
            object  => Midnight::Location::Object::NOTHING,
            area    => Midnight::Map::Area::NOTHING,
            domain  => 0,
            special => 0,
        });
    }

    return $instance;
}
