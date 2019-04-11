variable "region" {
  description = "AWS Region"
  default     = "us-east-1"
}

variable "ssh_public_key_path" {
  description = "Public key path"
  default     = "/home/ec2-user/.ssh/id_rsa.pub"
}

#variable "public_key_extension" {
 # description = "Public key path"
 # default = "/home/ec2-user/.ssh/id_rsa.pub"
#}

variable "aws_access_key" {
  description = "aws_access_key"
  default     = "AKIARMEROPMAZGTTDKPB"
}
variable "aws_secret_key" {
  description = "aws_secret_key"
  default     = "ubvpzeLBBgL2p1s2JrQQA9gxHnCek/tCpzXAv6G9"
}

variable "ami" {
  description = "AMI"
  default     = "ami-8c1be5f6" // Amazon Linux
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "t2.micro"
}