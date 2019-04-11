resource "aws_instance" "ASG-mudeseuplano-prod-pub" {
 count = "${var.count}"
 ami = "${var.ami}"
 instance_type = "${var.instance_type}"
 key_name = "${var.key_name}"
 #security_groups = "${var.security_groups}"
 vpc_security_group_ids = "${var.}"
 subnet_id = "${var.subnet_id}" 
 
 tags {
   Name = "${format("ASG-mudeseuplano-prod-%02d",count.index+1)}"
   Ambiente = "${var.tags.Ambiente}"
   Marca = "${var.tags.Marca}"
   Produto = "${var.tags.Produto}"
   Conta = "${var.tags.Conta}"
   Plataforma = "${var.tags.Plataforma}"
 }
}