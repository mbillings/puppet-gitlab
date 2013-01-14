# = Class: gitlab::config
#
# Configures and "installs" gitlab, if you want to call it an install. Order of operations is from top to bottom, insert new functions into list at the bottom
#

class gitlab::config
{
  # EPEL rpm provides more options than the yumrepo type, downside is that the mirrors may change
  #exec { "Create EPEL repo":
  #       command => "/usr/bin/wget -q -O - wget http://ftp.osuosl.org/pub/fedora-epel/6/x86_64/epel-release-6-7.noarch.rpm | /usr/bin/yum localinstall -y",
  #       creates => "/etc/yum.repos.d/epel.repo",
  #     }

  # Ensure redis is started
  service { "redis":
            ensure     => running,
            enable     => true,
            hasstatus  => true,
            hasrestart => true,
            alias      => 'redis',
            subscribe  => Package['redis'],
          }

  # Ensure mysql is started
  service { "mysqld":
            ensure     => running,
            enable     => true,
            hasstatus  => true,
            hasrestart => true,
            alias      => 'mysql',
            subscribe  => Package['mysql'],
          }


  # parameterize the RVM version for installation
  exec { "Install RVM":
         command => "curl -L https://get.rvm.io | bash -s stable && rvm install 1.9.3 && rvm use 1.9.3 --default && rvm user gemsets",
         path    => "/bin/:/usr/bin/:/usr/local/rvm/bin/",
         onlyif  => "test `rvm -v 2</dev/null | wc -l` -eq 0",
       }

  # If the gitlab database does not exist yet:
  #  1. Create gitlab database
  #  2. Grant access to gitlab@localhost
  #  3. Grant privileges to gitlab@localhost
  #  4. Apply!
  exec { "Create database and grant privileges":
         command => "mysql -u root -e \"CREATE DATABASE IF NOT EXISTS '${gitlab::db_name}' DEFAULT CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci'; CREATE USER 'gitlab'@'localhost' IDENTIFIED BY '${gitlab::db_pass}'; GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER ON '${gitlab::db_name}' TO 'gitlab'@'localhost'; FLUSH PRIVILEGES;\"",
         path    => "/bin/:/usr/bin/:/usr/local/bin/",
         onlyif  => "test `mysql -u root -e \"show databases;\" 2>/dev/null | grep '${gitlab::db_name}' | wc -l` -eq 0",
       }

  exec { "SSH keygen for gitlab and copy gitlab pub key to git":
         user    => "git",
         command => "ssh-keygen -q -N '' -t rsa -f /home/gitlab/.ssh/id_rsa && cp /home/gitlab/.ssh/id_rsa.pub /home/git/gitlab.pub",
         path    => "/bin/:/usr/bin/:/usr/local/bin/",
         creates => ["/home/gitlab/.ssh/id_rsa", "/home/git/gitlab.pub"]
       }

  exec { "git clone gitolite":
         user    => "git",
         command => "/usr/bin/git clone -b gl-v304 https://github.com/gitlabhq/gitolite.git /home/git/gitolite",
         creates => "/home/git/gitolite",
       }

  exec { "Export /home/git/bin to PATH":
         command => "PATH=/home/git/bin:\$PATH && echo -e \"PATH=\$PATH:/home/git/bin\nexport PATH\" >> /home/git/.profile",
         path    => "/bin/:/usr/bin/:/usr/local/bin/",
         onlyif  => "test `grep '/home/git/bin' /home/git/.profile | wc -l` -ne 0";
       }

  exec { "Install gitolite":
         user    => "git",
         command => "/home/git/gitolite/install -ln /home/git/bin",
         creates => "/home/git/bin/gitolite";
       }

  file { "/home/git":
         path    => "/home/git",
         recurse => "true",
         owner   => "git",
         group   => "git",
         mode    => "755";
       }

  exec { "Setup gitolite":
         user    => "git",
         command => "gitolite setup -pk /home/git/gitlab.pub",
         path    => "/home/git/bin",
         onlyif  => "test `gitolite list-users | grep gitlab | wc -l` -eq 0",
       }

  exec { "Clone gitlab":
         user    => "gitlab",
         command => "/usr/bin/git clone -b stable https://github.com/gitlabhq/gitlabhq.git /home/gitlab/gitlab",
         creates => "/home/gitlab/gitlab",
       }

  file { "/home/git/.gitolite/hooks/common/post-receive":
         owner   => "git", group => "git", mode => "0750",
         ensure  => "present",
         content => template("gitlab/post-receive.erb"),
       }

  file { "/home/gitlab/gitlab/config/gitlab.yml":
         owner   => "gitlab", group => "gitlab", mode => "0750",
         ensure  => "present",
         content => template("gitlab/gitlab.yml.erb"),
       } 

  file { "/home/gitlab/gitlab/config/database.yml":
         owner => "gitlab", group => "gitlab", mode => "0750",
         ensure => "present",
         content => template("gitlab/database.yml.erb"),
       } 

  exec { "bundle install and rake":
         cwd     => "/home/gitlab/gitlab",
         user    => "gitlab",
         command => "bundle install --without development test sqlite postgres --deployment && bundle exec rake gitlab:app:setup RAILS_ENV=production",
         path    => "/usr/local/rvm/gems/ruby-1.9.3-p286/bin/",
#         creates => "?",
       }

  file { "/etc/init.d/gitlab":
         owner   => "gitlab",
         group   => "gitlab",
         mode    => "0750",
         content => template("gitlab/gitlab.conf.erb"),
       }

  file { "/etc/${gitlab::web_service}/conf.d/gitlab.conf":
         owner   => "gitlab",
         group   => "gitlab",
         mode    => "0644",
         ensure  => "present",
         content => template("gitlab/gitlab_${web_service}.conf.erb"),
       }

  exec { "Move gitlab to document root":
         command => "/bin/mv /home/gitlab/gitlab ${gitlab::web_doc_root}",
         creates => "/var/www/html/gitlab",
  	   }

  file { "gitlab symlink":
         path   => "/home/gitlab/gitlab",
         ensure => "symlink",
         target => "${gitlab::web_doc_root}/gitlab",
       }

  file { "${gitlab::web_doc_root}/config/unicorn.rb":
         owner   => "gitlab",
         group   => "gitlab",         
         content => template("gitlab/unicorn.rb.erb"),
       }

  exec { "Configure git":
         user    => "gitlab",
         command => "git config --global user.name \"GitLab\" && git config --global user.email \"gitlab@localhost\"",
         path    => "/usr/bin/",
         onlyif  => "test `git config -f /home/gitlab/.git/config -l | grep 'gitlab@' | wc -l` -eq 0",
       }


  Exec["Create EPEL repo"] -> 
  Service["redis"] -> 
  Service["mysqld"] -> 
  Exec["Install RVM"] -> 
  Exec["Create database and grant privileges"] -> 
  Exec["SSH keygen for gitlab and copy gitlab pub key to git"] ->
  Exec["git clone gitolite"] -> 
  Exec["Export /home/git/bin to PATH"] -> 
  Exec["Install gitolite"] -> 
  File["/home/git"] -> 
  Exec["Setup gitolite"] -> 
  Exec["Clone gitlab"] -> 
  File["/home/git/.gitolite/hooks/common/post-receive"] -> 
  File["/home/gitlab/gitlab/config/gitlab.yml"] -> 
  File["/home/gitlab/gitlab/config/database.yml"] -> 
  Exec["bundle install and rake"] -> 
  File["/etc/init.d/gitlab"] -> 
  File["/etc/${gitlab::web_service}/conf.d/gitlab.conf"]
  #Exec["Move gitlab to document root"] -> 
  #File["gitlab symlink"] -> 
  #File["${gitlab::web_doc_root}/config/unicorn.rb"] ->
  #Exec["Configure git"]
#  File["/etc/nginx/sites-enabled/gitlab"] # need condition here for httpd vs nginx installation

}
