package Midnight::Game::Status;

use warnings;
use strict;

use Midnight::Race;

use Class::Constant
    LUXOR_MORKIN_DEAD => "Luxor is dead and Morkin is dead.",
                      => { winner => Midnight::Race::FOUL },
    MORKIN_XAJORKITH  => "Xajorkith has fallen and Morkin is dead.",
                      => { winner => Midnight::Race::FOUL },
    USHGARAK          => "Ushgarak has fallen.",
                      => { winner => Midnight::Race::FREE },
    ICE_CROWN         => "The Ice Crown has been destroyed.",
                      => { winner => Midnight::Race::FREE };

1;
