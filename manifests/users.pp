# ===Class: gitlab::users          
#                                    
# Defines users and groups for gitlab
#
# ===Parameters: 
# 
# None                               
#
# ===Actions:                        
#
# None   
#
# ===Requires:           
#
# None  
#

class gitlab::users 
{
  # git user
  @user { "git":
          ensure  => "present",
          gid => "git",
          groups => ["gitlab"],
          managehome => "true",
          comment => ""
        }

  # gitlab user
  @user { "gitlab":
          ensure  => "present",
          gid => "gitlab",
          groups => ["git","rvm"],
          managehome => "true",
          comment => ""
        }

  # git group
  @group { "git":
           ensure => "present"
         }

  # gitlab group
  @group { "gitlab":
           ensure => "present"
         }
  # rvm group
  @group { "rvm":
           ensure => "present"
         }
}
