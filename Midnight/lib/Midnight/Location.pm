package Midnight::Location;

use warnings;
use strict;

use Class::Std;

my %game        : ATTR( :get<game> :init_arg<game>
my %x           : ATTR( :get<x> :init_arg<x>
my %y           : ATTR( :get<y> :init_arg<y>
my %feature     : ATTR( :get<feature> :init_arg<feature>
my %object      : ATTR( :get<object> :init_arg<object>
my %area        : ATTR( :get<domain> :init_arg<area>
my %domain      : ATTR( :get<domain_flag> :init_arg<domain>
my %special     : ATTR( :init_arg<special>
my %guard       : ATTR( :get<guard>
my %armies      : ATTR( :get<armies>
my %characters  : ATTR
my %ice_fear    : ATTR

sub get_coordinates {
    my ($self) = @_;

    return " [" . $x{ident $self} . ", " . $y{ident $self} . "]";
}

sub as_string {
    my ($self) = @_;

    my $feature = $feature{ident $self};
    my $area = $area{ident $self};

    if ($domain{ident $self}) {
        my $article;
        if ($feature == Midnight::Location::Feature::MOUNTAIN or
            $feature == Midnight::Location::Feature::DOWNS or
            $feature == Midnight::Location::Feature::FROZEN_WASTE or
            $feature == Midnight::Location::Feature::ARMY or
            $feature == Midnight::Location::Feature::PLAINS) {
            $article = " ";
        }
        else {
            $article = "a ";
        }

        return "$article$feature in the Domain of $area";
    }

    if ($feature == Midnight::Location::Feature::HENGE) {
        return $area . "henge";
    }

    if ($feature == Midnight::Location::Feature::LAKE) {
        return "Lake $area";
    }

    if ($feature == Midnight::Location::Feature::FROZEN_WASTE) {
        return "the Frozen Wastes";
    }

    my $feature_string = "$feature";
    $feature_string =~ s/^[a-z]/uc($1)/e;
    return "the $feature_string of $area";
}

use overload q{""} => \&as_string;

sub get_map {
    my ($self) = @_;

    return $game{ident $self}->get_map;
}

sub is_special {
    my ($self) = @_;

    return $special{ident $self};
}

sub set_guard {
    my ($self, $guard) = @_;

    if ($feature{ident $self} == Midnight::Location::Feature::KEEP or
        $feature{ident $self} == Midnight::Location::Feature::CITADEL) {
        $guard{ident $self} = $guard;
    }
}

sub add_army {
    my ($self, $army) = @_;

    push @{$army{ident $self}}, $army;

    if ($feature{ident $self} == Midnight::Location::Feature::PLAINS) {
        $feature{ident $self} = Midnight::Location::Feature::ARMY;
    }
}

sub remove_army {
    my ($self, $army) = @_;

    my $armies = $armies{ident $self};

    my $index = 0;
    while ($armies->[$index] != $army) {
        $index++;
    }

    return if $index == @{$armies};

    splice @{$armies}, $index, 1;

    if ($feature{ident $self} == Midnight::Location::Feature::ARMY and @{$armies} == 0) {
        $feature{ident $self} = Midnight::Location::Feature::PLAINS;
    }
}

1;
