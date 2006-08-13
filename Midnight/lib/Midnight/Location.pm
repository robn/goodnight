package Midnight::Location;

use warnings;
use strict;

use Midnight::Location::Fear;
use Midnight::Location::Feature;
use Midnight::Map;

use Class::Std;

my %game        : ATTR( :get<game> :init_arg<game> );
my %x           : ATTR( :get<x> :init_arg<x> );
my %y           : ATTR( :get<y> :init_arg<y> );
my %feature     : ATTR( :get<feature> :init_arg<feature> );
my %object      : ATTR( :get<object> :init_arg<object> );
my %area        : ATTR( :get<domain> :init_arg<area> );
my %domain      : ATTR( :get<domain_flag> :init_arg<domain> );
my %special     : ATTR( :init_arg<special> );
my %guard       : ATTR( :get<guard> );
my %armies      : ATTR( :get<armies> );
my %characters  : ATTR( :get<characters> );
my %ice_fear    : ATTR;

sub START {
    my ($self, $ident, $args) = @_;

    $armies{ident $self} = [];
    $characters{ident $self} = [];
}

sub get_coordinates {
    my ($self) = @_;

    return " [" . $x{ident $self} . ", " . $y{ident $self} . "]";
}

sub as_string {
    my ($self) = @_;

    my $feature = $feature{ident $self};
    my $area = $area{ident $self};

    if ($domain{ident $self}) {
        my $article;
        if ($feature == Midnight::Location::Feature::MOUNTAIN or
            $feature == Midnight::Location::Feature::DOWNS or
            $feature == Midnight::Location::Feature::FROZEN_WASTE or
            $feature == Midnight::Location::Feature::ARMY or
            $feature == Midnight::Location::Feature::PLAINS) {
            $article = " ";
        }
        else {
            $article = "a ";
        }

        return "$article$feature in the Domain of $area";
    }

    if ($feature == Midnight::Location::Feature::HENGE) {
        return $area . "henge";
    }

    if ($feature == Midnight::Location::Feature::LAKE) {
        return "Lake $area";
    }

    if ($feature == Midnight::Location::Feature::FROZEN_WASTE) {
        return "the Frozen Wastes";
    }

    my $feature_string = "$feature";
    $feature_string =~ s/^([a-z])/uc($1)/e;
    return "the $feature_string of $area";
}

use overload q{""} => \&as_string;

sub get_map {
    my ($self) = @_;

    return $game{ident $self}->get_map;
}

sub is_special {
    my ($self) = @_;

    return $special{ident $self};
}

sub set_guard {
    my ($self, $guard) = @_;

    if ($feature{ident $self} == Midnight::Location::Feature::KEEP or
        $feature{ident $self} == Midnight::Location::Feature::CITADEL) {
        $guard{ident $self} = $guard;
    }
}

sub add_army {
    my ($self, $army) = @_;

    push @{$armies{ident $self}}, $army;

    if ($feature{ident $self} == Midnight::Location::Feature::PLAINS) {
        $feature{ident $self} = Midnight::Location::Feature::ARMY;
    }
}

sub remove_army {
    my ($self, $army) = @_;

    my $armies = $armies{ident $self};

    my $index = 0;
    while ($armies->[$index] != $army) {
        $index++;
    }

    return if $index == @{$armies};

    splice @{$armies}, $index, 1;

    if ($feature{ident $self} == Midnight::Location::Feature::ARMY and @{$armies} == 0) {
        $feature{ident $self} = Midnight::Location::Feature::PLAINS;
    }
}

sub add_character {
    my ($self, $character) = @_;

    push @{$characters{ident $self}}, $character;

    if ($feature{ident $self} == Midnight::Location::Feature::PLAINS and
        ($character->get_riders->get_how_many > 0 or $character->get_warriors->get_how_many > 0)) {
        $feature{ident $self} = Midnight::Location::Feature::ARMY;
    }
}

sub remove_character {
    my ($self, $character) = @_;

    my $characters = $characters{ident $self};

    my $index = 0;
    while ($characters->[$index] != $character) {
        $index++;
    }

    if ($index < @{$characters}) {
        splice @{$characters}, $index, 1;
    }

    if ($feature{ident $self} == Midnight::Location::Feature::ARMY) {
        for my $character (@{$characters}) {
            if ($character->get_riders->get_how_many > 0 or
                $character->get_warriors->get_how_many > 0) {
                return;
            }
        }

        $feature{ident $self} = Midnight::Location::Feature::PLAINS;
    }
}

sub riders_battle_bonus {
    my ($self) = @_;

    if ($feature{ident $self} == Midnight::Location::Feature::MOUNTAIN) {
        return 0x20;
    }
    else {
        return 0x40;
    }
}

sub get_ice_fear {
    my ($self) = @_;

    my $game = $game{ident $self};

    my $fear;
    if ($game->MORKIN->is_alive) {
        if (Midnight::Map::calc_distance($self, $game->MORKIN->get_location) == 0) {
            $ice_fear{ident $self} =
                0x1ff - Midnight::Map::calc_distance($self, $self->get_map->TOWER_OF_DESPAIR) * 4;
            return $ice_fear{ident $self};
        }
        else {
            $fear = Midnight::Map::calc_distance($game->MORKIN->get_location,
                                                 $self->get_map->TOWER_OF_DESPAIR);
        }
    }
    else {
        $fear = 0x7f;
    }

    if ($game->LUXOR->is_alive) {
        $fear += Midnight::Map::calc_distance($self, $game->LUXOR->get_location);
    }
    else {
        $fear += 0x7f;
    }

    $fear += 0x30;
    $fear += $game->get_doomdarks_citadels;

    $ice_fear{ident $self} = $fear;
    return $fear;
}

sub describe_ice_fear {
    my ($self) = @_;

    $self->get_ice_fear;

    return Midnight::Location::Fear->by_ordinal((7 - $ice_fear{ident $self} / 0x40) % 8);
}

sub save {
}

sub load {
}

1;
