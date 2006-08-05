package Midnight::Unit;

use warnings;
use strict;

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
    $condition{ident $self} = Midnight::Unit::Condition->by_ordinal($energy << 4);
}

sub increment_energy {
    my ($self, $increment) = @_;

    $self->set_energy($self->get_energy + $increment);
}

sub decrement_energy {
    my ($self, $decrement) = @_;

    $self->set_energy($self->get_energy - $decrement);
}


package Midnight::Unit::Condition;

use warnings;
use strict;

use Class::Constant
    UTTERLY_TIRED       => "utterly tired and cannot continue",
    VERY_TIRED          => "very tired",
    TIRED               => "tired",
    QUITE_TIRED         => "quite tired",
    SLIGHTLY_TIRED      => "slightly tired",
    INVIGORATED         => "invigorated",
    VERY_INVIGORATED    => "very invigorated",
    UTTERLY_INVIGORATED => "utterly invigorated";

1;
