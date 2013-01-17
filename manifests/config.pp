# = Class: gitlab::config
#
# Configures and "installs" gitlab, if you want to call it an install. Order of operations is from top to bottom, insert new functions into list at the bottom
#

class gitlab::config {

  # Ensure mysql is started
  service { "mysqld":
            ensure     => running,
            enable     => true,
            hasstatus  => true,
            hasrestart => true,
            alias      => 'mysql',
            subscribe  => Package['mysql'],
          }

  # Ensure redis is started
  service { "redis":
            ensure     => running,
            enable     => true,
            hasstatus  => true,
            hasrestart => true,
            alias      => 'redis',
            subscribe  => Package['redis'],
          }

  # parameterize the RVM version for installation
  exec { "Install RVM":
        command => "curl -L https://get.rvm.io | bash -s stable \
                      && /usr/local/rvm/bin/rvm install 1.9.3 \
  					  && /usr/local/rvm/scripts/rvm \
  					  && /usr/local/rvm/bin/rvm use 1.9.3 --default --create",
		path    => "/bin/:/usr/bin/",
		unless  => "test `rvm -v 2</dev/null | wc -l` -eq 0",
  }
  
  exec { "SSH keygen for gitlab":
         user    => "gitlab",
         command => "ssh-keygen -q -t rsa -f /home/gitlab/.ssh/id_rsa -N ''",
         path    => "/bin/:/usr/bin/:/usr/local/bin/",
         creates => ["/home/gitlab/.ssh/id_rsa"]
       }

  exec { "Copy gitlab pub key to git":
         command => "cp /home/gitlab/.ssh/id_rsa.pub /home/git/gitlab.pub \
					  && chmod 0444 /home/git/gitlab.pub \
					  && chown git.git /home/git/gitlab.pub",
         path    => "/bin/:/usr/bin/:/usr/local/bin/",
         creates => ["/home/git/gitlab.pub"]
       }

  exec { "git clone gitolite":
         user    => "git",
         cwd     => "/home/git",
         command => "/usr/bin/git clone --recursive -b gl-v304 https://github.com/gitlabhq/gitolite.git /home/git/gitolite",
         creates => "/home/git/gitolite/.git",
       }

  exec { "Export /home/git/bin to PATH":
         user    => "git",
         command => "mkdir -p /home/git/bin && echo -e \"PATH=\$PATH:/home/git/bin\nexport PATH\" >> /home/git/.bash_profile",
         path    => "/bin/:/usr/bin/:/usr/local/bin/",
         onlyif  => "test `grep '/home/git/bin' /home/git/.bash_profile | wc -l` -ne 0";
       }

  exec { "Install gitolite":
         user    => "git",
         cwd     => "/home/git",
         command => "/home/git/gitolite/install -ln /home/git/bin",
         creates => "/home/git/bin/gitolite";
       }

  exec { "Setup gitolite":
         user     => "git",
         cwd      => "/home/git",
         provider => "shell",
         command  => 'source /home/git/.bash_profile; /home/git/bin/gitolite setup -pk /home/git/gitlab.pub',
         onlyif  => "/usr/bin/test `/home/git/bin/gitolite list-users | /bin/grep gitlab | /usr/bin/wc -l` -eq 0",
#         logoutput => true,
       }

	
  exec { "Clone gitlab":
         user    => "gitlab",
         cwd     => "/home/gitlab",
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
         command => "/usr/local/rvm/bin/bundle install --without development test sqlite postgres --deployment \
                      && /usr/local/rvm/bin/bundle exec rake gitlab:app:setup RAILS_ENV=production",
         creates => "/home/gitlab/gitlab/vendor/bundle",
       }

  file { "/etc/init.d/gitlab":
         owner   => "gitlab",
         group   => "gitlab",
         mode    => "0750",
         content => template("gitlab/gitlab.conf.erb"),
       }

  exec { "Move gitlab to document root":
         command => "/bin/mv /home/gitlab/gitlab ${gitlab::web_doc_root}",
         creates => "/var/www/html/gitlab",
  	   }

  file { "${gitlab::web_doc_root}/config/unicorn.rb":
         owner   => "gitlab",
         group   => "gitlab",         
         content => template("gitlab/unicorn.rb.erb"),
       }

  file { "/etc/${gitlab::web_service}/conf.d/gitlab.conf":
         owner   => "gitlab",
         group   => "gitlab",
         mode    => "0644",
         ensure  => "present",
         content => template("gitlab/gitlab_${web_service}.conf.erb"),
       }

  file { "gitlab symlink":
         path   => "/home/gitlab/gitlab",
         ensure => "symlink",
         target => "${gitlab::web_doc_root}/gitlab",
       }

  exec { "Configure git for gitlab":
         user    => "gitlab",
         cwd     => "/home/gitlab",
         command => "git config --global user.name GitLab && git config --global user.email gitlab@localhost",
         path    => "/usr/bin/",
         onlyif  => "test `git config -f /home/gitlab/.git/config -l | grep 'gitlab@' | wc -l` -eq 0",
       }

  Service["mysqld"] -> 
  Service["redis"] -> 
  Exec["Install RVM"] -> 
  Exec["SSH keygen for gitlab"] ->
  Exec["Copy gitlab pub key to git"] ->
  Exec["git clone gitolite"] -> 
  Exec["Export /home/git/bin to PATH"] ->
  Exec["Install gitolite"] ->
  Exec["Setup gitolite"] ->
  Exec["Clone gitlab"] ->
  File["/home/git/.gitolite/hooks/common/post-receive"] -> 
  File["/home/gitlab/gitlab/config/gitlab.yml"] -> 
  File["/home/gitlab/gitlab/config/database.yml"] -> 
  Exec["bundle install and rake"] #-> 
  File["/etc/init.d/gitlab"]
  Exec["Move gitlab to document root"] ->
  File["${gitlab::web_doc_root}/config/unicorn.rb"] ->
  File["/etc/${gitlab::web_service}/conf.d/gitlab.conf"]
  File["gitlab symlink"] -> 
  Exec["Configure git for gitlab"]
  #File["/etc/nginx/sites-enabled/gitlab"] # need condition here for httpd vs nginx installation
}
