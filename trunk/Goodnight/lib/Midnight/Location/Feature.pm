package Midnight::Location::Feature;

use warnings;
use strict;

use Class::Constant
    MOUNTAIN     => "mountains",     { at => "in" },
    CITADEL      => "citadel",       { at => "at" },
    FOREST       => "forest",        { at => "in" },
    HENGE        => "henge",         { at => "at" },
    TOWER        => "tower",         { at => "at" },
    VILLAGE      => "village",       { at => "at" },
    DOWNS        => "downs",         { at => "on" },
    KEEP         => "keep",          { at => "at" },
    SNOWHALL     => "snowhall",      { at => "at" },
    LAKE         => "lake",          { at => "at" },
    FROZEN_WASTE => "frozen wastes", { at => "in" },
    RUIN         => "ruin",          { at => "at" },
    LITH         => "lith",          { at => "at" },
    CAVERN       => "cavern",        { at => "at" },
    ARMY         => "plains",        { at => "on" },
    PLAINS       => "plains",        { at => "on" };
		
1;
