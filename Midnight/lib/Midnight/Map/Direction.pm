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

1;
