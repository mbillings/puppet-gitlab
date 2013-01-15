# = Class: gitlab::params
#
# Installs necessary packages for gitlab
# Modify variables as necessary for your install
#

class gitlab::params
{
  $auth_base      = 'dc=EDU'
  $auth_binddn    = 'CN=bigbro,CN=Users,DC=col,DC=missouri,DC=edu'
  $auth_enabled   = 'true'
  $auth_host      = 'ldap.missouri.edu'
  $auth_method    = 'ssl'
  $auth_pass      = '.b16Br0+'
  $auth_port      = '3269'
  $auth_uid       = 'sAMAccountName'
  $db_adapter     = 'mysql2'
  $db_encoding    = 'utf8'
  $db_name        = 'gitlabhq_production'
  $db_pass        = 'omgggg.pa$aw3#rd3D'
  $db_pool        = '5'
  $db_reconnect   = 'false'
  $db_user        = 'gitlab'
  $host           = 'mbtest.missouri.edu'
  $host_ip        = '128.206.0.153'
  $http_port      = '80'
  $mail           = 'linux@missouri.edu'
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
#  $easy_install=
#  [ 
#    "pip", 
#  ]

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
    "git",
    #"git-core",
    #"iconv-dev",
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
    #"python-pip",
    "python-setuptools",
    "readline",
    "readline-devel",
    "redis",
    "ruby",
    "ruby-devel",
    "rubygems",
    "${web_service}",
    "wget",
    "zlib",
    #"zlib1g-dev",
    "zlib-devel",
  ]
}
