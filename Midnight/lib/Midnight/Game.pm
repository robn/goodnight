package Midnight::Game;

use warnings;
use strict;

use Midnight::Map;

use Class::Std;

# !!! suckish way of handling public variables
my %public_data :ATTR;
my %public_keys = map { $_ => 1 } qw(LUXOR MORKIN CORLETH RORTHRON
                                     GARD MARAKITH XAJORKITH GLOOM
                                     SHIMERIL KUMAR ITHRORN DAWN
                                     DREAMS DREGRIM THIMRATH WHISPERS
                                     SHADOWS LOTHORIL KORINEL THRALL
                                     BRITH RORATH TRORN MORNING
                                     ATHORIL BLOOD HERATH MITHARG
                                     UTARG FAWKRIN LORGRIM FARFLAME);

sub AUTOMETHOD {
    my ($self, $ident, $args) = @_;
    my $key = $_;

    return if not $public_keys{$key};

    return sub {
        return $public_data{ident $self}->{$key} || ();
    };
}


my %map                     :ATTR( :get<map> :set<map> );
my %characters              :ATTR( :get<characters> );
my %armies                  :ATTR( :get<armies> );
my %doomguard               :ATTR( :get<doomguard );
my %day                     :ATTR( :get<day> );
my %moon_ring_controlled    :ATTR;
my %ice_crown_destroyed     :ATTR;
my %game_over               :ATTR;
my %status                  :ATTR( :get<status> );
my %battles                 :ATTR;
my %doomdarks_citadels      :ATTR( :get<doomdarks_citadels> );

sub START {
    my ($self, $ident, $args) = @_;

    $map{ident $self} = Midnight::Map->new({game => $self});

    $day{ident $self} = 0;
    $moon_ring_controlled{ident $self} = 1;
    $battles{ident $self} = {};

    $self->init_characters;
    $self->init_armies;
    $self->init_doomguard;
}

sub remove_doomguard {
    my ($self, $army) = @_;

    my $doomguard = $doomguard{ident $self};

    my $index = 0;
    while ($doomguard->[$index] != $army) {
        $index++;
    }

    return if $index == @{$doomguard};

    splice @{$doomguard}, $index, 1;
}

sub is_controllable {
    my ($self, $character) = @_;

    if ($character != $self->LUXOR and $character != $self->MORKIN) {
        return $character->is_recruited and $self->is_moon_ring_controlled;
    }

    return 1;
}

sub is_moon_ring_controlled {
    my ($self) = @_;

    return $moon_ring_controlled{ident $self};
}

sub night {
    my ($self) = @_;

    $self->check_special_conditions;
    if (! $game_over{ident $self}) {
        $day{ident $self}++;
        $self->calc_doomdarks_citadels;
        $self->calc_night_activity;
    }
}

sub dawn {
    my ($self) = @_;

    for my $character (@{$characters{ident $self}}) {
        $character->dawn;
    }
    for my $army (@{$armies{ident $self}}) {
        $army->dawn;
    }
    for my $army (@{$doomguard{ident $self}}) {
        $army->dawn;
    }
}

sub check_special_conditions {
    my ($self) = @_;

    if (! $self->LUXOR->is_alive and
        $self->LUXOR->get_object == Midnight::Location::Object::MOON_RING) {
        $self->LUXOR->drop_object;
        $moon_ring_controlled{ident $self} = 0;
    }

    if ($self->MORKIN->is_alive) {
        if ($self->MORKIN->get_object == Midnight::Location::Object::MOON_RING) {
            $moon_ring_controlled{ident $self} = 1;
        }
        elsif ($self->MORKIN->get_object == Midnight::Location::Object::ICE_CROWN) {
            my $location = $self->MORKIN->get_location;

            if ($location == $map{ident $self}->LAKE_MIRROW or
                $location == $self->FAWKRIN->get_location or
                $location == $self->LORGRIM->get_location or
                $location == $self->FARFLAME->get_location) {
                $ice_crown_destroyed{ident $self} = 1;
            }
        }
    }

    $self->check_game_over;
}

# !!! this feels wrong. its supposed to be +5 per citadel, +2 per keep, but this
# does +2 for anything other than a citadel; ie all armies give a bonus
sub calc_doomdarks_citadels {
    my ($self) = @_;

    my $citadels = 0;
    for my $army (@{$armies{ident $self}}) {
        if ($army->get_race == Midnight::Race::FOUL) {
            if ($army->get_location->get_feature == Midnight::Location::Feature::CITADEL) {
                $citadels += 5;
            }
            else {
                $citadels += 2;
            }
        }
    }

    $doomdarks_citadels{ident $self} = $citadels;
}

sub calc_night_activity {
    my ($self) = @_;

    $battles{ident $self} = {};

    for my $character (@{$characters{ident $self}}) {
        $character->increment_energy($character->get_time->get_time / 2);
        if ($character->is_alive and ! $character->is_hidden) {
            $character->get_location->set_special(1);
            $character->set_battle(undef);
            $character->set_enemy_killed = 0;
            $character->get_riders->set_casualties(0);
            $character->get_riders->set_enemy_killed(0);
            $character->get_warriors->set_casualties(0);
            $character->get_warriors->set_enemy_killed(0);
        }
    }

    for my $army (@{$armies{ident $self}}) {
        if ($army->get_race == Midnight::Race::FOUL) {
            $army->get_location->set_special(1);
        }
    }

    for my $army (@{$doomguard{ident $self}}) {
        while ($doomguard->get_move_count < Midnight::Doomguard::MAX_MOVE_COUNT) {
            $doomguard->execute_move;
        }
        $doomguard->reset_move_count;
    }

    for my $character (@{$characters{ident $self}}) {
        my $location = $character->get_location;
        $character->get_location->set_special(0);
        if ((@{$location->get_armies} > 0 or
                (not $location->get_guard and
                 $location->get_guard->get_race == Midnight::Race::FOUL)) and
            not exists $battles{ident $self}->{ident $army->get_location}) {
            $battles{ident $self}->{ident $army->get_location}, Midnight::Battle->new($army->get_location);
        }
    }

    for my $battle (values %{$battles{ident $self}}) {
        $battle->run;
    }
}

sub check_game_over {
    my ($self) = @_;

    if (! $self->MORKIN->is_alive) {
        if (! $self->LUXOR->is_alive) {
            $game_over{ident $self} = 1;
            $status{ident $self} = Midnight::Game::Status::LUXOR_MORKIN_DEAD;
        }
        elsif ($map{ident $self}->XAJORKITH->get_guard->get_race == Midnight::Race::FOUL) {
            $game_over{ident $self} = 1;
            $status{ident $self} = Midnight::Game::Status::MORKIN_XAJORKITH;
        }
    }

    if ($map{ident $self}->USHGARAK->get_guard->get_race == Midnight::Race::FREE) {
        $game_over{ident $self} = 1;
        $status{ident $self} = Midnight::Game::Status::USHGARAK;
    }
    elsif ($ice_crown_destroyed{ident $self}) {
        $game_over{ident $self} = 1;
        $status{ident $self} = Midnight::Game::Status::ICE_CROWN;
    }
}

sub get_battle_domains {
}

sub is_game_over {
}

sub save {
}

sub load {
}

sub load_characters {
}

sub save_characters {
}

sub load_garrisons {
}

sub save_garrisons {
}

sub load_doomguard {
}

sub save_doomguard {
}

sub init_characters {
}

sub init_armies {
}

sub init_doomguard {
}

sub random {
}

1;
