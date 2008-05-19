package Goodnight::Doomguard;

use warnings;
use strict;

use base qw(Goodnight::Army);

use Goodnight::Doomguard::Orders;
use Goodnight::Location::Feature;
use Goodnight::Map::Direction;
use Goodnight::Race;

use Class::Std;

use constant MAX_MOVE_COUNT => 6;

my %orders              : ATTR( :get<orders> :init_arg<orders> );
my %target              : ATTR( :get<target> :init_arg<target> );
my %move_count          : ATTR( :get<move_count> :default(0) );
my %id                  : ATTR;

my $next_id = 1;

sub PREBUILD {
    my ($class, $args) = @_;

    my %new_args = (%{$args}, race => Goodnight::Race::FOUL);

    return \%new_args;
}

sub START {
    my ($self, $ident, $args) = @_;

    $id{$ident} = $next_id++;
}

sub set_location {
    if (@_ == 2) {
       my ($self, $location) = @_;

        if ($self->get_location) {
            $self->get_location->remove_army($self);
        }

        $self->SUPER::set_location($location);
        $self->get_location->add_army($self);
    }

    elsif (@_ == 3) {
        my ($self, $x, $y) = @_;

        my $location = $self->get_game->get_map->get_location($x, $y);
        $self->set_location($location);
    }
}

sub decrease_numbers {
    my ($self, $decrease) = @_;

    $self->SUPER::decrease_numbers($decrease);

    if ($self->get_how_many == 0) {
        $self->get_location->remove_army($self);
        $self->get_game->remove_doomguard($self);
    }
}

sub execute_move {
    my ($self) = @_;

    if ($self->get_location->is_special) {
        $self->stop_moving;
        return;
    }

    my $direction = Goodnight::Map::Direction::NORTH;
    for (0..7) {
        my $location = $self->get_game->get_map->get_looking_towards($self->get_location, $direction);
        if ($location->is_special) {
            $self->move_to($self->get_game->get_map->get_in_front($self->get_location, $direction));
            return;
        }
        $direction = $direction->turn_right;
    }

    if ($orders{ident $self} == Goodnight::Doomguard::Orders::FOLLOW) {
        $self->follow_character;
    }
    elsif ($orders{ident $self} == Goodnight::Doomguard::Orders::GOTO) {
        $self->follow_goto;
    }
    elsif ($orders{ident $self} == Goodnight::Doomguard::Orders::ROUTE) {
        $self->follow_route;
    }
    elsif ($orders{ident $self} == Goodnight::Doomguard::Orders::WANDER) {
        $self->wander;
    }
}

sub follow_character {
    my ($self) = @_;

    my $character = $target{ident $self};

    if (! $character->is_alive) {
        if ($self->get_game->LUXOR->is_alive) {
            $character = $self->get_game->LUXOR;
        }
        else {
            $character = $self->get_game->MORKIN;
        }
        $target{ident $self} = $character;
    }

    $self->move_towards($character->get_location);
}

sub follow_goto {
    my ($self) = @_;

    my $location = $target{ident $self};

    if ($location->is_special) {
        $self->move_towards($location);
    }
    else {
        $self->stop_moving;
    }
}

sub follow_route {
    my ($self) = @_;

    my $destination = $target{ident $self};

    if ($self->get_location == $destination) {
        if ($self->get_game->random(2) == 0) {
            $destination = $self->get_game->get_map->get_next_node_a($destination);
        }
        else {
            $destination = $self->get_game->get_map->get_next_node_b($destination);
        }
        $target{ident $self} = $destination;
    }

    $self->move_towards($destination);
}

sub wander {
    my ($self) = @_;

    my $location;
    while (1) {
        $location = $self->get_game->get_map->get_in_front($self->get_location,
                                                           Goodnight::Map::Direction->by_ordinal($self->get_game->random(8)));
        last if $location->get_feature != Goodnight::Location::Feature::FROZEN_WASTE;
    }

    $self->move_to($location);
}

sub move_towards {
    my ($self, $location) = @_;

    if ($self->get_location != $location) {
        my $direction = Goodnight::Map::calc_direction($self->get_location, $location);
        my $destination;

        for (0..7) {
            my $random = $self->get_game->get_random(4);
            if ($random < 2) {
                $destination = $self->get_game->get_map->get_in_front($self->get_location, $direction);
            }
            elsif ($random == 2) {
                $destination = $self->get_game->get_map->get_in_front($self->get_location, $direction->turn_left);
            }
            elsif ($random == 3) {
                $destination = $self->get_game->get_map->get_in_front($self->get_location, $direction->turn_right);
            }

            if ($destination->get_feature != Goodnight::Location::Feature::FOREST and
                $destination->get_feature != Goodnight::Location::Feature::MOUNTAIN and
                $destination->get_feature != Goodnight::Location::Feature::FROZEN_WASTE) {
                next;
            }
        }

        if ($destination->get_feature != Goodnight::Location::Feature::FROZEN_WASTE) {
            $self->move_to($destination);
        }
        else {
            $self->stop_moving;
        }
    }

    else {
        $self->stop_moving;
    }
}

sub stop_moving {
    my ($self) = @_;

    $move_count{ident $self} = MAX_MOVE_COUNT;
}

sub reset_move_count {
    my ($self) = @_;

    $move_count{ident $self} = 0;
}

sub move_to {
    my ($self, $location) = @_;

    if (@{$location->get_armies} > 0x1f) {
        $self->stop_moving;
        return;
    }

    my $cost;
    if ($location->get_feature == Goodnight::Location::Feature::FOREST or
        $location->get_feature == Goodnight::Location::Feature::MOUNTAIN) {
        $cost = 8;
    }
    else {
        $cost = 2;
    }

    if($self->get_type == Goodnight::Army::Type::RIDERS) {
        $cost /= 2;
    }

    $move_count{ident $self} += $cost;
    $self->set_location($location);
}

sub as_string {
    my ($self) = @_;

    return
        "#" . $id{ident $self} .
        " Doomguard (" . $self->SUPER::as_string .
        " " . $self->get_location->get_feature->get_at .
        " " . $self->get_location . "): " .
        $orders{ident $self} . " " .
        ($target{ident $self} ? $target{ident $self}->as_string : "");
}

use overload q{""} => \&as_string;

sub save {
}

sub load {
}

1;
