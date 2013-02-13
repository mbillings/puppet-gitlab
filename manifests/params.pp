# = Class: gitlab::params
#
# Installs necessary packages for gitlab
# Modify variables as necessary for your install
#

class gitlab::params
{
  $auth_base        = 'dc=COM'
  $auth_binddn      = 'CN=user,CN=Users,DC=host,DC=com'
  $auth_enabled     = 'true'
  $auth_host        = 'ldap.host.com'
  $auth_method      = 'ssl'
  $auth_pass        = '.OMGWTFBBQ'
  $auth_port        = '3269'
  $auth_uid         = 'sAMAccountName'
  $db_adapter       = 'mysql2'
  $db_encoding      = 'utf8'
  $db_name          = 'gitlabhq_production'
  $db_pass          = 'omg'
  $db_pool          = '5'
  $db_reconnect     = 'false'
  $db_user          = 'gitlab'
  $gitlab_init_url  = 'https://raw.github.com/gitlabhq/gitlab-recipes/4-1-stable/init.d/gitlab'
  $gitlabhq_branch  = '4-1-stable'
  $gitolite_branch  = 'gl-v320'
  $host             = 'gitlab.host.com'
  $host_ip          = '10.10.10.10'
  $http_port        = '80'
  $mail             = 'linux@host.com'
  $project_limit    = '20'
  $proxy_port       = '8080'
  $ruby_version     = '1.9.3-p327'
  $ssl_port         = '443'
  # Web service: comment/uncomment as desired, only one can be defined at a time
  $web_doc_root     = '/var/www/html/gitlab'
  $web_service      = 'httpd'
  #$web_service    = 'nginx'

  # Nginx default config file must be overwritten for unicorn compatibility :(
  # Apache can use a vhost
#  $web_config = "${web_service}" ?
#  {
#    httpd => '/etc/httpd/conf.d/gitlab.conf',
#    nginx => '/etc/nginx/conf.d/gitlab.conf',
#    #nginx => '/etc/nginx/nginx.conf',
#  }

  #$gems=
  #[ 
  #  "bundler", 
  #  "charlock_holmes", 
  #  "grit",
#	"passenger",
#    "rails",
#    "rake",
#    "rb-inotify",
#    "unicorn",
#  ]

  #$pips=
  #[
  #  "pygments",
  #]

  # Name-specific vairables
  $server_name      = 'servernamehere' 

  $rpms=
  [ 
    "apr-devel",
    "apr-util-devel",
    "autoconf",
    "automake",
    "bison",
    "byacc",
    "bzip2",
    "curl",
    "gcc",
    "gcc-c++",
    "gdbm-devel",
    "git",
    #"git-core",
    #"iconv-dev",
    "httpd-devel",
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
    "python-pygments",
    "readline",
    "readline-devel",
    "redis",
    "rubygems",
    "tcl-devel",
    "${web_service}",
    "wget",
    "zlib",
    "zlib-devel",
  ]
}
