package Nodegroups::Client;

=head1 NAME

Nodegroups::Client - nodegroups client module

=head1 SYNOPSIS

  use Nodegroups::Client;
  my $ng = new Nodegroups::Client();
  my $nodes = $ng->get_nodes_from_nodegroup('@foobar');

=head1 DESCRIPTION

This module provides common functions to query various
nodegroup APIs.

Unless otherwise specified, methods return undef on failure.
The error string can be retrieved via the object's errstr() method.

=cut

use strict;
use warnings;

##
## Modules
##

use Config::Simple;
use JSON::DWIW;
use LWP::UserAgent;

##
## Variables
##

BEGIN {
	$Nodegroups::Client::errstr = '';
}

my $VERSION = '0.01';

=head1 OPTIONS

=over 4

=item config_file

Use this to get other options from specified configuration file.
Options passed to new() will override options passed via this configuration
file.

=item uri

Hash of uri's to use.
  'ro' => 'http://localhost/api/v1',
  'rw' => 'http://localhost/api/v1',

=item user_agent

Sets the User Agent request header. Default is Nodegroups::Client/$version

=back

=cut

my $DEFAULT_CONFIG_FILE = '/usr/local/etc/nodegroups_client/config.ini';
my $JSON;
my %PARAMS = (
	'uri' => {
		'ro' => 'http://localhost/api/v1',
		'rw' => 'http://localhost/api/v1',
	},
	'user_agent' => __PACKAGE__ . '/' . $VERSION,
);

##
## Subroutines
##

=head1 METHODS

=over 4

=cut

#
# Public
#

sub new {

=item new(%options)

Create a new object. See OPTIONS for available options. If
/usr/local/etc/nodegroups_client/config.ini exists, new() will parse that file
for default options. Options passed to new() will override options passed via
a configuration file.

The LWP::UserAgent object can be accessed directly via this module's object,
e.g.: $ng->{'ua'}

On failure, inspect $Nodegroups::Client::errstr.

=cut

	my $proto = shift;
	my $options = {@_};
	my $class = ref($proto) || $proto;
	my $self = {};

	if(-f $DEFAULT_CONFIG_FILE) {
		_parse_config($DEFAULT_CONFIG_FILE);
	}

	if(defined($options) && ref($options) eq 'HASH') {
		if(exists($options->{'config_file'})) {
			_parse_config($options->{'config_file'}) ||
				return undef;
		}

		delete($options->{'config_file'});

		if(exists($options->{'uri'}) &&
				ref($options->{'uri'}) eq 'HASH') {
			if(exists($options->{'uri'}{'ro'})) {
				$PARAMS{'uri'}{'ro'} = $options->{'uri'}{'ro'};
			}

			if(exists($options->{'uri'}{'rw'})) {
				$PARAMS{'uri'}{'rw'} = $options->{'uri'}{'rw'};
			}
		}

		if(exists($options->{'user_agent'})) {
			$PARAMS{'user_agent'} = $options->{'user_agent'};
		}
	}

	$JSON = JSON::DWIW->new();
	$self->{'ua'} = LWP::UserAgent->new('agent' => $PARAMS{'user_agent'});

	return bless($self, $class);
}

sub errstr {

=item errstr

Return the error (if any) from the most recent API call.

=cut

	return $Nodegroups::Client::errstr;
}

sub api_get {

=item api_get($type, $path, $params)

Generic method to GET from a nodegroups API.

Returns a ref to data

=cut

	my ($self, $type, $path, $params) = @_;

	$Nodegroups::Client::errstr = '';

	my $url;
	# TODO: build $url

	my $response = $self->{'ua'}->get($url);

	if(!$response->is_success()) {
		return _errstr($response->status_line());
	}

	my ($json, $error) = $JSON->from_json($response->decoded_content());
	if($error) {
		return _errstr($error);
	}

	if(defined($json->{'status'})) {
		if($json->{'status'} eq '200') {
			return $json;
		}

		return _errstr($json->{'message'});
	}

	return _errstr($response->decoded_content());
}

sub api_post {

=item api_post($type, $path, $params)

Generic method to POST to a nodegroups API.

Returns a ref of data.

=cut

	my ($self, $type, $path, $params) = @_;

	$Nodegroups::Client::errstr = '';

	my $url;
	# TODO: build $url

	my $response = $self->{'ua'}->post($url, $params);

	if(!$response->is_success()) {
		return _errstr($response->status_line());
	}

	my ($json, $error) = $JSON->from_json($response->decoded_content());
	if($error) {
		return _errstr($error);
	}

	if(defined($json->{'status'})) {
		if($json->{'status'} eq '200') {
			return $json;
		}

		return _errstr($json->{'message'});
	}

	return _errstr($response->decoded_content());
}

sub get_nodegroups_from_node {

=item get_nodegroups_from_node($node, [$app])

Get the nodegroups a node is a member of, with an optional sorting by 'app'

Returns an array of nodegroups

=cut

	my ($self, $node, $app) = @_;

	my $opts = {
		'node' => $node,
	};

	if($app) {
		$opts->{'app'} = $app;
		$opts->{'sortDir'} = 'asc';
		$opts->{'sortField'} = 'order';
	}

	my $data = $self->api_get('ro', 'r/list_nodegroups.php', $opts);

	if(defined($data) && defined($data->{'records'})) {
		my @nodegroups;
		foreach my $record (@{$data->{'records'}}) {
			push(@nodegroups, $record->{'nodegroup'});
		}

		return @nodegroups;
	}

	return undef;
}

sub get_nodes_from_expression {

=item get_nodes_from_expression($expression)

Parse an expression and return an array of members

=cut

	my ($self, $expr) = @_;

	my $data = $self->api_post('ro', 'r/list_nodes.php', {
		'expression' => $expr,
	});

	if(defined($data) && defined($data->{'records'})) {
		my @nodes;
		foreach my $record (@{$data->{'records'}}) {
			push(@nodes, $record->{'node'});
		}

		return @nodes;
	}

	return undef;
}

sub get_nodes_from_nodegroup {

=item get_nodes_from_nodegroup($nodegroup)

Return an array of members from given nodegroup.

=cut

	my ($self, $nodegroup) = @_;

	my $data = $self->api_get('ro', 'r/list_nodes.php', {
		'nodegroup' => $nodegroup,
	});

	if(defined($data) && defined($data->{'records'})) {
		my @nodes;
		foreach my $record (@{$data->{'records'}}) {
			push(@nodes, $record->{'node'});
		}

		return @nodes;
	}

	return undef;
}

sub get_param {

=item get_param($param)

Return the value of given parameter.

=cut

	my ($self, $param, $sub) = @_;
	my $message = 'Unknown parameter: ' . $param;

	if(exists($PARAMS{$param})) {
		if(defined($sub)) {
			if(exists($PARAMS{$param}{$sub})) {
				return $PARAMS{$param}{$sub};
			}

			$message .= ' - ' . $sub;
		} else {
			return $PARAMS{$param};
		}
	}

	return _errstr($message);
}

sub set_param {

=item set_param($param, $value)

Modify a parameter

Returns the new value.

=cut

	my ($self, $param, $value) = @_;

	if(!exists($PARAMS{$param})) {
		return _errstr('Unknown param: ' . $param);
	}

	$PARAMS{$param} = $value;

	return $self->get_param($param);
}

#
# Private
#

sub _errstr {
# Purpose: set error string and return undef
# Inputs: Error message
# Returns: undef

	my $error = shift;

	$Nodegroups::Client::errstr = $error;
	return undef;
}

sub _parse_config {
# Purpose: Parse ini-style config for various options
# eg, which uri, user_agent, etc

	my $file = shift;

	my $config = Config::Simple->new($file);

	if(!defined($config)) {
		return _errstr(Config::Simple->error());
	}

	my $uri_ro = $config->param('uri.ro');
	if(defined($uri_ro)) {
		$PARAMS{'uri'}{'ro'} = $uri_ro;
	}

	my $uri_rw = $config->param('uri.rw');
	if(defined($uri_rw)) {
		$PARAMS{'uri'}{'rw'} = $uri_rw;
	}

	my $user_agent = $config->param('perl.user_agent');
	if(defined($user_agent)) {
		$PARAMS{'user_agent'} = $user_agent;
	}

	return 1;
}

##
## Do not edit below this line
##

=back
=cut
1;
