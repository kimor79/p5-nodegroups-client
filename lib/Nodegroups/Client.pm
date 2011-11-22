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
use URI::Escape;

##
## Variables
##

BEGIN {
	$Nodegroups::Client::errstr = '';
}

my $VERSION = '0.05';

=head1 OPTIONS

=over 4

=item config_file

Use this to get other options from specified configuration file.
Options passed to new() will override options passed via this configuration
file.

=item ssl_cafile

The path to a file containing Certificate Authority certificates.

=item ssl_capath

The path to a directory containing files containing Certificate Authority
certificates.

=item ssl_verify_hostname

When TRUE LWP will for secure protocol schemes ensure it connects to servers
that have a valid certificate matching the expected hostname.

=item uri

Hash of uri's to use.
  'ro' => 'http://localhost/api',
  'rw' => 'http://localhost/api',

=item user_agent

Sets the User Agent request header. Default is Nodegroups::Client/$version

=back

=cut

my $DEFAULT_CONFIG_FILE = '/usr/local/etc/nodegroups_client/config.ini';
my $JSON;
my %PARAMS = (
	'ssl_cafile' => '',
	'ssl_capath' => '',
	'ssl_verify_hostname' => '',
	'uri' => {
		'ro' => 'http://localhost/api',
		'rw' => 'http://localhost/api',
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

		if(exists($options->{'ssl_cafile'})) {
			$PARAMS{'ssl_cafile'} = $options->{'ssl_cafile'};
		}

		if(exists($options->{'ssl_capath'})) {
			$PARAMS{'ssl_capath'} = $options->{'ssl_capath'};
		}

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

		if(exists($options->{'ssl_verify_hostname'})) {
			$PARAMS{'ssl_verify_hostname'} =
				$options->{'ssl_verify_hostname'};
		}
	}

	$JSON = JSON::DWIW->new();
	$self->{'ua'} = LWP::UserAgent->new('agent' => $PARAMS{'user_agent'});

	eval {
		if(exists($PARAMS{'ssl_cafile'})) {
			$self->{'ua'}->ssl_opts('SSL_ca_file' =>
				$PARAMS{'ssl_cafile'});
		}

		if(exists($PARAMS{'ssl_capath'})) {
			$self->{'ua'}->ssl_opts('SSL_ca_path' =>
				$PARAMS{'ssl_capath'});
		}

		if(exists($PARAMS{'ssl_verify_hostname'})) {
			$self->{'ua'}->ssl_opts('verify_hostname' =>
				$PARAMS{'ssl_verify_hostname'});
		}
	};

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
	my @query;
	$path =~ s|^/||;

	$Nodegroups::Client::errstr = '';

	my $url = $self->get_param('uri', $type);
	$url =~ s|/$||;
	$url .= '/' . $path;

	if(defined($params)) {
		while(my ($key, $value) = each(%{$params})) {
			push(@query, sprintf("%s=%s", $key,
				uri_escape_utf8($value)));
		}
	}

	push(@query, 'outputFormat=json');
	$url .= '?' . join('&', @query);

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

=item api_post($type, $path, $params, $get)

Generic method to POST to a nodegroups API.

Returns a ref of data.

=cut

	my ($self, $type, $path, $params, $get) = @_;
	my @query;
	$path =~ s|^/||;

	$Nodegroups::Client::errstr = '';

	my $url = $self->get_param('uri', $type);
	$url =~ s|/$||;
	$url .= '/' . $path;

	if(defined($get)) {
		while(my ($key, $value) = each(%{$get})) {
			push(@query, sprintf("%s=%s", $key,
				uri_escape_utf8($value)));
		}
	}

	push(@query, 'outputFormat=json');
	$url .= '?' . join('&', @query);

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

Returns an array ref of nodegroups

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

	my $data = $self->api_get('ro', 'v1/r/list_nodegroups_from_nodes.php',
		$opts);

	if(defined($data) && defined($data->{'records'})) {
		my @nodegroups;
		foreach my $record (@{$data->{'records'}}) {
			push(@nodegroups, $record->{'nodegroup'});
		}

		return \@nodegroups;
	}

	return undef;
}

sub get_nodes_from_expression {

=item get_nodes_from_expression($expression)

Parse an expression and return an array ref of members

=cut

	my ($self, $expr) = @_;

	my $data = $self->api_post('ro', 'v1/r/list_nodes.php', {
		'expression' => $expr,
	});

	if(defined($data) && defined($data->{'records'})) {
		my @nodes;
		foreach my $record (@{$data->{'records'}}) {
			push(@nodes, $record->{'node'});
		}

		return \@nodes;
	}

	return undef;
}

sub get_nodes_from_nodegroup {

=item get_nodes_from_nodegroup($nodegroup)

Return an array ref of members from given nodegroup.

=cut

	my ($self, $nodegroup) = @_;

	my $data = $self->api_get('ro', 'v1/r/list_nodes.php', {
		'nodegroup' => $nodegroup,
	});

	if(defined($data) && defined($data->{'records'})) {
		my @nodes;
		foreach my $record (@{$data->{'records'}}) {
			push(@nodes, $record->{'node'});
		}

		return \@nodes;
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

	my $ssl_cafile = $config->param('perl.ssl_cafile');
	if(defined($ssl_cafile)) {
		$PARAMS{'ssl_cafile'} = $ssl_cafile;
	}

	my $ssl_capath = $config->param('perl.ssl_capath');
	if(defined($ssl_capath)) {
		$PARAMS{'ssl_capath'} = $ssl_capath;
	}

	my $ssl_hostname = $config->param('perl.ssl_verify_hostname');
	if(defined($ssl_hostname)) {
		$PARAMS{'ssl_verify_hostname'} = $ssl_hostname;
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
