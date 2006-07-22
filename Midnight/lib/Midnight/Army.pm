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
    $casualties->{ident $self} += $number;
}

sub dawn {
}

sub increment_energy {
}

sub guard {
}

sub switch_sides {
}

sub save {
}

sub load {
}

use overload
    '""'    =>

package Midnight::Army::Type;

use warnings;
use strict;

h

use constant WARRIORS => bless do { \(my $x = "warriors") }, __PACKAGE__;
use constant RIDERS   => bless do { \(my $x = "riders") }, __PACKAGE__;

use overload
    '""'    => sub { return ${$_[0]} };

1;
