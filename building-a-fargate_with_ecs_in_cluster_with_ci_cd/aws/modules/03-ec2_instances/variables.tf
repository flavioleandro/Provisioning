variable "project_name" { }
variable "env" { }
variable "public_subnet1_id" { }
variable "public_subnet2_id" { }
variable "vpc_id" { }
variable "app_port" { }
variable "count" {
   default = "2"
}
variable "ami" {
   default = "ami-0351742ccdf731099" # base-mudeseuplano-apache
}
variable "tags" {
  type = "map"
  default = {
    Ambiente        = "X"
    Torre           = "X"
    Marca           = "X"
    Centro-de-Custo = "X"
    Projeto         = "X"
    Servico         = "X"
    Conta           = "X"
    Plataforma      = "X"
  }
}