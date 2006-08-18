package Midnight::Time;

use warnings;
use strict;

use Class::Std;

use constant DAWN  => 16;
use constant NIGHT => 0;

my %time    : ATTR( :get<time> );

sub START {
    my ($self) = @_;

    $self->dawn;
}

sub dawn {
    my ($self) = @_;

    $time{ident $self} = DAWN;
}

sub night {
    my ($self) = @_;

    $time{ident $self} = NIGHT;
}

sub increase {
    my ($self, $increment) = @_;

    $time{ident $self} += $increment;
    $time{ident $self} = DAWN if $time{ident $self} > DAWN;
}

sub decrease {
    my ($self, $decrement) = @_;

    $time{ident $self} -= $decrement;
    $time{ident $self} = NIGHT if $time{ident $self} < NIGHT;
}

sub is_dawn {
    my ($self) = @_;

    return $time{ident $self} == DAWN;
}

sub is_night {
    my ($self) = @_;

    return $time{ident $self} == NIGHT;
}

sub as_string {
    my ($self) = @_;

    if ($time{ident $self} == DAWN) {
        return "It is dawn.";
    }
    if ($time{ident $self} == NIGHT) {
        return "It is night.";
    }

    my $lt = "";
    if ($time{ident $self} % 2 == 1) {
        $lt = "Less than ";
    }

    return
        $lt .
        int($time{ident $self} / 2 + 1) .
        " hour" . (($time{ident $self} < 3) ? "" : "s") . " " .
        "of the day remain.";
};

use overload q{""} => \&as_string;

1;
