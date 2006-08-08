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
my %guard       : ATTR
my %armies      : ATTR
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

}

1;
