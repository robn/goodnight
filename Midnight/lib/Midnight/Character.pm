package Midnight::Character;

use warnings;
use strict;

use base qw(Midnight::Unit);

use Class::Std;

my %id                  : ATTR ( :get<id> );
my %name                : ATTR ( :get<name> );
my %title               : ATTR ( :get<title> );
my %life                : ATTR ( :get<life> );
my %strength            : ATTR ( :get<strength> :set<strength> );
my %courage_base        : ATTR ( :get<courage_base> );
my %courage             : ATTR;
my %direction           : ATTR ( :get<direction> :set<direction> );
my %object              : ATTR ( :get<object> :set<object> );
my %found               : ATTR;
my %warriors            : ATTR ( :get<warriors> );
my %riders              : ATTR ( :get<riders> );
my %time                : ATTR ( :get<time> );
my %killed              : ATTR ( :get<killed> :set<killed> );
my %battle              : ATTR ( :get<battle> :set<battle> );
my %on_horse            : ATTR ( :set<on_horse> );
my %recruiting_key      : ATTR ( :get<recruiting_key> );
my %recruited_by_key    : ATTR ( :get<recruited_by_key> );
my %recruited           : ATTR ( :set<recruited> );
my %hidden              : ATTR ( :set<hidden> );

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
    $courage{ident $self} = Midnight::Character::Courage->get($fear / 8);
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
    
}

sub can_leave {
}

sub walk_forward {
}

sub can_recruit {
}

sub recruit {
}

sub is_recruited {
}

sub can_recruit_men {
}

sub recruit_men {
}

sub can_stand_on_guard {
}

sub stand_on_guard {
}

sub is_on_horse {
}

sub can_attack {
}

sub describe_battle {
}

sub increment_energy {
}

sub dawn {
}

sub clear_found {
}

sub seek {
}

sub drop_object {
}

sub can_fight {
}

sub fight {
}

sub maybe_lose {
}

sub clear_killed {
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

my @descriptions = (
    "utterly afraid",
    "very afraid",
    "afraid",
    "quite afraid",
    "slightly afraid",
    "bold",
    "very bold",
    "utterly bold",
);

sub get {
    my ($class, $index) = @_;

    return bless \$index, $class;
}

use overload
    '""'     => sub { return $descriptions{${$_[0]}} },
    '0+'     => sub { return ${$_[0]} },
    '<=>'    => sub { 0+$_[0] <=> 0+$_[1] },
    fallback => 1;

1;
