# = Class: gitlab::config
#
# Configures and "installs" gitlab, if you want to call it an install. 
# Order of operations is from top to bottom, declaration at the bottom
#

class gitlab::config {

	#class { 'mysql': }
	#class { 'mysql::server': 
	#  config_hash => { 'root_password' => 'foo' }
	#}
	#mysql::db { $gitlab::db_name:
#		user     => "gitlab",
#		password => "omg",
#		host     => "localhost",
#		grant    => ["all"],
#	}

  # Ensure mysql started
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

  # Only needed once so rvm can be installed by [gitlab] the rvm group. This will be overwritten by a puppet run
  exec { "Temporary sudo for rvm group":
         command => "echo '%rvm    ALL=NOPASSWD: ALL' >> /etc/sudoers",
         onlyif  => "test `grep rvm /etc/sudoers | grep -v grep | wc -l` -eq 0",
         path    => "/bin/:/usr/bin/";
       } 

  # eventually parameterize the RVM version for installation
  # gitlab is finicky and requires a specific version of ruby as of 4.0
  # there was a syntax change between p327 and p374 (most recent) that 
  #  causes gitlab to fail when raking. Hopefully this will be fixed in
  #  future gitlab releases...?
  exec { "Install RVM":
       # provider => "shell",
         user        => "gitlab",
         cwd         => "/home/gitlab",
#         environment => "PATH=$PATH:/home/gitlab/bin",
         command     => "curl -L https://get.rvm.io | sudo bash -s stable && /usr/local/rvm/bin/rvm reload", 
	 path        => "/bin/:/usr/bin/",
	 creates     => "/usr/local/rvm/rubies/ruby-${gitlab::ruby_version}";
#	 onlyif   => "test `/usr/local/rvm/bin/rvm list 2</dev/null | grep '1.9.3' | wc -l` -eq 0",
       }
  
  exec { "Install ruby version ${gitlab::ruby_version}. This takes about 10 minutes":
         user      => "gitlab",
         cwd       => "/home/gitlab",
         command   => "/usr/local/rvm/bin/rvm install ${gitlab::ruby_version} && /usr/local/rvm/bin/rvm alias create default ${gitlab::ruby_version} && /usr/local/rvm/scripts/rvm",
	 path      => "/bin/:/usr/bin/",
         onlyif    => "test `/usr/local/rvm/bin/rvm list 2>/dev/null | grep ${gitlab::ruby_version} | wc -l` -eq 0",
         logoutput => true,
         timeout   => "900";
       }

  exec { "One-time source of rvm-ruby":
          command  => "/usr/local/rvm/scripts/rvm",
       }

  # necessary to globally set ruby header file location to specific rvm version
#  exec { "One-time source of rvm-ruby":
#         provider => "shell",
#         command  => "export RUBYLIB=\"/usr/local/rvm/src/ruby-${gitlab::ruby_version}/include/ruby.h\"",
#         command  => "export RUBYLIB; RUBYLIB=\"/usr/local/rvm/src/ruby-${gitlab::ruby_version}/include/ruby.h\"
#                      export PATH; PATH=\"/usr/local/rvm/gems/ruby-${gitlab::ruby_version}/bin:/usr/local/rvm/gems/ruby-${gitlab::ruby_version}@global/bin:/usr/local/rvm/rubies/ruby-${gitlab::ruby_version}/bin:/usr/local/rvm/bin:$PATH\"
#
#                      export rvm_env_string; rvm_env_string=ruby-${gitlab::ruby_version}
#                      export rvm_path ; rvm_path=/usr/local/rvm
#                      export rvm_ruby_string ; rvm_ruby_string=ruby-${gitlab::ruby_version}
#                      unset rvm_gemset_name
#                      export RUBY_VERSION ; RUBY_VERSION=ruby-${gitlab::ruby_version}
#                      export GEM_HOME ; GEM_HOME=/usr/local/rvm/gems/ruby-${gitlab::ruby_version}
#                      export GEM_PATH ; GEM_PATH=/usr/local/rvm/gems/ruby-${gitlab::ruby_version}:/usr/local/rvm/gems/ruby-${gitlab::ruby_version}@global
#                      export MY_RUBY_HOME ; MY_RUBY_HOME=/usr/local/rvm/rubies/ruby-${gitlab::ruby_version}
#                      export IRBRC ; IRBRC=/usr/local/rvm/rubies/ruby-${gitlab::ruby_version}/.irbrc"
#         #command  => "/bin/bash /usr/local/rvm/environments/ruby-${gitlab::ruby_version}",
#         #command  => "source /usr/local/rvm/environments/ruby-${gitlab::ruby_version}",
#       }

# I cannot figure out why charlock_holmes fails at build here. Just run gem install charlock_holmes as gitlab and move on.

  # gems - sticking with unicorn at the moment since gitlab maintains install docs with it
  exec { "Install gems as gitlab":
#         user        => "gitlab",
#         cwd         => "/home/gitlab",
         provider    => "shell",
#         environment => "RUBYLIB=\"/usr/local/rvm/src/ruby-${gitlab::ruby_version}/include/ruby.h\"
#                         PATH=\"/usr/local/rvm/gems/ruby-${gitlab::ruby_version}/bin:/usr/local/rvm/gems/ruby-${gitlab::ruby_version}@global/bin:/usr/local/rvm/rubies/ruby-${gitlab::ruby_version}/bin:/usr/local/rvm/bin:$PATH\"
#                         rvm_env_string=ruby-${gitlab::ruby_version}
#                         rvm_bin_path=/usr/local/rvm/bin
#                         rvm_path=/usr/local/rvm
#                         rvm_prefix=/usr/local
#                         rvm_ruby_string=ruby-${gitlab::ruby_version}
#                         RUBY_VERSION=ruby-${gitlab::ruby_version}
#                         GEM_HOME=/usr/local/rvm/gems/ruby-${gitlab::ruby_version}
#                         GEM_PATH=/usr/local/rvm/gems/ruby-${gitlab::ruby_version}:/usr/local/rvm/gems/ruby-${gitlab::ruby_version}@global
#                         MY_RUBY_HOME=/usr/local/rvm/rubies/ruby-${gitlab::ruby_version}
#                         IRBRC=/usr/local/rvm/rubies/ruby-${gitlab::ruby_version}/.irbrc",
  	 command     =>	"sudo -u gitlab -H sh -c \"
                          export PATH; PATH=/usr/local/rvm/gems/ruby-${gitlab::ruby_version}/bin:/usr/local/rvm/gems/ruby-${gitlab::ruby_version}@global/bin:/usr/local/rvm/rubies/ruby-${gitlab::ruby_version}/bin:/usr/local/rvm:/usr/local/rvm/bin:/usr/lib64/qt-3.3/bin:/usr/local:/usr/lib64:/usr/lib:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:/home/gitlab/bin:$PATH
                          export RUBYLIB; RUBYLIB=/usr/local/rvm/src/ruby-${gitlab::ruby_version}/include/ruby.h
                          export rvm_env_string; rvm_env_string=ruby-${gitlab::ruby_version}
                          export rvm_path ; rvm_path=/usr/local/rvm
                          export rvm_ruby_string ; rvm_ruby_string=ruby-${gitlab::ruby_version}
                          unset rvm_gemset_name
                          export RUBY_VERSION ; RUBY_VERSION=ruby-${gitlab::ruby_version}
                          export GEM_HOME ; GEM_HOME=/usr/local/rvm/gems/ruby-${gitlab::ruby_version}
                          export GEM_PATH ; GEM_PATH=/usr/local/rvm/gems/ruby-${gitlab::ruby_version}:/usr/local/rvm/gems/ruby-${gitlab::ruby_version}@global
                          export MY_RUBY_HOME ; MY_RUBY_HOME=/usr/local/rvm/rubies/ruby-${gitlab::ruby_version}
                          export IRBRC ; IRBRC=/usr/local/rvm/rubies/ruby-${gitlab::ruby_version}/.irbrc                          
                          /usr/local/rvm/rubies/ruby-${gitlab::ruby_version}/bin/gem install --no-ri --no-rdoc bundler celluloid charlock_holmes grit rails rake rb-inotify sidekiq unicorn\"",
  	 timeout     => "900",
  	 onlyif      => "/usr/bin/test $(/usr/local/rvm/rubies/ruby-${gitlab::ruby_version}/bin/gem list | grep charlock_holmes | wc -l) -eq 0",
         logoutput   => true,
#  	 path        => "/usr/local/rvm/rubies/ruby-${gitlab::ruby_version}/bin/gem",
       }

  exec { "Create database and grant privileges":
         command => "mysql -u root -e \"CREATE DATABASE ${gitlab::db_name} DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_unicode_ci; CREATE USER 'gitlab'@'localhost' IDENTIFIED BY '${gitlab::db_pass}'; GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER ON ${gitlab::db_name}.* TO 'gitlab'@'localhost'; FLUSH PRIVILEGES;\"",
         path    => "/bin/:/usr/bin/:/usr/local/bin/",
         onlyif  => "test `mysql -u root -e \"show databases;\" 2>/dev/null | grep '${gitlab::db_name}' | wc -l` -eq 0",
       }


  exec { "SSH keygen for gitlab":
         user    => "gitlab",
         command => "ssh-keygen -q -t rsa -f /home/gitlab/.ssh/id_rsa -N ''",
         path    => "/bin/:/usr/bin/:/usr/local/bin/",
         creates => "/home/gitlab/.ssh/id_rsa"
       }

  exec { "Copy gitlab pub key to git":
         command => 'cp /home/gitlab/.ssh/id_rsa.pub /home/git/gitlab.pub \
					   && chmod 0555 /home/git/gitlab.pub \
					   && chown git.git /home/git/gitlab.pub',
         path    => "/bin/:/usr/bin/:/usr/local/bin/",
         creates => "/home/git/gitlab.pub"
       }

  exec { "git clone gitolite":
         user    => "git",
         cwd     => "/home/git",
         command => "/usr/bin/git clone --recursive -b ${gitlab::gitolite_branch} https://github.com/gitlabhq/gitolite.git /home/git/gitolite",
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

  exec { "Export PATH":
        user    => "git",
        cwd     => "/home/git",
        command => 'touch /home/git/.profile && echo -e "\nPATH=\$PATH:/home/git/bin\nexport PATH" | tee -a /home/git/.bash_profile | tee -a /home/git/.profile | chmod g+w /home/git/.profile',
        path    => "/bin/:/usr/bin/:/usr/local/bin/",
        onlyif  => 'test `grep "/home/git/bin" /home/git/.bash_profile | wc -l` -eq 0';
       }

  exec { "Install gitolite":
         user        => "git",
         cwd         => "/home/git",
#         environment => ["HOME=/home/git/bin"],
         command     => "/home/git/gitolite/install -ln /home/git/bin",
         creates     => "/home/git/bin/gitolite";
       }

  exec { "Setup gitolite":
         command   => 'sudo -u git -H sh -c "PATH=/home/git/bin:$PATH; /home/git/bin/gitolite setup -pk /home/git/gitlab.pub" \
                       && chmod 750 /home/git/.gitolite \
                       && chown -R git:git /home/git/.gitolite \
                       && chmod -R ug+rwXs,o-rwx /home/git/repositories',
         path      => "/bin/:/usr/bin/:/sbin/:/usr/sbin/",
         logoutput => true,
         creates   => "/home/git/repositories",
       }

#  exec { "Setup gitolite":
#         user        => "git",
#         cwd         => "/home/git",
##         environment => ["HOME=/home/git","PATH=/home/git/bin:/bin/:/usr/bin/:/usr/local/bin/"],#"PATH=/home/git/bin:$PATH"],
#         environment => ["PATH=/home/git/bin:/usr/local/rvm/gems/ruby-1.9.3-p327/bin:/usr/local/rvm/gems/ruby-1.9.3-p327@global/bin:/usr/local/rvm/rubies/ruby-1.9.3-p327/bin:/usr/local/rvm/bin:/usr/lib64/qt-3.3/bin:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:/home/git/bin:/home/git/bin"], #"PATH=/home/git/bin:$PATH"],
##         environment => ["HOME=/home/git/bin","PATH=/home/git/bin:$PATH"], #"PATH=/home/git/bin:$PATH"],
##         provider    => "shell",
#         command     => '/home/git/bin/gitolite setup -pk /home/git/gitlab.pub \
#                           && chmod 750 /home/git/.gitolite \
#                           && chown -R git:git /home/git/.gitolite \
#                           && chmod -R ug+rwXs,o-rwx /home/git/repositories/ \
#                           && chown -R git:git /home/git/repositories/',
##         onlyif      => "test `/home/git/bin/gitolite list-users | grep gitlab | wc -l` -eq 0",
#         path        => "/bin/:/usr/bin/",
#         logoutput   => true,
#         creates     => "/home/git/repositories",
#       }

	
  exec { "Clone gitlab":
         user    => "gitlab",
         cwd     => "/home/gitlab",
         command => "/usr/bin/git clone -b ${gitlab::gitlabhq_branch} https://github.com/gitlabhq/gitlabhq.git /home/gitlab/gitlab",
         creates => "/home/gitlab/gitlab/.git",
       }

  exec { "Set gitlab perms on log and tmp":
         command => "/bin/chown -R gitlab /home/gitlab/gitlab/log;
                     /bin/chown -R gitlab /home/gitlab/gitlab/tmp;
                     /bin/chmod -R u+rwX  /home/gitlab/gitlab/log;
                     /bin/chmod -R u+rwX  /home/gitlab/gitlab/tmp;",
       }


  exec { "Link share": #puppet really sucks at determining what's a dependency cycle and what's not
         user    => "git",
         cwd     => "/home/git",
         command => "/bin/mkdir -p /home/git/share && /bin/ln -s /home/git/.gitolite /home/git/share/gitolite",
         creates => "/home/git/share/gitolite";
       }

  exec { "Copy post-receive":
         command => "/bin/cp -f /home/gitlab/gitlab/lib/hooks/post-receive /home/git/share/gitolite/hooks/common/post-receive;
                    /bin/chown git:git /home/git/share/gitolite/hooks/common/post-receive",
         creates => "/home/git/share/gitolite/hooks/common/post-receive";
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

#  exec { "install passenger apache mod":
#  	"/usr/bin/passenger-install-apache2-module -a":
#         provider => "shell",
#         command  => "/usr/bin/passenger-install-apache2-module -a",
#         command  => "/usr/local/rvm/bin/rvm all do passenger-install-apache2-module -a",
#         path        => "/bin/",
#       }

  # For some reason, Puppet complains about dependency issues if this is set with type=file
  exec { "Set 755 on git home":
         command => "/bin/chmod 0755 /home/git";
       }

  exec { "SSH to git as gitlab": 
         user    => "gitlab",
         cwd     => "/home/gitlab",
         command => "ssh -o StrictHostKeyChecking=no git@localhost 2>/dev/null && ssh -o StrictHostKeyChecking=no git@${gitlab::host} 2>/dev/null",
         path    => "/bin/:/usr/bin/",
         creates => "/home/gitlab/.ssh/known_hosts";
       }

  exec { "Configure git":
         user        => "gitlab",
         cwd         => "/home/gitlab/gitlab",
         environment => ["HOME=/home/gitlab"],
         command     => "git config --global user.name GitLab && git config --global user.email gitlab@localhost",
         path        => "/usr/bin/",
         onlyif      => "test `git config -f /home/gitlab/gitlab/.git/config -l | grep 'gitlab@' | wc -l` -eq 0",
       }

#  exec { "bundle install and rake":
#         cwd      => "/home/gitlab/gitlab",
#         user     => "gitlab",
#         environment => ["HOME=/home/gitlab","PATH=/home/git/bin:/bin/:/usr/bin/:/usr/local/bin/"],#"PATH=/home/git/bin:$PATH"],
#         #environment => ["HOME=/home/gitlab/bin"],
#		 provider => "shell",
#         command  => "/usr/local/rvm/bin/bundle install --without test sqlite postgres --deployment \
#                      && /usr/bin/yes \"yes\" | /usr/local/rvm/gems/ruby-${gitlab::ruby_version}/bin/bundle exec rake gitlab:setup RAILS_ENV=production \
#                      && /usr/local/rvm/gems/ruby-${gitlab::ruby_version}/bin/rake db:seed_fu RAILS_ENV=production \
#                      && /usr/local/rvm/gems/ruby-${gitlab::ruby_version}/bin/bundle \
#                      && /usr/local/rvm/gems/ruby-${gitlab::ruby_version}/bin/bundle exec rake sidekiq:start \
#                      && /usr/local/rvm/gems/ruby-${gitlab::ruby_version}/bin/bundle exec rake gitlab:check RAILS_ENV=production",
##         command     => "/usr/local/rvm/bin/bundle install --without development test sqlite postgres --deployment \
#                      && /usr/local/rvm/bin/bundle exec rake gitlab:app:setup RAILS_ENV=production",
#         #path    => "/usr/local/rvm/gems/ruby-1.9.3-p286/bin/",
#         creates  => ["/home/gitlab/gitlab/vendor/bundle","/home/gitlab/gitlab/log/sidekiq.log"]
#       }

#  file { "/etc/init.d/gitlab":
#         owner   => "gitlab",
#         group   => "gitlab",
#         mode    => "0750",
#         content => template("gitlab/gitlab.init.erb"),
#       }

  exec { "/etc/init.d/gitlab":
         command => "curl --output /etc/init.d/gitlab ${gitlab::gitlab_init_url} && chmod +x /etc/init.d/gitlab",
         path    => "/bin/:/usr/bin/",
         creates => "/etc/init.d/gitlab";
       }

  file { "/etc/${gitlab::web_service}/conf.d/gitlab.conf":
         owner   => "gitlab",
         group   => "gitlab",
         mode    => "0644",
         ensure  => "present",
         content => template("gitlab/${web_service}.conf.erb"),
       }

# Move and symlink are done in the same command, otherwise puppet complains about a dependency cycle
  exec { "Move gitlab to web doc root":
         command => "mv /home/gitlab/gitlab $(dirname ${gitlab::web_doc_root}) && ln -s ${gitlab::web_doc_root} /home/gitlab/gitlab",
         path    => "/bin/:/usr/bin/",
         onlyif  => "test $(ls -l /home/gitlab | grep gitlab | grep lrwxrwxrwx | wc -l) -eq 0"; 
#         creates => "/var/www/html/gitlab/config",
  	   }

# Puppet doesn't like this declared; it sees it as a dependency cycle. This has been moved to the above exec.
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


#  exec { "/usr/bin/passenger-install-apache2-module -a":
#         command     => "yes \"\" | /usr/local/rvm/gems/ruby-'${gitlab::ruby_version}'/bin/passenger-install-apache2-module",
#         path        => "/usr/bin/",
#       }

  # Ensure httpd is started
  service { "httpd":
            ensure     => running,
            enable     => true,
            hasstatus  => true,
            hasrestart => true,
            alias      => 'httpd',
            subscribe  => Package['httpd'],
          }

  exec { "bundle install and rake (this takes about 10 mins)":
         provider  => "shell",
         cwd       => "/home/gitlab/gitlab",
#         shell   => "/usr/bin/sudo -u gitlab -H sh -c \"source /usr/local/rvm/environments/ruby-${gitlab::ruby_version}\"",
         command   => "sudo -u gitlab -H sh -c \"source /usr/local/rvm/environments/ruby-${gitlab::ruby_version};
                       /usr/local/rvm/gems/ruby-${gitlab::ruby_version}/bin/bundle install --deployment --without development test sqlite postgres; 
                       /usr/local/rvm/gems/ruby-${gitlab::ruby_version}/bin/rake db:seed_fu RAILS_ENV=production; 
                       /usr/bin/yes 'yes' | /usr/local/rvm/gems/ruby-${gitlab::ruby_version}/bin/bundle exec rake gitlab:setup RAILS_ENV=production; 
                       /usr/local/rvm/gems/ruby-${gitlab::ruby_version}/bin/bundle exec rake sidekiq:start;
                       /usr/local/rvm/gems/ruby-${gitlab::ruby_version}/bin/bundle exec rake gitlab:env:info RAILS_ENV=production;
                       /usr/local/rvm/gems/ruby-${gitlab::ruby_version}/bin/bundle exec rake gitlab:check RAILS_ENV=production;\"",
#                       /usr/local/rvm/gems/ruby-${gitlab::ruby_version}/bin/bundle exec rake gitlab:setup RAILS_ENV=production;\"", 
#                       /usr/local/rvm/gems/ruby-${gitlab::ruby_version}/bin/bundle exec rake gitlab:env:info RAILS_ENV=production;\"",
                       #/usr/local/rvm/gems/ruby-${gitlab::ruby_version}/bin/bundle; 
         path      => "/bin/:/usr/bin/:/sbin/:/usr/sbin/:",
#         creates   => ["/home/gitlab/gitlab/vendor/bundle","/home/gitlab/gitlab/log/sidekiq.log"],
         logoutput => "true",
         timeout   => "900";
  	   }

  exec { "Start gitlab":
         command     => "/etc/init.d/gitlab start",
         onlyif      => "test `/etc/init.d/gitlab status | grep -i running | wc -l` -eq 0",
         path        => "/bin/:/usr/bin/:/usr/local/bin/",
       }

#  exec { "Configure git":
#		user    => "gitlab",
#		cwd     => "/home/gitlab",
#		path    => ["/usr/bin", "/bin"],
#		command => "git config --global user.name GitLab; git config --global user.email gitlab@localhost; break",
#		onlyif  => "test `grep -i gitlab /home/gitlab/.gitconfig | wc -l` -eq 0",
#		#onlyif  => "test `git config --get user.name | grep -i gitlab`"
#	}


 # Mysql::Db[$gitlab::db_name] ->
  Service["mysqld"] -> 
  Service["redis"] -> 
  Exec["Install RVM"] -> 
  Exec["Install ruby version ${gitlab::ruby_version}. This takes about 10 minutes"] -> 
  Exec["One-time source of rvm-ruby"] -> 
  Exec["Install gems as gitlab"] -> 
  Exec["Create database and grant privileges"] ->
  Exec["SSH keygen for gitlab"] ->
  Exec["Copy gitlab pub key to git"] ->
  Exec["git clone gitolite"] -> 
#  Exec["Export /home/git/bin to PATH"] ->
  File["/home/git/bin/"] -> 
  Exec["Export PATH"] ->
  Exec["Install gitolite"] ->
  Exec["Setup gitolite"] ->
  Exec["Clone gitlab"] ->
  Exec["Set gitlab perms on log and tmp"] ->
  Exec["Link share"] ->
  Exec["Copy post-receive"] ->
#  File["/home/git/.gitolite/hooks/common/post-receive"] -> 
  File["/home/gitlab/gitlab/config/gitlab.yml"] -> 
  File["/home/gitlab/gitlab/config/database.yml"] -> 
#  Exec["install passenger apache mod"] -> 
  Exec["Set 755 on git home"] ->
  Exec["SSH to git as gitlab"] -> 
  Exec["Configure git"] ->
  Exec["/etc/init.d/gitlab"] ->
  #File["/etc/init.d/gitlab"] ->
  File["/etc/${gitlab::web_service}/conf.d/gitlab.conf"] ->
  Exec["Move gitlab to web doc root"] ->
  File["${gitlab::web_doc_root}/config/unicorn.rb"] ->
#  File["gitlab symlink"] -> 
  Service["httpd"] ->
  Exec["bundle install and rake (this takes about 10 mins)"] -> 
  Exec["Start gitlab"]
  #File["/etc/nginx/sites-enabled/gitlab"] # need condition here for httpd vs nginx installation
}
