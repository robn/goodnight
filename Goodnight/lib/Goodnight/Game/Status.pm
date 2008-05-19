package Goodnight::Game::Status;

use warnings;
use strict;

use Goodnight::Race;

use Class::Constant
    LUXOR_MORKIN_DEAD => "Luxor is dead and Morkin is dead.",
                      => { winner => Goodnight::Race::FOUL },
    MORKIN_XAJORKITH  => "Xajorkith has fallen and Morkin is dead.",
                      => { winner => Goodnight::Race::FOUL },
    USHGARAK          => "Ushgarak has fallen.",
                      => { winner => Goodnight::Race::FREE },
    ICE_CROWN         => "The Ice Crown has been destroyed.",
                      => { winner => Goodnight::Race::FREE };

1;
