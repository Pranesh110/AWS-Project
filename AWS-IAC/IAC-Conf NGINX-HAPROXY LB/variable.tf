variable "cidr_block" {
    description = "cidr_block for vpc"
    default= "172.16.0.0/16"
}

variable "aws_ami" {
    description= "ami_id"

}

variable "aws_instance" {
    description = "instance_type"
}