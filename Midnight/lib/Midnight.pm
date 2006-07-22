package Midnight;

use warnings;
use strict;

use Class::Std;

my %map                 : ATTR ( :get<map> );
my %characters          : ATTR;
my %armies              : ATTR;
my %doomguard           : ATTR;
my %day                 : ATTR;
my %moonring_controlled : ATTR;
my %ice_crown_destroyed : ATTR;
my %game_over           : ATTR;
my %status              : ATTR;
my %battles             : ATTR;
my %doomdarks_citadel   : ATTR;

sub BUILD {
    my ($self, $ident, $args) = @_;

    $map{$ident} = Midnight::Map->new({ game => $self });

    $day{$ident} = 0;
    $moonring_controlled{$ident} = 1;
}

1;
