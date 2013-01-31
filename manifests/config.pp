# = Class: gitlab::config
#
# Configures and "installs" gitlab. Order of operations is from top to bottom, declaration at bottom
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
  exec { "Install RVM and ruby":
        command => "curl -L https://get.rvm.io | bash -s stable \
                      && /usr/local/rvm/bin/rvm install ${gitlab::$ruby_version} \
  					  && /usr/local/rvm/scripts/rvm \
  					  && /usr/local/rvm/bin/rvm use ${gitlab::$ruby_version} --default --create",
		path    => "/bin/:/usr/bin/",
		creates => "/usr/local/rvm/rubies/ruby-${gitlab::$ruby_version}";
#		onlyif  => "test `/usr/local/rvm/bin/rvm list 2</dev/null | grep '${gitlab::$ruby_version}' | wc -l` -eq 0",
  }
  
  exec { "Install gems as gitlab":
         user    => "gitlab",
         cwd     => "/home/gitlab",
         command => "gem install bundler charlock_holmes grit rails rake rb-inotify sidekiq unicorn",
         path    => "/usr/local/rvm/rubies/ruby-${gitlab::$ruby_verison}/bin/gem";
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

  exec { "SSH keygen for gitlab":
         user    => "gitlab",
         command => "ssh-keygen -q -t rsa -f /home/gitlab/.ssh/id_rsa -N ''",
         path    => "/bin/:/usr/bin/:/usr/local/bin/",
         creates => "/home/gitlab/.ssh/id_rsa";
       }

  exec { "Copy gitlab pub key to git":
         command => "cp -f /home/gitlab/.ssh/id_rsa.pub /home/git/gitlab.pub \
					  && chmod 0555 /home/git/gitlab.pub \
					  && chown git.git /home/git/gitlab.pub",
         path    => "/bin/:/usr/bin/:/usr/local/bin/",
         creates => "/home/git/gitlab.pub";
       }

  exec { "git clone gitolite":
         user    => "git",
         cwd     => "/home/git",
         command => "/usr/bin/git clone --recursive -b ${gitlab::gitlab_fork} https://github.com/gitlabhq/gitolite.git /home/git/gitolite",
         creates => "/home/git/gitolite/.git",
       }

#  exec { "Export /home/git/bin to PATH":
#         user    => "git",
#         command => "mkdir -p /home/git/bin && echo -e \
#         						\"PATH=\$PATH:/home/git/bin\nexport PATH\" >> /home/git/.bash_profile",
#         path    => "/bin/:/usr/bin/:/usr/local/bin/",
#         onlyif  => "test `grep '/home/git/bin' /home/git/.bash_profile | wc -l` -ne 0";
#       }
  
  file { "/home/git/bin": owner => "git", group => "gitlab", mode => "0775", ensure => "directory"; }

  exec { "Install gitolite":
         user    => "git",
         cwd     => "/home/git",
         command => "/home/git/gitolite/install -ln /home/git/bin",
         creates => "/home/git/bin/gitolite";
       }


#  file { "/home/git":
#         path    => "/home/git",
#         recurse => "true",
#         owner   => "git",
#         group   => "git",
#         mode    => "755";
#       }

# Since 'repositories' doesn't exist until we setup gitolite, puppet sees this as a cyclical dependency
# this may be fixed with a 'require' statement, but not sure.
  exec { "Setup gitolite":
         user        => "git",
         cwd         => "/home/git",
#         environment => ["HOME=/home/git/bin"],
#         provider    => "shell",
         command     => "/home/git/bin/gitolite setup -pk /home/git/gitlab.pub \
                           && chmod 750 /home/git/.gitolite \
                           && chown -R git:git /home/git/.gitolite \
                           && chmod -R ug+rwXs,o-rwx /home/git/repositories/ \
                           && chown -R git:git /home/git/repositories/",
#         onlyif      => "test `/home/git/bin/gitolite list-users | grep gitlab | wc -l` -eq 0",
         path        => "/bin/",
         logoutput   => true,
       }

	
  exec { "Clone gitlab":
         user    => "gitlab",
         cwd     => "/home/gitlab",
         command => "/usr/bin/git clone -b stable https://github.com/gitlabhq/gitlabhq.git /home/gitlab/gitlab",
         creates => "/home/gitlab/gitlab",
       }

  exec { "Copy post-receive to gitolite":
          path    => "/bin/",
          command => "cp /home/gitlab/gitlab/lib/hooks/post-receive /home/git/.gitolite/hooks/common/post-receive \
                        && chown git.git /home/git/.gitolite/hooks/common/post-receive \
                        && chmod 0750 /home/git/.gitolite/hooks/common/post-receive",
          creates => "/home/git/.gitolite/hooks/common/post-receive";
       }

#  file { "/home/git/.gitolite/hooks/common/post-receive":
#         owner   => "git", group => "git", mode => "0750",
#         ensure  => "present",
#         content => template("gitlab/post-receive.erb"),
#       }

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
         cwd      => "/home/gitlab/gitlab",
         user     => "gitlab",
#         #environment => ["HOME=/home/gitlab/bin"],
         command  => "/usr/local/rvm/bin/bundle install --without test sqlite postgres --deployment \
                        &&  /usr/bin/yes \"yes\" | /usr/local/rvm/gems/ruby-${gitlab::$ruby_version}/bin/bundle exec rake gitlab:setup RAILS_ENV=production \
                        && /usr/local/rvm/gems/ruby-${gitlab::$ruby_version}/bin/bundle \
                        && /usr/local/rvm/gems/ruby-${gitlab::$ruby_version}/bin/bundle exec rake sidekiq:start \
                        && /usr/local/rvm/gems/ruby-${gitlab::$ruby_version}/bin/bundle exec rake gitlab:check RAILS_ENV=production",
##         command     => "/usr/local/rvm/bin/bundle install --without development test sqlite postgres --deployment \
#                      && /usr/local/rvm/bin/bundle exec rake gitlab:app:setup RAILS_ENV=production",
#         #path    => "/usr/local/rvm/gems/ruby-${gitlab::$ruby_version}-p327/bin/",
         creates => ["/home/gitlab/gitlab/vendor/bundle","/home/gitlab/gitlab/log/sidekiq.log"]
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

# Move and symlink are done in the same command, otherwise puppet complains about a dependency cycle
  exec { "Move gitlab to document root":
         command => "/bin/mv /home/gitlab/gitlab ${gitlab::web_doc_root} && ln -s /home/gitlab/gitlab ${gitlab::web_doc_root}",
         creates => "/var/www/html/gitlab",
  	   }

#  file { "gitlab symlink":
#         path   => "/home/gitlab/gitlab",
#         ensure => "symlink",
#         target => "${gitlab::web_doc_root}",
#       }

  file { "${gitlab::web_doc_root}/config/unicorn.rb":
         owner   => "gitlab",
         group   => "gitlab",         
         content => template("gitlab/unicorn.rb.erb"),
       }


  exec { "Configure git":
         user        => "gitlab",
         cwd         => "/home/gitlab",
         environment => ["HOME=/home/gitlab"],
         command     => "git config --global user.name GitLab && git config --global user.email gitlab@localhost",
         path        => "/usr/bin/",
         onlyif      => "test `git config -f /home/gitlab/.git/config -l | grep 'gitlab@' | wc -l` -eq 0",
       }

#  exec { "Install passenger apache module":
#         command     => "/usr/bin/passenger-install-apache2-module -a",
#       }

/*
  exec { "Configure git":
		#user    => "gitlab",
		path    => ["/usr/bin", "/bin"],
		command => "git config --global user.name GitLab; git config --global user.email gitlab@localhost; break",
		onlyif  => "test `grep -i gitlab /home/gitlab/.gitconfig | wc -l` -eq 0",
		#onlyif  => "test `git config --get user.name | grep -i gitlab`"
	}
	*/

  exec { "Download init script":
         command => "curl --output /etc/init.d/gitlab https://raw.github.com/gitlabhq/gitlab-recipes/4-1-stable/init.d/gitlab",
         path    => "/bin/",
         creates => "/etc/init.d/gitlab",
       }

  exec { "Start gitlab":
         command     => "/etc/init.d/gitlab start",
         onlyif      => "test `/etc/init.d/gitlab status 2>/dev/null | egrep -i 'unicorn|sidekiq' | wc -l` -ne 2",
       }


 # Mysql::Db[$gitlab::db_name] ->
  Service["mysqld"] -> 
  Service["redis"] -> 
  Exec["Install RVM and ruby"] -> 
  Exec["Install gems as gitlab"] -> 
  Exec["Create database and grant privileges"] -> 
  Exec["SSH keygen for gitlab"] ->
  Exec["Copy gitlab pub key to git"] ->
  Exec["git clone gitolite"] -> 
#  Exec["Export /home/git/bin to PATH"] ->
  Exec["Install gitolite"] ->
  File["/home/git/bin"] -> 
  Exec["Setup gitolite"] ->
  Exec["Clone gitlab"] ->
  File["/home/git/.gitolite/hooks/common/post-receive"] -> 
  File["/home/gitlab/gitlab/config/gitlab.yml"] -> 
  File["/home/gitlab/gitlab/config/database.yml"] -> 
  Exec["bundle install and rake"] -> 
  File["/etc/init.d/gitlab"] ->
  Exec["Move gitlab to document root"] ->
  File["${gitlab::web_doc_root}/config/unicorn.rb"] ->
  File["/etc/${gitlab::web_service}/conf.d/gitlab.conf"] ->
#  File["gitlab symlink"] -> 
  Exec["Configure git"] ->
  Exec["Download init script"] ->
  Exec["Start gitlab"] ->
#  Exec["Install passenger apache module"] #->
  #Exec["Start gitlab"]
  #File["/etc/nginx/sites-enabled/gitlab"] # need condition here for httpd vs nginx installation
}
