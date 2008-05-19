package Goodnight::Location::Object;

use warnings;
use strict;

use Class::Constant
    NOTHING          => "nothing",
    WOLVES           => "wolves",
    DRAGONS          => "dragons",
    ICE_TROLLS       => "ice trolls",
    SKULKRIN         => "Skulkrin",
    WILD_HORSES      => "wild horses",
    SHELTER          => "shelter and is refreshed",
    GUIDANCE         => "guidance",
    SHADOWS_OF_DEATH => "the Shadows of Death which drain him of vigour",
    WATERS_OF_LIFE   => "the Waters of Life which fill him with vigour",
    HAND_OF_DARK     => "the Hand of Dark which brings death to the day",
    CUP_OF_DREAMS    => "the Cup of Dreams which brings new welcome",
    WOLFSLAYER       => "the sword Wolfslayer",
    DRAGONSLAYER     => "the sword Dragonslayer",
    ICE_CROWN        => "the Ice Crown",
    MOON_RING        => "the Moon Ring",
    FAWKRIN          => "Fawkrin the Skulkrin",
    FARFLAME         => "Farflame the Dragonlord",
    LAKE_MIRROW      => "Lake Mirrow",
    LORGRIM          => "Lorgrim the Wise";

sub is_beast {
    my ($object) = @_;

    return $object == WOLVES or
           $object == DRAGONS or
           $object == ICE_TROLLS or
           $object == SKULKRIN;
}

# XXX this is badness of astronomical proportions. its bad enough that these
# enum classes have additional methods in them. its inexcusable to build game
# mechanics into them, and its just as bad to abuse a stringification method
# this way.

sub as_string {
    my ($object, $location) = @_;

    return $object->SUPER::as_string if $object != GUIDANCE or @_ == 1 or not $location;

    my $msg = "guidance. A voice says: '";
    my $rnd = $location->get_game->random(32);
    if ($rnd >= 4) {
        my $character = $location->get_game->get_characters->[$rnd];

        $msg .= "Looking for $character you must seek ".$character->get_location."'";
    }
    else {
        $msg .= $object->by_ordinal($rnd+16) . " can destroy the Ice Crown'";
    }

    return $msg;
}

1;
