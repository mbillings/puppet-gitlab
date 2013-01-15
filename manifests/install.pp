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

  # epel installs as pip-python, which puppet doesn't recognize when looking for 'pip'
  # easyinstall installs as pip-<verison>, which puppet doesn't recognize when looking for 'pip'
  # thus...we symlink >__<
  file { "/usr/bin/pip": ensure => "symlink", target => "/usr/bin/pip-python" }

#  package { $gitlab::params::easy_install:
#  	ensure   => installed,
#  	provider => easy_install,
#  	require  => Package["epel-release"]
#  }

  package { $gitlab::params::pips:
  	ensure   => installed,
  	provider => pip,
  	require  => Package["epel-release"]
  }

  package { $gitlab::params::gems: 
  	ensure   => installed,
  	provider => gem,
  	require  => Package["epel-release"]
  }
}
