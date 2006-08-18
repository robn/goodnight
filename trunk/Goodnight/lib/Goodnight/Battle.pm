package Goodnight::Battle;

use warnings;
use strict;

use Goodnight::Army::Type;
use Goodnight::Location::Feature;
use Goodnight::Race;

use Class::Std;

my %location    : ATTR( :get<location> :init_arg<location> );
my %game        : ATTR;
my %winner      : ATTR( :get<winner> );
my %characters  : ATTR;
my %free        : ATTR;
my %foul        : ATTR;

sub START {
    my ($self, $ident, $args) = @_;

    $characters{ident $self} = [];
    $free{ident $self} = [];
    $foul{ident $self} = [];

    my $location = $location{ident $self};

    $game{$ident} = $location->get_game;

    $self->add_guard;

    for my $character (@{$location->get_characters}) {
        if ($character->is_alive and ! $character->is_hidden) {
            $self->add_character($character);
        }
    }

    for my $army (@{location->get_armies}) {
        $self->add_foul_army($army);
    }
}

sub add_guard {
    my ($self) = @_;

    my $guard = $location{ident $self}->get_guard;
    return if not $guard or $guard->get_how_many == 0;

    if ($guard->get_race == Goodnight::Race::FOUL) {
        $self->add_foul_army($guard);
    }

    else {
        if ($guard->get_type == Goodnight::Army::Type::RIDERS) {
            $guard->set_success_chance(0x60);
        }
        else {
            $guard->set_success_chance(0x40);
        }
    }
}

sub add_character {
    my ($self, $character) = @_;

    push @{$characters{ident $self}}, $character;
    $character->set_battle($self);

    if ($character->get_riders->get_how_many > 0) {
        $self->add_free_army($character->get_riders, $character);
    }
    if ($character->get_warriors->get_how_many > 0) {
        $self->add_free_army($character->get_warriors, $character);
    }
}

sub add_foul_army {
    my ($self, $army) = @_;

    my $location = $location{ident $self};

    my $fear_factor;
    if ($army->get_type == Goodnight::Army::Type::RIDERS) {
        $fear_factor = $location->get_ice_fear / 4;
    }
    else {
        $fear_factor = $location->get_ice_fear / 5;
    }

    my $success_chance = int $fear_factor;
    if ($location->get_guard and $location->get_guard->get_race == Goodnight::Race::FOUL) {
        if ($location->get_feature == Goodnight::Location::Feature::CITADEL) {
            $success_chance += 0x20;
        }
        else {
            $success_chance += 0x10;
        }
    }

    $army->set_success_chance($success_chance);

    push @{$foul{ident $self}}, $army;
}

sub add_free_army {
    my ($self, $army, $character) = @_;

    return if not $army or $army->get_how_many == 0;

    my $success_chance = $army->get_energy;

    my $location = $location{ident $self};
    if ($location->get_guard and $location->get_guard->get_race != Goodnight::Race::FOUL) {
        if ($location->get_feature == Goodnight::Location::Feature::CITADEL) {
            $success_chance += 0x20;
        }
        else {
            $success_chance += 0x10;
        }
    }

    if ($army->get_type == Goodnight::Army::Type::RIDERS) {
        $success_chance += $location->riders_battle_bonus;
    }

    if ($location->get_feature == Goodnight::Location::Feature::FOREST and
        $character->get_race == Goodnight::Race::FEY and $character->is_on_horse) {
        $success_chance += 0x40;
    }

    $success_chance = $success_chance / 2 + 0x18;

    $army->set_success_chance($success_chance);

    push @{$free{ident $self}}, $army;
}

sub run {
    my ($self) = @_;

    for my $character (@{$characters{ident $self}}) {
        $character->set_enemy_killed(
            $self->skirmish($character->get_strength,
                            $character->get_energy,
                            $foul{ident $self}));
    }

    for my $army (@{$free{ident $self}}) {
        $army->set_enemy_killed(
            $self->skirmish($army->get_how_many / 5,
                            $army->get_success_chance,
                            $foul{ident $self}));
    }

    for my $army (@{$foul{ident $self}}) {
        $army->set_enemy_killed(
            $self->skirmish($army->get_how_many / 5,
                            $army->get_success_chance,
                            $free{ident $self}));
    }

    # !!! lots of fancy printing omitted here, should bring it over

    $self->determine_result;
}

sub skirmish {
    my ($self, $hits, $success_chance, $enemies) = @_;

    my $enemy_killed = 0;

    my $i = 0;
    while (@{$enemies} > 0 and $i < $hits) {
        if ($game{ident $self}->random(256) < $success_chance) {
            my $enemy_index = $game{ident $self}->random(@{$enemies});
            my $enemy = $enemies->[$enemy_index];

            if ($game{ident $self}->random(256) > $enemy->get_success_chance) {
                $enemy_killed += 5;

                $enemy->add_casualties(5);
                if ($enemy->get_how_many == 0) {
                    splice @{$enemies}, $enemy_index, 1;
                }
            }
        }

        $i++;
    }

    return $enemy_killed;
}

sub determine_result {
    my ($self) = @_;

    my $winner = $winner{ident $self};

    if ($foul{ident $self}->size == 0) {
        $winner = Goodnight::Race::FREE;
    }
    elsif ($free{ident $self}->size == 0) {
        $winner = Goodnight::Race::FOUL;
    }
    else {
        undef $winner;
    }

    for my $army (@{$free{ident $self}}) {
        $army->decrement_energy(0x18);
    }

    my $location = $location{ident $self};
    if ($location->get_guard) {
        if ($winner) {
            if (($winner == Goodnight::Race::FOUL and
                 $location->get_guard->get_race != Goodnight::Race::FOUL) or
                ($winner != Goodnight::Race::FOUL and
                 $location->get_guard->get_race == Goodnight::Race::FOUL)) {
                $location->get_guard->switch_sides;
            }
        }
        elsif ($location->get_guard->get_how_many == 0) {
            $location->get_guard->increase_numbers(20);
        }
    }

    for my $character (@{$characters{ident $self}}) {
        $character->decrement_energy(0x14);
    }

    if ($winner == Goodnight::Race::FOUL) {
        $self->what_happened_to_free_lords;
    }
}

sub what_happened_to_free_lords {
    my ($self) = @_;

    for my $character (@{$characters{ident $self}}) {
        $character->maybe_lose;

        if ($character->is_alive) {
            my ($direction, $destination);

            do {
                $direction = Map::Direction->by_ordinal($game{ident $self}->random(8));
                $destination = $location{ident $self}->get_map->get_in_front($character->get_location, $direction);
            } while ($destination->get_feature == Goodnight::Location::Feature::FROZEN_WASTE);

            $character->set_location($destination);
        }
    }
}

sub as_string {
    my ($self) = @_;

    return "A battle in the domain of " . $location{$self}->get_domain;
}

use overload q{""} => \&as_string;

1;
