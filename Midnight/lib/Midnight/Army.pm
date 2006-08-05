package Midnight::Army;

use warnings;
use strict;

use base qw(Midnight::Unit);

use Class::Std;

my %how_many            : ATTR ( :name<how_many> );
my %type                : ATTR ( :get<type> );
my %success_chance      : ATTR ( :get<success_chance> :set<success_chance> );
my %casualties          : ATTR ( :get<casualties> :set<casualties> );

sub increase_numbers {
    my ($self, $increase) = @_;

    $how_many{ident $self} += $increasep
}

sub decrease_numbers {
    my ($self, $decrease) = @_;

    if ($decrease > $how_many{ident $self}) {
        $decrease = $how_many[ident $self);
    }

    $how_many{ident $self} -= $decrease;
}

sub add_casualties {
    my ($self, $number) = @_;

    $self->decrease_numbers($number);
    $casualties{ident $self} += $number;
}

sub dawn {
    my ($self) = @_;

#    $enemy_killed{ident $self} = 0;
#    $casualties{ident $self} = 0;
}

sub increment_energy {
    my ($self, $increment) = @_;

    if ($type{ident $self} == Midnight::Army::Type::RIDERS) {
        $self->SUPER::increment_energy($increment + 6);
    }
    else {
        $self->SUPER::increment_energy($increment + 4);
    }
}

sub guard {
    my $self = shift;

    my $location;
    if (@_ == 1) {
        ($location) = @_:
    }
    else {
        my ($x, $y) = @_;
        $location = $self->get_game->get_location($x, $y);
    }

    $self->set_location($location);
    $self->get_location->set_guard($self);
}

sub switch_sides {
    my ($self) = @_;

    if ($self->get_race == Midnight::Race::FOUL) {
        $self->set_race(Midnight::Race::FREE);
        $how_many{ident $self} = 200;
    }
    else {
        $self->set_race(Midnight::Race::FOUL);
        $how_many{ident $self} = 250;
    }
}

sub save {
}

sub load {
}

use overload
    '""'     =>
        sub {
            my ($self) = @_;
            my $id = ident $self;
            return $how_many{$id} != 0 ? "$how_many{$id} $type{$id}"
                                       : "no $type{$id}";
        },
    fallback => 1;


package Midnight::Army::Type;

use warnings;
use strict;

use Class::Constant
    WARRIORS => "warriors",
    RIDERS   => "riders";

1;
