package Goodnight::Game;

use warnings;
use strict;

use Goodnight::Army;
use Goodnight::Army::Type;
use Goodnight::Battle;
use Goodnight::Character;
use Goodnight::Doomguard;
use Goodnight::Game::Status;
use Goodnight::Location::Feature;
use Goodnight::Location::Object;
use Goodnight::Map;
use Goodnight::Map::Direction;
use Goodnight::Race;

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


# assigned at end of file
my (@character_defs, @army_defs, @doomguard_defs);

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

    $map{ident $self} = Goodnight::Map->new({game => $self});

    $day{ident $self} = 0;
    $moon_ring_controlled{ident $self} = 1;
    $battles{ident $self} = {};

    $self->init_characters;
    $self->init_armies;
    $self->init_doomguard;

    $self->calc_doomdarks_citadels;
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
        return ($character->is_recruited and $self->is_moon_ring_controlled);
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
        $self->LUXOR->get_object == Goodnight::Location::Object::MOON_RING) {
        $self->LUXOR->drop_object;
        $moon_ring_controlled{ident $self} = 0;
    }

    if ($self->MORKIN->is_alive) {
        if ($self->MORKIN->get_object == Goodnight::Location::Object::MOON_RING) {
            $moon_ring_controlled{ident $self} = 1;
        }
        elsif ($self->MORKIN->get_object == Goodnight::Location::Object::ICE_CROWN) {
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
        if ($army->get_race == Goodnight::Race::FOUL) {
            if ($army->get_location->get_feature == Goodnight::Location::Feature::CITADEL) {
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
            $character->set_enemy_killed(0);
            $character->get_riders->set_casualties(0);
            $character->get_riders->set_enemy_killed(0);
            $character->get_warriors->set_casualties(0);
            $character->get_warriors->set_enemy_killed(0);
        }
    }

    for my $army (@{$armies{ident $self}}) {
        if ($army->get_race == Goodnight::Race::FOUL) {
            $army->get_location->set_special(1);
        }
    }

    for my $doomguard (@{$doomguard{ident $self}}) {
        while ($doomguard->get_move_count < Goodnight::Doomguard::MAX_MOVE_COUNT) {
            $doomguard->execute_move;
        }
        $doomguard->reset_move_count;
    }

    for my $character (@{$characters{ident $self}}) {
        my $location = $character->get_location;
        $location->set_special(0);
        if ((@{$location->get_armies} > 0 or
                ($location->get_guard and
                 $location->get_guard->get_race == Goodnight::Race::FOUL)) and
            not exists $battles{ident $self}->{ident $location}) {
            $battles{ident $self}->{ident $location} = Goodnight::Battle->new({location => $location});
        }
    }
            
    for my $army (@{$armies{ident $self}}) {
        if ($army->get_race == Goodnight::Race::FOUL) {
            my $location = $army->get_location;
            $location->set_special(0);
            if (@{$location->get_armies} > 0 and
                not exists $battles{ident $self}->{ident $location}) {
                $battles{ident $self}->{ident $location} =
                    Goodnight::Battle->new({location => $location});
            }
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
            $status{ident $self} = Goodnight::Game::Status::LUXOR_MORKIN_DEAD;
        }
        elsif ($map{ident $self}->XAJORKITH->get_guard->get_race == Goodnight::Race::FOUL) {
            $game_over{ident $self} = 1;
            $status{ident $self} = Goodnight::Game::Status::MORKIN_XAJORKITH;
        }
    }

    if ($map{ident $self}->USHGARAK->get_guard->get_race == Goodnight::Race::FREE) {
        $game_over{ident $self} = 1;
        $status{ident $self} = Goodnight::Game::Status::USHGARAK;
    }
    elsif ($ice_crown_destroyed{ident $self}) {
        $game_over{ident $self} = 1;
        $status{ident $self} = Goodnight::Game::Status::ICE_CROWN;
    }
}

sub get_battles {
    my ($self) = @_;

    my @battles = values %{$battles{ident $self}};
    return \@battles;
}

sub get_battle_domains {
    my ($self) = @_;

    my %domains;
    for my $battle (@{$self->get_battles}) {
        my $domain = $battle->get_location->get_domain;
        $domains{ident $domain} = $domain;
    }

    my @domains = values %domains;
    return \@domains;
}

sub is_game_over {
    my ($self) = @_;

    return $game_over{ident $self};
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
    my ($self) = @_;

    my @defs = @character_defs;

    my $id = 0;
    while (my $key = shift @defs) {
        my @def = @{shift @defs};

        my $facing = pop @def;

        my %def;
        @def{qw(game id name title race x y life energy strength courage_base recruiting_key recruited_by_key warriors riders)} = ($self, $id++, @def);

        my $character = Goodnight::Character->new(\%def);
        $character->set_direction($facing);

        $public_data{ident $self}->{$key} = $character;
    }

    $self->SHADOWS->set_on_horse(0);
    $self->KORINEL->set_on_horse(0);

    $self->LUXOR->set_recruited(1);
    $self->MORKIN->set_recruited(1);
    $self->CORLETH->set_recruited(1);
    $self->RORTHRON->set_recruited(1);

    $self->LUXOR->set_object(Goodnight::Location::Object::MOON_RING);

    push @{$characters{ident $self}}, $_ for values %{$public_data{ident $self}};
}

sub init_armies {
    my ($self) = @_;

    for my $def (@army_defs) {
        my @def = @{$def};

        my $y = pop @def;
        my $x = pop @def;

        my %def;
        @def{qw(game race how_many type)} = ($self, @def);

        my $army = Goodnight::Army->new(\%def);
        $army->guard($x, $y);

        push @{$armies{ident $self}}, $army;
    }
}

sub init_doomguard {
    my ($self) = @_;

    for my $def (@doomguard_defs) {
        my @def = @{$def};

        my $y = pop @def;
        my $x = pop @def;

        my %def;
        @def{qw(game energy how_many type orders target)} = ($self, @def);

        if ($def{orders} == Goodnight::Doomguard::Orders::FOLLOW) {
            $def{target} = $public_data{ident $self}->{$def{target}};
        }
        elsif ($def{orders} == Goodnight::Doomguard::Orders::ROUTE or
               $def{orders} == Goodnight::Doomguard::Orders::GOTO) {
            $def{target} = $self->get_map->get_route_node($def{target});
        }

        my $doomguard = Goodnight::Doomguard->new(\%def);
        $doomguard->guard($x, $y);

        push @{$doomguard{ident $self}}, $doomguard;
    }
}

sub random {
    my ($self, $max) = @_;

    return int(rand($max));
}

@character_defs = (
    LUXOR => [ "Luxor", "Luxor the Moonprince", Goodnight::Race::FREE, 12, 40, 180, 127, 25, 80, 0x17, 0x00, 0, 0, Goodnight::Map::Direction::SOUTHEAST ],
    MORKIN => [ "Morkin", "Morkin", Goodnight::Race::MORKIN, 12, 40, 200, 127, 5, 127, 0x7e, 0x00, 0, 0, Goodnight::Map::Direction::SOUTHEAST ],
    CORLETH => [ "Corleth", "Corleth the Fey", Goodnight::Race::FEY, 12, 40, 180, 127, 20, 96, 0x6b, 0x00, 0, 0, Goodnight::Map::Direction::EAST ],
    RORTHRON => [ "Rorthron", "Rorthron the Wise", Goodnight::Race::WISE, 12, 40, 220, 127, 40, 80, 0x7f, 0x00, 0, 0, Goodnight::Map::Direction::NORTHEAST ],
    GARD => [ "Gard", "the Lord of Gard", Goodnight::Race::FREE, 10, 55, 150, 64, 10, 64, 0x01, 0x01, 500, 1000, Goodnight::Map::Direction::EAST ],
    MARAKITH => [ "Marakith", "the Lord of Marakith", Goodnight::Race::FREE, 43, 32, 150, 64, 10, 64, 0x01, 0x01, 500, 1000, Goodnight::Map::Direction::WEST ],
    XAJORKITH => [ "Xajorkith", "the Lord of Xajorkith", Goodnight::Race::FREE, 45, 59, 150, 64, 15, 64, 0x01, 0x01, 800, 1200, Goodnight::Map::Direction::NORTH ],
    GLOOM => [ "Gloom", "the Lord of Gloom", Goodnight::Race::FREE, 8, 0, 150, 64, 15, 56, 0x01, 0x01, 500, 1000, Goodnight::Map::Direction::EAST ],
    SHIMERIL => [ "Shimeril", "the Lord of Shimeril", Goodnight::Race::FREE, 28, 42, 150, 64, 15, 64, 0x01, 0x01, 800, 1000, Goodnight::Map::Direction::NORTHWEST ],
    KUMAR => [ "Kumar", "the Lord of Kumar", Goodnight::Race::FREE, 57, 29, 150, 64, 10, 64, 0x01, 0x01, 700, 1000, Goodnight::Map::Direction::NORTH ],
    ITHRORN => [ "Ithrorn", "the Lord of Ithrorn", Goodnight::Race::FREE, 57, 15, 150, 64, 15, 64, 0x09, 0x01, 1000, 1200, Goodnight::Map::Direction::NORTHWEST ],
    DAWN => [ "Dawn", "the Lord of Dawn", Goodnight::Race::FREE, 44, 45, 150, 64, 8, 48, 0x01, 0x01, 500, 800, Goodnight::Map::Direction::NORTH ],
    DREAMS => [ "Dreams", "the Lord Of Dreams", Goodnight::Race::FEY, 42, 16, 180 , 64,  20,  90,  0x1f, 0x08, 800,  1200, Goodnight::Map::Direction::NORTH ],
    DREGRIM => [ "Dregrim", "the Lord Of Dregrim", Goodnight::Race::FEY, 59, 43, 150,  64,  15,  80,  0x1f, 0x08, 400,  1000, Goodnight::Map::Direction::NORTH ],
    THIMRATH => [ "Thimrath", "Thimrath the Fey",  Goodnight::Race::FEY, 33, 60, 130,  64,  12,  90,  0x1a, 0x02, 600,  400, Goodnight::Map::Direction::WEST ],
    WHISPERS => [ "Whispers", "the Lord Of Whispers",  Goodnight::Race::FEY, 57, 20, 150,  64,  12,  80,  0x1a, 0x02, 300,  600, Goodnight::Map::Direction::NORTHWEST ],
    SHADOWS => [ "Shadows", "the Lord Of Shadows", Goodnight::Race::FEY, 11, 37, 130,  64,  12,  70,  0x1a, 0x02, 0,  1000, Goodnight::Map::Direction::NORTH ],
    LOTHORIL => [ "Lothoril", "the Lord Of Lothoril",  Goodnight::Race::FEY, 11, 10,  100,  64,  8,  60,  0x1a, 0x02, 200,  500, Goodnight::Map::Direction::EAST ],
    KORINEL => [ "Korinel", "Korinel the Fey", Goodnight::Race::FEY, 23, 21,  120,  64,  12,  60,  0x1a, 0x02, 0,  1000, Goodnight::Map::Direction::NORTH ],
    THRALL => [ "Thrall", "the Lord Of Thrall",  Goodnight::Race::FEY, 33, 38,  150,  64,  10,  70,  0x1a, 0x02, 300,  600, Goodnight::Map::Direction::NORTHWEST ],
    BRITH => [ "Brith", "Lord Brith", Goodnight::Race::FREE, 21, 49,  100,  64,  8,  40,  0x01, 0x01, 500,  300, Goodnight::Map::Direction::NORTHEAST ],
    RORATH => [ "Rorath", "Lord Rorath",  Goodnight::Race::FREE, 23, 60,  100,  64,  8,  50,  0x01, 0x01, 800,  400, Goodnight::Map::Direction::NORTH ],
    TRORN => [ "Trorn", "Lord Trorn", Goodnight::Race::FREE, 54, 50,  100,  64,  8,  35,  0x01, 0x01, 400,  800, Goodnight::Map::Direction::NORTHWEST ],
    MORNING => [ "Morning", "the Lord Of Morning",  Goodnight::Race::FREE, 39, 51,  120,  64,  8,  40,  0x01, 0x01, 300,  800, Goodnight::Map::Direction::NORTH ],
    ATHORIL => [ "Athoril", "Lord Athoril", Goodnight::Race::FREE, 54, 38,  120,  64,  8,  50,  0x01, 0x01, 800,  300, Goodnight::Map::Direction::NORTH ],
    BLOOD => [ "Blood", "Lord Blood",  Goodnight::Race::FREE, 21, 36,  150,  64,  15,  80,  0x01, 0x01, 1200,  0, Goodnight::Map::Direction::NORTH ],
    HERATH => [ "Herath", "Lord Herath",  Goodnight::Race::FREE, 45, 26,  130,  64,  8,  40,  0x01, 0x01, 500,  600, Goodnight::Map::Direction::NORTHEAST ],
    MITHARG => [ "Mitharg", "Lord Mitharg",  Goodnight::Race::FREE, 29, 46,  130,  64,  8,  50,  0x01, 0x01, 500,  600, Goodnight::Map::Direction::NORTH ],
    UTARG => [ "Utarg", "the Utarg Of Utarg",  Goodnight::Race::TARG, 59, 34,  180,  64,  20,  80,  0x00, 0x04, 1000,  0, Goodnight::Map::Direction::WEST ],
    FAWKRIN => [ "Fawkrin", "Fawkrin the Skulkrin",  Goodnight::Race::SKULKRIN, 1, 10,  200,  64,  1,  30,  0x00, 0x20, 0,  0, Goodnight::Map::Direction::EAST ],
    LORGRIM => [ "Lorgrim", "Lorgrim the Wise",  Goodnight::Race::WISE, 62, 0,  200,  64,  20,  70,  0x7f, 0x10, 0,  0, Goodnight::Map::Direction::SOUTH ],
    FARFLAME => [ "Farflame", "Farflame the Dragonlord", Goodnight::Race::DRAGON, 12, 23, 200, 64, 100, 127, 0x00, 0x40, 0, 0, Goodnight::Map::Direction::SOUTHEAST ],
);

@army_defs = (
    [ Goodnight::Race::FREE, 600, Goodnight::Army::Type::WARRIORS, 8, 0 ],
    [ Goodnight::Race::FREE, 200, Goodnight::Army::Type::RIDERS, 46, 3 ],
    [ Goodnight::Race::FOUL, 400, Goodnight::Army::Type::WARRIORS, 28, 4 ],
    [ Goodnight::Race::FOUL, 1000, Goodnight::Army::Type::WARRIORS, 22, 5 ],
    [ Goodnight::Race::FOUL, 300, Goodnight::Army::Type::RIDERS, 32, 6 ],
    [ Goodnight::Race::FOUL, 500, Goodnight::Army::Type::WARRIORS, 23, 7 ],
    [ Goodnight::Race::FOUL, 1200, Goodnight::Army::Type::RIDERS, 29, 7 ],
    [ Goodnight::Race::FOUL, 1100, Goodnight::Army::Type::WARRIORS, 37, 7 ],
    [ Goodnight::Race::FOUL, 400, Goodnight::Army::Type::RIDERS, 40, 8 ],
    [ Goodnight::Race::FREE, 300, Goodnight::Army::Type::WARRIORS, 57, 8 ],
    [ Goodnight::Race::FOUL, 500, Goodnight::Army::Type::WARRIORS, 39, 9 ],
    [ Goodnight::Race::FEY, 200, Goodnight::Army::Type::WARRIORS, 11, 10 ],
    [ Goodnight::Race::FOUL, 300, Goodnight::Army::Type::WARRIORS, 21, 11 ],
    [ Goodnight::Race::FOUL, 250, Goodnight::Army::Type::WARRIORS, 25, 11 ],
    [ Goodnight::Race::FOUL, 1000, Goodnight::Army::Type::RIDERS, 29, 12 ],
    [ Goodnight::Race::FOUL, 300, Goodnight::Army::Type::RIDERS, 36, 12 ],
    [ Goodnight::Race::FREE, 200, Goodnight::Army::Type::RIDERS, 51, 12 ],
    [ Goodnight::Race::FREE, 150, Goodnight::Army::Type::WARRIORS, 62, 12 ],
    [ Goodnight::Race::FOUL, 200, Goodnight::Army::Type::WARRIORS, 16, 13 ],
    [ Goodnight::Race::FREE, 300, Goodnight::Army::Type::WARRIORS, 55, 13 ],
    [ Goodnight::Race::FREE, 700, Goodnight::Army::Type::WARRIORS, 57, 15 ],
    [ Goodnight::Race::FOUL, 250, Goodnight::Army::Type::WARRIORS, 14, 16 ],
    [ Goodnight::Race::FOUL, 500, Goodnight::Army::Type::WARRIORS, 27, 16 ],
    [ Goodnight::Race::FOUL, 200, Goodnight::Army::Type::WARRIORS, 34, 16 ],
    [ Goodnight::Race::FEY, 550, Goodnight::Army::Type::WARRIORS, 42, 16 ],
    [ Goodnight::Race::FREE, 150, Goodnight::Army::Type::RIDERS, 52, 16 ],
    [ Goodnight::Race::FOUL, 250, Goodnight::Army::Type::WARRIORS, 19, 17 ],
    [ Goodnight::Race::FOUL, 150, Goodnight::Army::Type::WARRIORS, 22, 18 ],
    [ Goodnight::Race::FREE, 250, Goodnight::Army::Type::WARRIORS, 54, 18 ],
    [ Goodnight::Race::FOUL, 100, Goodnight::Army::Type::WARRIORS, 14, 20 ],
    [ Goodnight::Race::FREE, 300, Goodnight::Army::Type::WARRIORS, 49, 20 ],
    [ Goodnight::Race::FEY, 150, Goodnight::Army::Type::WARRIORS, 57, 20 ],
    [ Goodnight::Race::FOUL, 900, Goodnight::Army::Type::WARRIORS, 18, 21 ],
    [ Goodnight::Race::FOUL, 100, Goodnight::Army::Type::WARRIORS, 42, 21 ],
    [ Goodnight::Race::FOUL, 350, Goodnight::Army::Type::WARRIORS, 31, 22 ],
    [ Goodnight::Race::FREE, 400, Goodnight::Army::Type::RIDERS, 46, 22 ],
    [ Goodnight::Race::FOUL, 250, Goodnight::Army::Type::WARRIORS, 39, 23 ],
    [ Goodnight::Race::FREE, 200, Goodnight::Army::Type::WARRIORS, 56, 24 ],
    [ Goodnight::Race::FOUL, 200, Goodnight::Army::Type::WARRIORS, 32, 25 ],
    [ Goodnight::Race::FREE, 300, Goodnight::Army::Type::WARRIORS, 45, 26 ],
    [ Goodnight::Race::FREE, 150, Goodnight::Army::Type::RIDERS, 54, 26 ],
    [ Goodnight::Race::FOUL, 200, Goodnight::Army::Type::RIDERS, 34, 27 ],
    [ Goodnight::Race::FOUL, 250, Goodnight::Army::Type::WARRIORS, 17, 28 ],
    [ Goodnight::Race::FREE, 250, Goodnight::Army::Type::WARRIORS, 42, 28 ],
    [ Goodnight::Race::FOUL, 1000, Goodnight::Army::Type::WARRIORS, 24, 29 ],
    [ Goodnight::Race::FOUL, 150, Goodnight::Army::Type::WARRIORS, 30, 29 ],
    [ Goodnight::Race::FREE, 150, Goodnight::Army::Type::RIDERS, 51, 29 ],
    [ Goodnight::Race::FREE, 600, Goodnight::Army::Type::RIDERS, 57, 29 ],
    [ Goodnight::Race::TARG, 200, Goodnight::Army::Type::RIDERS, 55, 31 ],
    [ Goodnight::Race::FOUL, 300, Goodnight::Army::Type::WARRIORS, 21, 32 ],
    [ Goodnight::Race::FOUL, 300, Goodnight::Army::Type::WARRIORS, 23, 32 ],
    [ Goodnight::Race::FREE, 700, Goodnight::Army::Type::WARRIORS, 43, 32 ],
    [ Goodnight::Race::FREE, 250, Goodnight::Army::Type::WARRIORS, 13, 33 ],
    [ Goodnight::Race::FREE, 150, Goodnight::Army::Type::WARRIORS, 34, 33 ],
    [ Goodnight::Race::FREE, 100, Goodnight::Army::Type::RIDERS, 30, 34 ],
    [ Goodnight::Race::TARG, 350, Goodnight::Army::Type::RIDERS, 59, 34 ],
    [ Goodnight::Race::FREE, 400, Goodnight::Army::Type::WARRIORS, 21, 36 ],
    [ Goodnight::Race::FREE, 150, Goodnight::Army::Type::WARRIORS, 54, 38 ],
    [ Goodnight::Race::FREE, 200, Goodnight::Army::Type::WARRIORS, 27, 39 ],
    [ Goodnight::Race::FREE, 200, Goodnight::Army::Type::WARRIORS, 22, 40 ],
    [ Goodnight::Race::FREE, 200, Goodnight::Army::Type::WARRIORS, 25, 40 ],
    [ Goodnight::Race::FREE, 100, Goodnight::Army::Type::WARRIORS, 48, 40 ],
    [ Goodnight::Race::FREE, 150, Goodnight::Army::Type::RIDERS, 42, 41 ],
    [ Goodnight::Race::FEY, 100, Goodnight::Army::Type::RIDERS, 55, 41 ],
    [ Goodnight::Race::FREE, 250, Goodnight::Army::Type::RIDERS, 17, 42 ],
    [ Goodnight::Race::FREE, 750, Goodnight::Army::Type::WARRIORS, 28, 42 ],
    [ Goodnight::Race::FREE, 100, Goodnight::Army::Type::RIDERS, 37, 43 ],
    [ Goodnight::Race::FEY, 500, Goodnight::Army::Type::WARRIORS, 59, 43 ],
    [ Goodnight::Race::FREE, 550, Goodnight::Army::Type::WARRIORS, 44, 45 ],
    [ Goodnight::Race::FREE, 150, Goodnight::Army::Type::WARRIORS, 29, 46 ],
    [ Goodnight::Race::FREE, 100, Goodnight::Army::Type::RIDERS, 42, 46 ],
    [ Goodnight::Race::FREE, 150, Goodnight::Army::Type::WARRIORS, 7, 47 ],
    [ Goodnight::Race::FREE, 250, Goodnight::Army::Type::WARRIORS, 10, 47 ],
    [ Goodnight::Race::FREE, 200, Goodnight::Army::Type::WARRIORS, 48, 48 ],
    [ Goodnight::Race::FREE, 150, Goodnight::Army::Type::RIDERS, 21, 49 ],
    [ Goodnight::Race::FREE, 250, Goodnight::Army::Type::RIDERS, 45, 49 ],
    [ Goodnight::Race::FREE, 150, Goodnight::Army::Type::WARRIORS, 54, 50 ],
    [ Goodnight::Race::FREE, 200, Goodnight::Army::Type::WARRIORS, 39, 51 ],
    [ Goodnight::Race::FREE, 150, Goodnight::Army::Type::WARRIORS, 42, 51 ],
    [ Goodnight::Race::FREE, 150, Goodnight::Army::Type::WARRIORS, 50, 51 ],
    [ Goodnight::Race::FREE, 200, Goodnight::Army::Type::WARRIORS, 46, 52 ],
    [ Goodnight::Race::FREE, 250, Goodnight::Army::Type::WARRIORS, 12, 54 ],
    [ Goodnight::Race::FREE, 250, Goodnight::Army::Type::WARRIORS, 25, 54 ],
    [ Goodnight::Race::FREE, 200, Goodnight::Army::Type::WARRIORS, 44, 54 ],
    [ Goodnight::Race::FREE, 150, Goodnight::Army::Type::WARRIORS, 55, 54 ],
    [ Goodnight::Race::FREE, 100, Goodnight::Army::Type::RIDERS, 7, 55 ],
    [ Goodnight::Race::FREE, 600, Goodnight::Army::Type::RIDERS, 10, 55 ],
    [ Goodnight::Race::FREE, 250, Goodnight::Army::Type::WARRIORS, 17, 56 ],
    [ Goodnight::Race::FREE, 150, Goodnight::Army::Type::WARRIORS, 21, 56 ],
    [ Goodnight::Race::FREE, 150, Goodnight::Army::Type::WARRIORS, 37, 56 ],
    [ Goodnight::Race::FREE, 150, Goodnight::Army::Type::WARRIORS, 8, 57 ],
    [ Goodnight::Race::FREE, 200, Goodnight::Army::Type::WARRIORS, 12, 57 ],
    [ Goodnight::Race::FREE, 200, Goodnight::Army::Type::WARRIORS, 39, 58 ],
    [ Goodnight::Race::FREE, 250, Goodnight::Army::Type::WARRIORS, 56, 58 ],
    [ Goodnight::Race::FREE, 150, Goodnight::Army::Type::RIDERS, 63, 58 ],
    [ Goodnight::Race::FREE, 300, Goodnight::Army::Type::WARRIORS, 42, 59 ],
    [ Goodnight::Race::FREE, 750, Goodnight::Army::Type::RIDERS, 45, 59 ],
    [ Goodnight::Race::FREE, 50, Goodnight::Army::Type::RIDERS, 4, 60 ],
    [ Goodnight::Race::FEY, 300, Goodnight::Army::Type::RIDERS, 33, 60 ],
    [ Goodnight::Race::FREE, 250, Goodnight::Army::Type::RIDERS, 23, 60 ],
    [ Goodnight::Race::FREE, 250, Goodnight::Army::Type::WARRIORS, 59, 60 ],
    [ Goodnight::Race::FREE, 200, Goodnight::Army::Type::WARRIORS, 14, 60 ],
);

@doomguard_defs = (
    [ 0, 1000, Goodnight::Army::Type::RIDERS, Goodnight::Doomguard::Orders::FOLLOW, "LUXOR", 29, 7 ],
    [ 0, 1000, Goodnight::Army::Type::RIDERS, Goodnight::Doomguard::Orders::FOLLOW, "LUXOR", 29, 7 ],
    [ 0, 1000, Goodnight::Army::Type::RIDERS, Goodnight::Doomguard::Orders::FOLLOW, "LUXOR", 29, 7 ],
    [ 0, 1000, Goodnight::Army::Type::RIDERS, Goodnight::Doomguard::Orders::FOLLOW, "LUXOR", 29, 7 ],
    [ 0, 1000, Goodnight::Army::Type::RIDERS, Goodnight::Doomguard::Orders::FOLLOW, "LUXOR", 29, 7 ],
    [ 0, 1000, Goodnight::Army::Type::RIDERS, Goodnight::Doomguard::Orders::FOLLOW, "LUXOR", 29, 7 ],
    [ 0, 1000, Goodnight::Army::Type::RIDERS, Goodnight::Doomguard::Orders::FOLLOW, "LUXOR", 29, 7 ],
    [ 0, 1000, Goodnight::Army::Type::RIDERS, Goodnight::Doomguard::Orders::FOLLOW, "LUXOR", 29, 7 ],
    [ 0, 1000, Goodnight::Army::Type::RIDERS, Goodnight::Doomguard::Orders::FOLLOW, "LUXOR", 29, 7 ],
    [ 0, 1000, Goodnight::Army::Type::RIDERS, Goodnight::Doomguard::Orders::FOLLOW, "LUXOR", 29, 7 ],
    [ 0, 1000, Goodnight::Army::Type::RIDERS, Goodnight::Doomguard::Orders::FOLLOW, "MORKIN", 29, 7 ],
    [ 0, 1000, Goodnight::Army::Type::RIDERS, Goodnight::Doomguard::Orders::FOLLOW, "CORLETH", 29, 7 ],
    [ 0, 1000, Goodnight::Army::Type::RIDERS, Goodnight::Doomguard::Orders::FOLLOW, "RORTHRON", 29, 7 ],
    [ 0, 1000, Goodnight::Army::Type::RIDERS, Goodnight::Doomguard::Orders::FOLLOW, "GARD", 29, 7 ],
    [ 0, 1000, Goodnight::Army::Type::RIDERS, Goodnight::Doomguard::Orders::FOLLOW, "MARAKITH", 29, 7 ],
    [ 0, 1000, Goodnight::Army::Type::RIDERS, Goodnight::Doomguard::Orders::FOLLOW, "XAJORKITH", 29, 7 ],
    [ 0, 1000, Goodnight::Army::Type::RIDERS, Goodnight::Doomguard::Orders::FOLLOW, "SHIMERIL", 29, 7 ],
    [ 0, 1000, Goodnight::Army::Type::RIDERS, Goodnight::Doomguard::Orders::FOLLOW, "KUMAR", 29, 7 ],
    [ 0, 1000, Goodnight::Army::Type::RIDERS, Goodnight::Doomguard::Orders::FOLLOW, "ITHRORN", 29, 7 ],
    [ 0, 1000, Goodnight::Army::Type::RIDERS, Goodnight::Doomguard::Orders::FOLLOW, "DAWN", 29, 7 ],
    [ 0, 1000, Goodnight::Army::Type::RIDERS, Goodnight::Doomguard::Orders::FOLLOW, "DREGRIM", 29, 7 ],
    [ 0, 1000, Goodnight::Army::Type::RIDERS, Goodnight::Doomguard::Orders::FOLLOW, "THIMRATH", 29, 7 ],
    [ 0, 1000, Goodnight::Army::Type::RIDERS, Goodnight::Doomguard::Orders::FOLLOW, "SHADOWS", 29, 7 ],
    [ 0, 1000, Goodnight::Army::Type::RIDERS, Goodnight::Doomguard::Orders::FOLLOW, "THRALL", 29, 7 ],
    [ 0, 1000, Goodnight::Army::Type::RIDERS, Goodnight::Doomguard::Orders::FOLLOW, "BRITH", 29, 7 ],
    [ 0, 1000, Goodnight::Army::Type::RIDERS, Goodnight::Doomguard::Orders::FOLLOW, "RORATH", 29, 7 ],
    [ 0, 1000, Goodnight::Army::Type::RIDERS, Goodnight::Doomguard::Orders::FOLLOW, "TRORN", 29, 7 ],
    [ 0, 1000, Goodnight::Army::Type::RIDERS, Goodnight::Doomguard::Orders::FOLLOW, "MORNING", 29, 7 ],
    [ 0, 1000, Goodnight::Army::Type::RIDERS, Goodnight::Doomguard::Orders::FOLLOW, "ATHORIL", 29, 7 ],
    [ 0, 1000, Goodnight::Army::Type::RIDERS, Goodnight::Doomguard::Orders::FOLLOW, "BLOOD", 29, 7 ],
    [ 0, 1000, Goodnight::Army::Type::RIDERS, Goodnight::Doomguard::Orders::FOLLOW, "HERATH", 29, 7 ],
    [ 0, 1000, Goodnight::Army::Type::RIDERS, Goodnight::Doomguard::Orders::FOLLOW, "MITHARG", 29, 7 ],
    [ 0, 1200, Goodnight::Army::Type::RIDERS, Goodnight::Doomguard::Orders::ROUTE, 6, 29, 7 ],
    [ 0, 1200, Goodnight::Army::Type::RIDERS, Goodnight::Doomguard::Orders::ROUTE, 6, 29, 7 ],
    [ 0, 1200, Goodnight::Army::Type::RIDERS, Goodnight::Doomguard::Orders::ROUTE, 6, 29, 7 ],
    [ 0, 1200, Goodnight::Army::Type::RIDERS, Goodnight::Doomguard::Orders::ROUTE, 6, 29, 7 ],
    [ 0, 1200, Goodnight::Army::Type::RIDERS, Goodnight::Doomguard::Orders::ROUTE, 6, 29, 7 ],
    [ 0, 1200, Goodnight::Army::Type::RIDERS, Goodnight::Doomguard::Orders::ROUTE, 6, 29, 7 ],
    [ 0, 1200, Goodnight::Army::Type::RIDERS, Goodnight::Doomguard::Orders::ROUTE, 6, 29, 7 ],
    [ 0, 1200, Goodnight::Army::Type::RIDERS, Goodnight::Doomguard::Orders::ROUTE, 6, 29, 7 ],
    [ 0, 1200, Goodnight::Army::Type::WARRIORS, Goodnight::Doomguard::Orders::ROUTE, 3, 22, 5 ],
    [ 0, 1200, Goodnight::Army::Type::WARRIORS, Goodnight::Doomguard::Orders::ROUTE, 3, 22, 5 ],
    [ 0, 1200, Goodnight::Army::Type::WARRIORS, Goodnight::Doomguard::Orders::ROUTE, 3, 22, 5 ],
    [ 0, 1200, Goodnight::Army::Type::WARRIORS, Goodnight::Doomguard::Orders::ROUTE, 3, 22, 5 ],
    [ 0, 1200, Goodnight::Army::Type::WARRIORS, Goodnight::Doomguard::Orders::ROUTE, 7, 37, 7 ],
    [ 0, 1200, Goodnight::Army::Type::WARRIORS, Goodnight::Doomguard::Orders::ROUTE, 7, 37, 7 ],
    [ 0, 1200, Goodnight::Army::Type::WARRIORS, Goodnight::Doomguard::Orders::ROUTE, 7, 37, 7 ],
    [ 0, 1200, Goodnight::Army::Type::WARRIORS, Goodnight::Doomguard::Orders::ROUTE, 7, 37, 7 ],
    [ 0, 1000, Goodnight::Army::Type::RIDERS, Goodnight::Doomguard::Orders::FOLLOW, "MORKIN", 29, 7 ],
    [ 0, 1000, Goodnight::Army::Type::RIDERS, Goodnight::Doomguard::Orders::FOLLOW, "MORKIN", 29, 7 ],
    [ 0, 1200, Goodnight::Army::Type::WARRIORS, Goodnight::Doomguard::Orders::ROUTE, 14, 29, 12 ],
    [ 0, 1200, Goodnight::Army::Type::WARRIORS, Goodnight::Doomguard::Orders::ROUTE, 14, 29, 12 ],
    [ 0, 1200, Goodnight::Army::Type::WARRIORS, Goodnight::Doomguard::Orders::ROUTE, 14, 29, 12 ],
    [ 0, 1200, Goodnight::Army::Type::WARRIORS, Goodnight::Doomguard::Orders::ROUTE, 14, 29, 12 ],
    [ 0, 1200, Goodnight::Army::Type::WARRIORS, Goodnight::Doomguard::Orders::ROUTE, 14, 29, 12 ],
    [ 0, 1200, Goodnight::Army::Type::WARRIORS, Goodnight::Doomguard::Orders::ROUTE, 14, 29, 12 ],
    [ 0, 1200, Goodnight::Army::Type::WARRIORS, Goodnight::Doomguard::Orders::ROUTE, 14, 29, 12 ],
    [ 0, 1200, Goodnight::Army::Type::WARRIORS, Goodnight::Doomguard::Orders::ROUTE, 14, 29, 12 ],
    [ 0, 1200, Goodnight::Army::Type::WARRIORS, Goodnight::Doomguard::Orders::ROUTE, 14, 29, 12 ],
    [ 0, 1200, Goodnight::Army::Type::WARRIORS, Goodnight::Doomguard::Orders::ROUTE, 14, 29, 12 ],
    [ 0, 1200, Goodnight::Army::Type::WARRIORS, Goodnight::Doomguard::Orders::ROUTE, 14, 29, 12 ],
    [ 0, 1200, Goodnight::Army::Type::WARRIORS, Goodnight::Doomguard::Orders::ROUTE, 14, 29, 12 ],
    [ 0, 1200, Goodnight::Army::Type::WARRIORS, Goodnight::Doomguard::Orders::ROUTE, 14, 29, 12 ],
    [ 0, 1200, Goodnight::Army::Type::WARRIORS, Goodnight::Doomguard::Orders::ROUTE, 14, 29, 12 ],
    [ 0, 1200, Goodnight::Army::Type::RIDERS, Goodnight::Doomguard::Orders::ROUTE, 14, 29, 12 ],
    [ 0, 1200, Goodnight::Army::Type::RIDERS, Goodnight::Doomguard::Orders::ROUTE, 14, 29, 12 ],
    [ 0, 1200, Goodnight::Army::Type::RIDERS, Goodnight::Doomguard::Orders::ROUTE, 14, 29, 12 ],
    [ 0, 1200, Goodnight::Army::Type::RIDERS, Goodnight::Doomguard::Orders::ROUTE, 14, 29, 12 ],
    [ 0, 1200, Goodnight::Army::Type::RIDERS, Goodnight::Doomguard::Orders::ROUTE, 14, 29, 12 ],
    [ 0, 1200, Goodnight::Army::Type::RIDERS, Goodnight::Doomguard::Orders::ROUTE, 14, 29, 12 ],
    [ 0, 1200, Goodnight::Army::Type::RIDERS, Goodnight::Doomguard::Orders::ROUTE, 14, 29, 12 ],
    [ 0, 1200, Goodnight::Army::Type::RIDERS, Goodnight::Doomguard::Orders::ROUTE, 14, 29, 12 ],
    [ 0, 1200, Goodnight::Army::Type::WARRIORS, Goodnight::Doomguard::Orders::ROUTE, 32, 18, 21 ],
    [ 0, 1200, Goodnight::Army::Type::WARRIORS, Goodnight::Doomguard::Orders::ROUTE, 32, 18, 21 ],
    [ 0, 1200, Goodnight::Army::Type::WARRIORS, Goodnight::Doomguard::Orders::ROUTE, 32, 18, 21 ],
    [ 0, 1200, Goodnight::Army::Type::WARRIORS, Goodnight::Doomguard::Orders::ROUTE, 32, 18, 21 ],
    [ 0, 1200, Goodnight::Army::Type::WARRIORS, Goodnight::Doomguard::Orders::ROUTE, 32, 18, 21 ],
    [ 0, 1200, Goodnight::Army::Type::WARRIORS, Goodnight::Doomguard::Orders::ROUTE, 32, 18, 21 ],
    [ 0, 1200, Goodnight::Army::Type::WARRIORS, Goodnight::Doomguard::Orders::ROUTE, 32, 18, 21 ],
    [ 0, 1200, Goodnight::Army::Type::WARRIORS, Goodnight::Doomguard::Orders::ROUTE, 32, 18, 21 ],
    [ 0, 1200, Goodnight::Army::Type::WARRIORS, Goodnight::Doomguard::Orders::ROUTE, 32, 18, 21 ],
    [ 0, 1200, Goodnight::Army::Type::WARRIORS, Goodnight::Doomguard::Orders::ROUTE, 32, 18, 21 ],
    [ 0, 1200, Goodnight::Army::Type::WARRIORS, Goodnight::Doomguard::Orders::ROUTE, 32, 18, 21 ],
    [ 0, 1200, Goodnight::Army::Type::WARRIORS, Goodnight::Doomguard::Orders::ROUTE, 32, 18, 21 ],
    [ 0, 1200, Goodnight::Army::Type::WARRIORS, Goodnight::Doomguard::Orders::ROUTE, 32, 18, 21 ],
    [ 0, 1200, Goodnight::Army::Type::WARRIORS, Goodnight::Doomguard::Orders::ROUTE, 32, 18, 21 ],
    [ 0, 1200, Goodnight::Army::Type::WARRIORS, Goodnight::Doomguard::Orders::ROUTE, 32, 18, 21 ],
    [ 0, 1200, Goodnight::Army::Type::WARRIORS, Goodnight::Doomguard::Orders::ROUTE, 32, 18, 21 ],
    [ 0, 1200, Goodnight::Army::Type::RIDERS, Goodnight::Doomguard::Orders::ROUTE, 32, 18, 21 ],
    [ 0, 1200, Goodnight::Army::Type::RIDERS, Goodnight::Doomguard::Orders::ROUTE, 32, 18, 21 ],
    [ 0, 1200, Goodnight::Army::Type::RIDERS, Goodnight::Doomguard::Orders::ROUTE, 32, 18, 21 ],
    [ 0, 1200, Goodnight::Army::Type::RIDERS, Goodnight::Doomguard::Orders::ROUTE, 32, 18, 21 ],
    [ 0, 1200, Goodnight::Army::Type::WARRIORS, Goodnight::Doomguard::Orders::ROUTE, 44, 24, 29 ],
    [ 0, 1200, Goodnight::Army::Type::WARRIORS, Goodnight::Doomguard::Orders::ROUTE, 44, 24, 29 ],
    [ 0, 1200, Goodnight::Army::Type::WARRIORS, Goodnight::Doomguard::Orders::ROUTE, 44, 24, 29 ],
    [ 0, 1200, Goodnight::Army::Type::WARRIORS, Goodnight::Doomguard::Orders::ROUTE, 44, 24, 29 ],
    [ 0, 1000, Goodnight::Army::Type::RIDERS, Goodnight::Doomguard::Orders::WANDER, undef, 7, 21 ],
    [ 0, 1000, Goodnight::Army::Type::RIDERS, Goodnight::Doomguard::Orders::WANDER, undef, 27, 16 ],
    [ 0, 1000, Goodnight::Army::Type::RIDERS, Goodnight::Doomguard::Orders::WANDER, undef, 40, 8 ],
    [ 0, 1000, Goodnight::Army::Type::RIDERS, Goodnight::Doomguard::Orders::WANDER, undef, 39, 23 ],
    [ 0, 1000, Goodnight::Army::Type::RIDERS, Goodnight::Doomguard::Orders::WANDER, undef, 21, 32 ],
    [ 0, 1000, Goodnight::Army::Type::RIDERS, Goodnight::Doomguard::Orders::WANDER, undef, 23, 32 ],
    [ 0, 1000, Goodnight::Army::Type::WARRIORS, Goodnight::Doomguard::Orders::WANDER, undef, 17, 28 ],
    [ 0, 1000, Goodnight::Army::Type::WARRIORS, Goodnight::Doomguard::Orders::WANDER, undef, 18, 3 ],
    [ 0, 1000, Goodnight::Army::Type::WARRIORS, Goodnight::Doomguard::Orders::WANDER, undef, 30, 29 ],
    [ 0, 1000, Goodnight::Army::Type::WARRIORS, Goodnight::Doomguard::Orders::WANDER, undef, 16, 13 ],
    [ 0, 1000, Goodnight::Army::Type::WARRIORS, Goodnight::Doomguard::Orders::WANDER, undef, 31, 22 ],
    [ 0, 1000, Goodnight::Army::Type::WARRIORS, Goodnight::Doomguard::Orders::WANDER, undef, 6, 37 ],
    [ 0, 1200, Goodnight::Army::Type::WARRIORS, Goodnight::Doomguard::Orders::GOTO, 6, 29, 7 ],
    [ 0, 1200, Goodnight::Army::Type::WARRIORS, Goodnight::Doomguard::Orders::GOTO, 6, 29, 7 ],
    [ 0, 1200, Goodnight::Army::Type::WARRIORS, Goodnight::Doomguard::Orders::GOTO, 6, 29, 7 ],
    [ 0, 1200, Goodnight::Army::Type::WARRIORS, Goodnight::Doomguard::Orders::GOTO, 6, 29, 7 ],
    [ 0, 1200, Goodnight::Army::Type::WARRIORS, Goodnight::Doomguard::Orders::GOTO, 6, 29, 12 ],
    [ 0, 1200, Goodnight::Army::Type::WARRIORS, Goodnight::Doomguard::Orders::GOTO, 6, 22, 5 ],
    [ 0, 1200, Goodnight::Army::Type::WARRIORS, Goodnight::Doomguard::Orders::GOTO, 6, 37, 7 ],
    [ 0, 1200, Goodnight::Army::Type::WARRIORS, Goodnight::Doomguard::Orders::GOTO, 6, 23, 7 ],
    [ 0, 1200, Goodnight::Army::Type::WARRIORS, Goodnight::Doomguard::Orders::GOTO, 6, 28, 4 ],
    [ 0, 1200, Goodnight::Army::Type::WARRIORS, Goodnight::Doomguard::Orders::GOTO, 14, 25, 11 ],
    [ 0, 1200, Goodnight::Army::Type::WARRIORS, Goodnight::Doomguard::Orders::GOTO, 7, 36, 12 ],
    [ 0, 1200, Goodnight::Army::Type::WARRIORS, Goodnight::Doomguard::Orders::GOTO, 7, 40, 8 ],
    [ 0, 1200, Goodnight::Army::Type::WARRIORS, Goodnight::Doomguard::Orders::GOTO, 7, 39, 9 ],
    [ 0, 1200, Goodnight::Army::Type::WARRIORS, Goodnight::Doomguard::Orders::GOTO, 6, 32, 6 ],
    [ 0, 1200, Goodnight::Army::Type::WARRIORS, Goodnight::Doomguard::Orders::GOTO, 3, 21, 11 ],
    [ 0, 1000, Goodnight::Army::Type::RIDERS, Goodnight::Doomguard::Orders::GOTO, 6, 29, 9 ],
    [ 0, 1000, Goodnight::Army::Type::RIDERS, Goodnight::Doomguard::Orders::GOTO, 6, 33, 7 ],
    [ 0, 1000, Goodnight::Army::Type::RIDERS, Goodnight::Doomguard::Orders::GOTO, 6, 30, 6 ],
    [ 0, 1000, Goodnight::Army::Type::RIDERS, Goodnight::Doomguard::Orders::GOTO, 6, 27, 6 ],
    [ 0, 1000, Goodnight::Army::Type::RIDERS, Goodnight::Doomguard::Orders::GOTO, 6, 26, 7 ],
);

1;
