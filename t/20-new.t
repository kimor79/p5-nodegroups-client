use strict;

use Test::More tests => 5;

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

new_ok($PACKAGE);
new_ok($PACKAGE => [ 'uri' => { 'ro' => '12345' } ]);
new_ok($PACKAGE => [ 'config_file' => 't/test_config.ini' ]);
new_ok($PACKAGE => [ 'config_file' => 't/test_config.ini',
	'user_agent' => 'foo' ]);
