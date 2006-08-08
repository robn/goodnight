package Midnight::Map::Direction;

use warnings;
use strict;

use Class::Constant
    NORTH     => "North",     { x =>  0, y => -1 },
    NORTHEAST => "Northeast", { x =>  1, y => -1 },
    EAST      => "East",      { x =>  1, y =>  0 },
    SOUTHEAST => "Southeast", { x =>  1, y =>  1 },
    SOUTH     => "South",     { x =>  0, y =>  1 },
    SOUTHWEST => "Southwest", { x => -1, y =>  1 },
    WEST      => "West",      { x => -1, y =>  0 },
    NORTHWEST => "Northwest", { x => -1, y => -1 };

sub turn_right {
    my ($direction) = @_;

    return $direction->by_ordinal($direction->get_ordinal + 1 % 8);
}

sub turn_left {
    my ($direction) = @_;

    return $direction->by_ordinal($direction->get_ordinal - 1 % 8);
}

sub is_diagonal {
    my ($direction) = @_;

    return $direction->x != 0 and $direction->y != 0;
}

1;
