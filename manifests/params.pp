# = Class: gitlab::params
#
# Installs necessary packages for gitlab
# Modify variables as necessary for your install
#

class gitlab::params
{
  $auth_base      = 'dc=COM'
  $auth_binddn    = 'CN=user,CN=Users,DC=host,DC=com'
  $auth_enabled   = 'true'
  $auth_host      = 'ldap.host.com'
  $auth_method    = 'ssl'
  $auth_pass      = 'OMGWTFBBQ'
  $auth_port      = '3269'
  $auth_uid       = 'sAMAccountName'
  $db_adapter     = 'mysql2'
  $db_encoding    = 'utf8'
  $db_name        = 'gitlabhq_production'
  $db_pass        = 'omgggg.pa$aw3#rd3D'
  $db_pool        = '5'
  $db_reconnect   = 'false'
  $db_user        = 'gitlab'
  $host           = 'gitlab.host.com'
  $host_ip        = '10.10.10.10'
  $http_port      = '80'
  $mail           = 'linux@host.com'
  $project_limit  = '20'
  $proxy_port     = '8080'
  $ssl_port       = '443'
  # Web service: comment/uncomment as desired, only one can be defined at a time
  $web_doc_root   = '/var/www/html/gitlab'
  #$web_service    = 'httpd'
  $web_service    = 'nginx'

  # Nginx default config file must be overwritten for unicorn compatibility :(
  # Apache can use a vhost
#  $web_config = "${web_service}" ?
#  {
#    httpd => '/etc/httpd/conf.d/gitlab.conf',
#    nginx => '/etc/nginx/conf.d/gitlab.conf',
#    #nginx => '/etc/nginx/nginx.conf',
#  }

  $gems=
  [ 
    "bundler", 
    "charlock_holmes", 
    "unicorn",
  ]

  $pips=
  [
    "pygments",
  ]

  # Name-specific vairables
  $server_name      = 'servernamehere' 

  $rpms=
  [ 
    "autoconf",
    "automake",
    "bison",
    "bzip2",
    "curl",
    "gcc",
    "gcc-c++",
    "git-core",
    "iconv-dev",
    "libcurl",
    "libcurl-devel",
    "libffi-devel",
    "libicu",
    "libicu-devel",
    "libtool",
    "libxml2-devel",
    "libxslt-devel",
    "libyaml",
    "libyaml-devel",
    "make",
    "mod_ssl",
    "mysql",
    "mysql-devel",
    "mysql-libs",
    "mysql-server",
    "openssl",
    "openssl-devel",
    "patch",
    "postfix",
    "python-devel",
    "python-pip",
    "readline",
    "readline-devel",
    "redis",
    "rubygems",
    "${web_service}",
    "wget",
    "zlib",
    "zlib1g-dev",
    "zlib-devel",
  ]
}
