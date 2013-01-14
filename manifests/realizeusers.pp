# ===Class: gitlab::realizeusers
#                                    
# Realizes the necessary users and groups for gitlab
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

class gitlab::realizeusers inherits gitlab::users
{
  realize (
            Group["git"],
            Group["gitlab"],
            Group["rvm"],
            User["git"],
            User["gitlab"],
          )
}
