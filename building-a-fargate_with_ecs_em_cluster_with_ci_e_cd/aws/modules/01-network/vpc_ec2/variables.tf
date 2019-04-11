variable "vpc_cidr_block" { } 
variable "public_subnet_az1_cidr_block" { }
variable "public_subnet_az2_cidr_block" { }
variable "private_subnet_az1_cidr_block" { }
variable "private_subnet_az2_cidr_block" { }

variable "availability_zone1" { }
variable "availability_zone2" { }
variable "env" { }
variable "project_name" { }

variable "tags" {
  type = "map"
  default = {
    Ambiente        = "dev"
    Torre           = "ecommerce"
    Marca           = "net"
    Centro-de-Custo = "n"
    Projeto         = "mudeseuplano"
    Servico         = "web"
    Conta           = "mind-dev"
    Plataforma      = "aws"
  }
}