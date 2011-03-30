use strict;

use Test::More tests => 3;
use Test::Pod;
use Test::Pod::Coverage;
use Test::Spelling;

add_stopwords(
	'nodegroup',
	'nodegroups',
);

our $FILE;
our $PACKAGE;

my $file = 't/config.pl';
unless (my $return = do($file)) {
	BAIL_OUT("couldn't parse $file: $@") if($@);
	BAIL_OUT("couldn't do $file: $!") unless(defined($return));
	BAIL_OUT("couldn't run $file") unless($return);
}

pod_coverage_ok($PACKAGE);
pod_file_ok($FILE);

SKIP: {
	my $spell = `which spell`;

	skip "'spell' command not found", 1 if($? ne 0);

	pod_file_spelling_ok($FILE);
}
