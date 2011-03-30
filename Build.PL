use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
	module_name		=> 'Nodegroups::Client',
	license			=> 'perl',
	dist_author		=> 'Kimo Rosenbaum <kimor79@yahoo.com>',
	dist_version_from	=> 'lib/Nodegroups/Client.pm',
	build_requires => {
		'Test::Deep'	=> 0,
		'Test::More'	=> 0,
		'Test::Pod'	=> 0,
		'Test::Pod::Coverage'	=> 0,
		'Test::Spelling'	=> 0,
		'Test::Strict'	=> 0,
	},
	create_makefile_pl	=> 'traditional',
);

$builder->create_build_script();
