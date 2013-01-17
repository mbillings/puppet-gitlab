class gitlab::stages {

  	stage { "install":
  		before => Stage["main"]
		}
}
