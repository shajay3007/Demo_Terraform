#1...vpc vars
variable "vpc_cidr" {
    default = "10.0.0.0/16"
}

#2...subnet IP creation
variable "pub_subnet_ip" {
  default = "10.1.0.0/24"
}

#2...subnet IP creation
variable "pub_subnet_ip_2" {
  default = "10.1.1.0/24"
}


#3....av_zone
variable "av_zone" {
    description = "availability zone of subnet"
    default = "us-east-1a"
}

#3....av_zone
variable "av_zone_2" {
    description = "availability zone of subnet"
    default = "us-east-1b"
}





#4..image id
variable "image_id" {
description = "This is default image"
default = "ami-0ebfd941bbafe70c6"
}

#5...instance type
variable "instance_type" {
  description = "this is the instance type"
  default = "t2.small"
}


