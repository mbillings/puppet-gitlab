# = Class: gitlab::init
#
# Installs gitlab on {RHEL|CentOS|Fedora}-based x86_64 systems
#
class gitlab
(
  # Point name-specific variables
  $auth_base        = $gitlab::params::auth_base,
  $auth_binddn      = $gitlab::params::auth_binddn,
  $auth_enabled     = $gitlab::params::auth_enabled,
  $auth_host        = $gitlab::params::auth_host,
  $auth_method      = $gitlab::params::auth_method,
  $auth_pass        = $gitlab::params::auth_pass,
  $auth_port        = $gitlab::params::auth_port,
  $auth_uid         = $gitlab::params::auth_uid,
  $db_adapter       = $gitlab::params::db_adapter,
  $db_encoding      = $gitlab::params::db_encoding,
  $db_name          = $gitlab::params::db_name,
  $db_pass          = $gitlab::params::db_pass,
  $db_pool          = $gitlab::params::db_pool,
  $db_reconnect     = $gitlab::params::db_reconnect,
  $db_user          = $gitlab::params::db_user,
  $gitlab_init_url  = $gitlab::params::gitlab_init_url,
  $gitlabhq_branch  = $gitlab::params::gitlabhq_branch,
  $gitolite_branch  = $gitlab::params::gitolite_branch,
  $gems             = $gitlab::params::gems,
  $host             = $gitlab::params::host,
  $host_ip          = $gitlab::params::host_ip,
  $http_port        = $gitlab::params::http_port,
  $mail             = $gitlab::params::mail,
  $project_limit    = $gitlab::params::project_limit,
  $proxy_port       = $gitlab::params::proxy_port,
  $rpms             = $gitlab::params::rpms,
  $ruby_version     = $gitlab::params::ruby_version,
  $ssl_port         = $gitlab::params::ssl_port,
  $web_config       = $gitlab::params::web_config,
  $web_doc_root     = $gitlab::params::web_doc_root,
  $web_service      = $gitlab::params::web_service,

) inherits gitlab::params {
  	include gitlab::install
  	include gitlab::config
  	Class['gitlab::install'] -> Class['gitlab::config']
  	#include gitlab::stages
  	#include gitlab::realizeusers

		#class { 'gitlab::install': 
		#	stage => install
		#}
		
		#Class['gitlab::realizeusers']
		#class { 'gitlab::service': }~>
    #class { 'gitlab::config':  }
  }
