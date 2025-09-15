variable "region" {
    default = "us-east-1"  
}

variable "key_name"{
    description = "EC2 Key pair name for SSH"
    type= string
}