package Midnight;

use warnings;
use strict;

use Carp qw(croak);

BEGIN {
    croak "use'ing Midnight directly isn't supported yet.\n For now, try 'use Midnight::Game' instead\n";
}

1;
