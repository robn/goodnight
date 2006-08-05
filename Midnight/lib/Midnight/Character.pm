package Midnight::Character;

use warnings;
use strict;

use base qw(Midnight::Unit);

use Class::Std;

my %id                  : ATTR( :get<id> );
my %name                : ATTR( :get<name> );
my %title               : ATTR( :get<title> );
my %life                : ATTR( :get<life> );
my %strength            : ATTR( :get<strength> :set<strength> );
my %courage_base        : ATTR( :get<courage_base> );
my %courage             : ATTR;
my %direction           : ATTR( :get<direction> :set<direction> );
my %object              : ATTR( :get<object> :set<object> );
my %found               : ATTR;
my %warriors            : ATTR( :get<warriors> );
my %riders              : ATTR( :get<riders> );
my %time                : ATTR( :get<time> );
my %killed              : ATTR( :get<killed> :set<killed> );
my %battle              : ATTR( :get<battle> :set<battle> );
my %on_horse            : ATTR( :set<on_horse> );
my %recruiting_key      : ATTR( :get<recruiting_key> );
my %recruited_by_key    : ATTR( :get<recruited_by_key> );
my %recruited           : ATTR( :set<recruited> );
my %hidden              : ATTR( :set<hidden> );

sub BUILD {
}

sub get_courage {
    my ($self) = @_;

    $self->calculate_courage;
    return $courage{ident $self};
}

sub calculate_courage {
    my ($self) = @_;

    my $fear = $courage_base{ident $self} - $self->get_location->get_ice_fear / 7;
    $courage{ident $self} = Midnight::Character::Courage->by_ordinal($fear / 8);
}

sub set_location {
    my ($self, $location) = @_;

    if ($self->get_location) {
        $self->get_location->remove_character($self);
    }

    $self->SUPER::set_location($location);
    $self->get_location->add_character($self);
}

sub is_alive {
    my ($self) = @_;

    return $life{ident $self} > 0;
}

sub kill {
    my ($self) = @_;

    $life{ident $self} = 0;
}

sub is_hidden {
    my ($self) = @_;

    return $hidden{ident $self};
}

sub can_hide {
    my ($self) = @_;

    return $self != $self->get_game->MORKIN and
           $self->get_warriors->get_how_many == 0 and
           $self->get_riders->get_how_many == 0;
}

sub can_walk_forward {
    my ($self) = @_;

    my $dest = $self->get_game->get_map->get_in_front($self->get_location, $direction{ident $self});

    return
        $self->can_leave and
        not $time{ident $self}->is_night and
        $self->get_condition != Midnight::Unit::Condition::UTTERLY_TIRED and
        $dest->get_feature != Midnight::Location::Feature::FROZEN_WASTE and
        @{$dest->get_characters} < 29 and
        @{$dest->get_armies} == 0 and
        (not $dest->get_guard or $dest->get_guard->get_race != Midnight::Race::FOUL);
}

sub can_leave {
    my ($self) = @_;

    my $object = $self->get_location->get_object;
    my $guard = $self->get_location->get_guard;

    return
        $self->is_alive and not $self->is_hidden and
        ($time{ident $self}->is_dawn or (
            @{$self->get_location->get_armies} == 0 and
            (not $guard or $guard->get_race != Midnight::Race::FOUL))) and
        $object != Midnight::Location::Object::DRAGONS and
        $object != Midnight::Location::Object::ICE_TROLLS and
        $object != Midnight::Location::Object::SKULKRIN and
        $object != Midnight::Location::Object::WOLVES;
}

sub walk_forward {
    my ($self) = @_;

    my $dest = $self->get_game->get_map->get_in_front($self->get_location, $direction{ident $self});
    $self->set_location($dest);

    my $drain = 2;
    if ($direction{ident $self}->is_diagonal) {
        $drain++;
    }

    if (not $on_horse{ident $self}) {
        $drain *= 2;
    }

    if ($dest->get_feature == Midnight::Location::Feature::DOWNS) {
        $drain++;
    }
    elsif ($dest->get_feature == Midnight::Location::Feature::MOUNTAIN) {
        $drain += 4;
    }
    elsif ($dest->get_feature == Midnight::Location::Feature::FOREST and
           $self->get_race != Midnight::Race::FEY) {
        $drain += 3;
    }

    if ($self == $self->get_game->FARFLAME) {
        $drain = 1;
    }

    $time{ident $self}->decrease($drain);

    $self->set_energy($self->get_energy - $drain);
    $riders{ident $self}->set_energy($riders{ident $self}->get_energy - $drain);
    $warriors{ident $self}->set_energy($warriors{ident $self}->get_energy - $drain);

    $self->set_battle(undef);
    $self->clear_killed;
    $self->clear_found;
}

sub can_recruit {
    my ($self, $them) = @_;

    return not $them->is_recruited and 
           $them->get_location == $self->get_location and
           ($recruiting_key{ident $self} & $them->get_recruiting_key) and
           (@{$self->get_location->get_armies} == 0 or $self == $self->get_game->MORKIN);
}

sub recruit {
    my ($self, $them) = @_;

    if ($self->can_recruit($them)) {
        $them->set_recruited(1);
        return 1;
    }

    return 0;
}

sub is_recruited {
    my ($self) = @_;

    return $recruited{ident $self};
}

sub can_recruit_men {
    my ($self) = @_;

    my $guards = $self->get_location->get_guard;
    return $guards and $guards->get_race == $self->get_race and
           $guards->get_how_many > 125 and
               (($guards->get_type == Midnight::Army::Type::RIDERS and
                 $self->get_riders->get_how_many < 1175) or
                ($guards->get_type == Midnight::Army::Type::WARRIORS and
                 $self->get_warriors->get_how_many < 1175)) and
           (@{$self->get_location->get_armies} == 0 or $self == $self->get_game->MORKIN);
}

sub recruit_men {
    my ($self) = @_;

    if (not $self->can_recruit_men) {
        return 0;
    }

    my $guards = $self->get_location->get_guard;
    $guards->decrease_numbers(100);
    if ($guards->get_type == Midnight::Army::Type::RIDERS) {
        $self->get_riders->increase_numbers(100);
    }
    elsif ($guards->get_type == Midnight::Army::Type::WARRIORS) {
        $self->get_warriors->increase_numbers(100);
    }

    return 1;
}

sub can_stand_on_guard {
    my ($self) = @_;

    my $guards = $self->get_location->get_guard;

    return $guards and $guards->get_race = $self->get_race and
           $guards->get_how_many < 1175 and
               (($guards->get_type == Midnight::Army::Type::RIDERS and
                 $self->get_riders->get_how_many >= 100) or
                ($guards->get_type == Midnight::Army::Type::WARRIORS and
                 $self->get_warriors->get_how_many >= 100)) and
           (@{$self->get_location->get_armies} == 0 or $self == $self->get_game->MORKIN);

}

sub stand_on_guard {
    my ($self) = @_;

    if (not $self->can_stand_on_guard) {
        return 0;
    }

    my $guards = $self->get_location->get_guard;
    $guards->increase_numbers(100);
    if ($guards->get_type == Midnight::Army::Type::RIDERS) {
        $self->get_riders->decrease_numbers(100);
    }
    elsif ($guards->get_type == Midnight::Army::Type::WARRIORS) {
        $self->get_warriors->decrease_numbers(100);
    }

    return 1;
}

sub is_on_horse {
    my ($self) = @_;

    return $on_horse{ident $self};
}

sub can_attack {
    my ($self) = @_;

    my $dest = $self->get_game->get_map->get_in_front($self->get_location, $direction{ident $self});

    return $self->can_leave and
               (@{$dest->get_armies} != 0 or
                ($dest->get_guard and $dest->get_guard->get_race == Midnight::Race::FOUL)) and
           $self->get_courage != Midnight::Character::Courage::UTTERLY_AFRAID;
               
}

sub describe_battle {
    my ($self) = @_;

    my $battle = $battle{ident $self};
    my $riders = $riders{ident $self};
    my $warriors = $warriors{ident $self};

    my $desc = "In the battle of " . $battle->get_location->get_domain . " ";

    if ($riders->get_casualties != 0 or $warriors->get_casualties != 0) {
        $desc .= $self->get_name . " lost ";
        if ($riders->get_casualties != 0) {
            $desc .= $riders->get_casualties . " riders";
        }
        if ($riders->get_casualties != 0 or $warriors->get_casualties != 0) {
            $desc .= " and ";
        }
        if ($warriors->get_casualties != 0) {
            $desc .= $warriors->get_casualties . " warriors";
        }
        $desc .= ". ";
    }

    $desc .= $self->get_name . " alone slew ";
    $desc .= $self->get_enemy_killed . " of the Enemy. ";

    if ($riders->get_enemy_killed != 0) {
        $desc .= "His riders killed " . $riders->get_enemy_killed . " of the enemy. ";
    }
    if ($warriors->get_enemy_killed != 0) {
        $desc .= "His warriors killed " . $warriors->get_enemy_killed . " of the enemy. ";
    }

    if ($battle->get_winner) {
        $desc .= "Victory went to the " . $battle->get_winner . "!";
    }
    else {
        $desc .= "The battle continues!";
    }

    return $desc;
}

sub increment_energy {
    my ($self, $increment) = @_;

    $self->SUPER::increment_energy(9 + $increment);
    if ($warriors{ident $self}) {
        $warriors{ident $self}->increment_energy($increment);
    }
    if ($riders{ident $self}) {
        $riders{ident $self}->increment_energy($increment);
    }
}

sub dawn {
    my ($self) = @_;

    $time{ident $self}->dawn;
    if ($self->is_alive) {
        if ($riders{ident $self}) {
            $riders{ident $self}->dawn;
        }
        if ($warriors{ident $self}) {
            $warriors{ident $self}->dawn;
        }
    }

    $self->clear_found;
    $self->clear_killed;
}

sub clear_found {
    my ($self) = @_;

    undef $found{ident $self};
}

sub seek {
    my ($self) = @_;

    my $object = $self->get_location->get_object;
    my $found = $object;

    if ($object == Midnight::Location::Object::DRAGONSLAYER or
        $object == Midnight::Location::Object::WOLFSLAYER) {
        if ($self->get_object != Midnight::Location::Object::ICE_CROWN and
            $self->get_object != Midnight::Location::Object::MOON_RING) {
            $self->get_location->set_object($self->get_object);
            $self->set_object($object);
        }
    }

    elsif ($object == Midnight::Location::Object::WILD_HORSES) {
        if ($self->get_race == Midnight::Race::FREE or
            $self->get_race == Midnight::Race::FEY or
            $self->get_race == Midnight::Race::TARG or
            $self->get_race == Midnight::Race::WISE) {
            $self->set_on_horse(1);
        }
    }

    elsif ($object == Midnight::Location::Object::SHELTER) {
        $self->increment_energy(0x10);
        $self->get_location->set_object(Midnight::Location::Object::NOTHING);
    }

    elsif ($object == Midnight::Location::Object::HAND_OF_DARK) {
        $time{ident $self}->night;
        $self->get_location->set_object(Midnight::Location::Object::NOTHING);
    }

    elsif ($object == Midnight::Location::Object::CUP_OF_DREAMS) {
        $time{ident $self}->dawn;
        $self->get_location->set_object(Midnight::Location::Object::NOTHING);
    }

    elsif ($object == Midnight::Location::Object::WATERS_OF_LIFE) {
        $self->set_energy(0x78);
        $warriors{ident $self}->set_energy(0x78);
        $riders{ident $self}->set_energy(0x78);
        $self->get_location->set_object(Midnight::Location::Object::NOTHING);
    }

    elsif ($object == Midnight::Location::Object::SHADOWS_OF_DEATH) {
        $self->set_energy(0);
        $warriors{ident $self}->set_energy(0);
        $riders{ident $self}->set_energy(0);
        $self->get_location->set_object(Midnight::Location::Object::NOTHING);
    }

    elsif ($object == Midnight::Location::Object::ICE_CROWN or
           $object == Midnight::Location::Object::MOON_RING) {
        if ($self == $self->get_game->MORKIN) {
            $self->get_location->set_object($self->get_object);
            $self->set_object($object);
        }
        else {
            return Midnight::Location::Object::NOTHING;
        }
    }

    return $object;
}

sub drop_object {
    my ($self) = @_;

    $self->get_location->set_object($self->get_object);
    $self->set_object(Midnight::Location::Object::NOTHING);
}

sub can_fight {
    my ($self) = @_;

    my $object = $self->get_location->get_object;
    return
        ! $self->is_hidden and (
            $object == Midnight::Location::Object::DRAGONS or
            $object == Midnight::Location::Object::ICE_TROLLS or
            $object == Midnight::Location::Object::SKULKRIN or
            $object == Midnight::Location::Object::WOLVES) and
        (@{$self->get_location->get_armies} == 0 or $self == $self->get_game->MORKIN);
}

sub fight {
    my ($self) = @_;

    my $object = $self->get_location->get_object;
    my $killed = $object;

    for my $character (@{$self->get_location->get_characters}) {
        if ($character->get_warriors->get_how_many != 0 or
            $character->get_riders->get_how_many != 0) {
            $self->get_location->set_object(Midnight::Location::Object::NOTHING);
            return;
        }
    }

    if (($object == Midnight::Location::Object::WOLVES and
         $self->get_object == Midnight::Location::Object::WOLFSLAYER) or
        ($object == Midnight::Location::Object::DRAGONS and
         $self->get_object == Midnight::Location::Object::DRAGONSLAYER)) {
        $self->get_location->set_object(Midnight::Location::Object::NOTHING);
        return;
    }

    $self->maybe_lose;

    # Does it make sense to remove the nasties even if the character died?
    # (Original LoM limitation)
    $self->get_location->set_object(Midnight::Location::Object::NOTHING);
}

sub maybe_lose {
    my ($self) = @_;

    if ($self->is_on_horse) {
        $self->set_on_horse($self->get_game->random(2) == 0);
    }

    if (($self->get_energy / 2 - 0x40 + $life{ident $self}) < $self->get_game->random(256)) {
        $self->kill;
    }
}

sub clear_killed {
    my ($self) = @_;

    if ($self->is_alive) {
        undef $killed{ident $self};
    }
}

sub save {
}

sub load {
}

sub update {
}

use overload
    '""'    => \&get_title,
    '<=>'   => sub { ref $_[0] eq ref $_[1] ? $_[0]->get_id <=> $_[1]->get_id : -1 };


package Midnight::Character::Courage;

use warnings;
use strict;

use Class::Constant
    UTTERLY_AFRAID  => "utterly afraid",
    VERY_AFRAID     => "very afraid",
    AFRAID          => "afraid",
    QUITE_AFRAID    => "quite afraid",
    SLIGHTLY_AFRAID => "slightly afraid",
    BOLD            => "bold",
    VERY_BOLD       => "very bold",
    UTTERLY_BOLD    => "utterly bold";

1;
