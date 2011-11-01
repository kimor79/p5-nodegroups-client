use strict;

use Test::More tests => 4;

our $PACKAGE;

BEGIN {
	my $file = 't/config.pl';
	unless (my $return = do($file)) {
		BAIL_OUT("couldn't parse $file: $@") if($@);
		BAIL_OUT("couldn't do $file: $!") unless(defined($return));
		BAIL_OUT("couldn't run $file") unless($return);
	}

	use_ok($PACKAGE);
}

my $got;

my $obj = $PACKAGE->new();

$got = $obj->set_param('ssl_cafile', 'foobar');
is($got, 'foobar', 'ssl_cafile');

$got = $obj->set_param('user_agent', 'foobar');
is($got, 'foobar', 'user_agent');

$got = $obj->get_param('foobar', 'foobar');
is($got, undef, 'invalid param');
