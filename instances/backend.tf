terraform{
    backend "s3"{
        bucket= "clixx-k8-bucket"
        key = "terraform.tfstate"
        region="us-east-1"
        #use_lockfile = true
        }
}