package Goodnight;

use warnings;
use strict;

use Carp qw(croak);

our $VERSION = "0.01";

BEGIN {
    croak "use'ing Goodnight directly isn't supported yet.\n For now, try 'use Goodnight::Game' instead\n";
}

1;
