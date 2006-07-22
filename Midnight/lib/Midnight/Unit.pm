package Midnight::Unit;

use warnings;
use strict;

use Class::Std;

use constant MAX_ENERGY => 127;

my %game                : ATTR ( :get<game> :init_arg<game> );
my %race                : ATTR ( :name<race> );
my %location            : ATTR ( :get<location> :set<location> );
my %energy              : ATTR ( :get<energy> );
my %condition           : ATTR ( :get<condition> );
my %enemy_killed        : ATTR ( :get<enemy_killed> :set<enemy_killed> );

sub START {
    my ($self, $ident, $args) = @_;

    $self->set_energy($args->{energy});
}

sub set_energy {
    my ($self, $energy) = @_;

    $energy = 0 if not $energy or $energy < 0;
    $energy = MAX_ENERGY if $energy > MAX_ENERGY;

    $energy{ident $self} = $energy;
    $condition{ident $self} = Midnight::Unit::Condition->get($energy);
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

my @conditions = (
    "utterly tired and cannot continue",
    "very tired",
    "tired",
    "quite tired",
    "slightly tired",
    "invigorated",
    "very invigorated",
    "utterly invigorated",
);

sub get {
    my ($class, $energy) = @_;

    $energy =>> 4;

    return bless \$energy, $class;
}

use overload
    '""'     => sub { return $conditions{${$_[0]}} },
    '0+'     => sub { return ${$_[0]} },
    '<=>'    => sub { 0+$_[0] <=> 0+$_[1] },
    fallback => 1;

1;
