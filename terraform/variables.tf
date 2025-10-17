variable "ami_id" {
    description = "ID of the AMI running on the EC2 Instance"
    type = string
}

variable "instance_type" {
    description = "Type of the EC2 Instance"
    type = string
}

variable "region" {
    description = "AWS Region"
    type = string
}

