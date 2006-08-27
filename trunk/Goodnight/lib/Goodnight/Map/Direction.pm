package Goodnight::Map::Direction;

use warnings;
use strict;

use Class::Constant
    NORTH     => "north",     { x =>  0, y => -1 },
    NORTHEAST => "northeast", { x =>  1, y => -1 },
    EAST      => "east",      { x =>  1, y =>  0 },
    SOUTHEAST => "southeast", { x =>  1, y =>  1 },
    SOUTH     => "south",     { x =>  0, y =>  1 },
    SOUTHWEST => "southwest", { x => -1, y =>  1 },
    WEST      => "west",      { x => -1, y =>  0 },
    NORTHWEST => "northwest", { x => -1, y => -1 };

sub turn_right {
    my ($direction) = @_;

    return $direction->by_ordinal(($direction->get_ordinal + 1) % 8);
}

sub turn_left {
    my ($direction) = @_;

    return $direction->by_ordinal(($direction->get_ordinal - 1) % 8);
}

sub is_diagonal {
    my ($direction) = @_;

    return $direction->get_x != 0 and $direction->get_y != 0;
}

1;
