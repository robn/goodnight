package Midnight::Unit;

use warnings;
use strict;

use Midnight::Unit::Condition;

use Class::Std;

use constant MAX_ENERGY => 127;

my %game                : ATTR( :get<game> :init_arg<game> );
my %race                : ATTR( :name<race> );
my %location            : ATTR( :get<location> :set<location> );
my %energy              : ATTR( :get<energy> );
my %condition           : ATTR( :get<condition> );
my %enemy_killed        : ATTR( :get<enemy_killed> :set<enemy_killed> );

sub START {
    my ($self, $ident, $args) = @_;

    $self->set_energy($args->{energy});
}

sub set_energy {
    my ($self, $energy) = @_;

    $energy = 0 if not $energy or $energy < 0;
    $energy = MAX_ENERGY if $energy > MAX_ENERGY;

    $energy{ident $self} = $energy;
    $condition{ident $self} = Midnight::Unit::Condition->by_ordinal($energy >> 4);
}

sub increment_energy {
    my ($self, $increment) = @_;

    $self->set_energy($self->get_energy + $increment);
}

sub decrement_energy {
    my ($self, $decrement) = @_;

    $self->set_energy($self->get_energy - $decrement);
}

1;
