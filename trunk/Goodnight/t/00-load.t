#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Goodnight' );
}

diag( "Testing Goodnight $Goodnight::VERSION, Perl $], $^X" );
