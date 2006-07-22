#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Midnight' );
}

diag( "Testing Midnight $Midnight::VERSION, Perl $], $^X" );
