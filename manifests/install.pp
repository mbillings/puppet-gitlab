# = Class: gitlab::install
#
# Install packages required for gitlab
#

class gitlab::install 
{
  include gitlab::params
  require gitlab::realizeusers

  package { "epel-release": ensure => installed }

  package { $gitlab::params::rpms: 
  	ensure  => installed,
  	require => Package["epel-release"]
  }

  package { $gitlab::params::gems: 
  	ensure   => installed,
  	provider => gem,
  	require  => [Package[$gitlab::params::rpms], Package["epel-release"]]
  }
}
