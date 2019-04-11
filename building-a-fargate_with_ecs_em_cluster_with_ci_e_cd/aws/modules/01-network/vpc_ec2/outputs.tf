
# VPC 
output "vpc_arn" {
  value = "${aws_vpc.vpc.arn}"
}
output "vpc_id" {
  value = "${aws_vpc.vpc.id}"
}
output "vpc_main_rtb" {
  value = "${aws_vpc.vpc.main_route_table_id}"
}
output "vpc_cidr_block" {
  value = "${aws_vpc.vpc.cidr_block}"
}
# Subnet az1
output "subnet_az1_id" {
  value = "${aws_subnet.public_subnet_az1.id}"
}
output "subnet_az1_cidr_block" {
  value = "${aws_subnet.public_subnet_az1.cidr_block}"
}
output "subnet_az1_az" {
  value = "${aws_subnet.public_subnet_az1.availability_zone}"
}
output "subnet_az1_az_id" {
  value = "${aws_subnet.public_subnet_az1.availability_zone_id}"
}
# Subnet az2
output "subnet_az2_id" {
  value = "${aws_subnet.public_subnet_az2.id}"
}
output "subnet_az2_cidr_block" {
  value = "${aws_subnet.public_subnet_az2.cidr_block}"
}
output "subnet_az2_az" {
  value = "${aws_subnet.public_subnet_az2.availability_zone}"
}
output "subnet_az2_az_id" {
  value = "${aws_subnet.public_subnet_az2.availability_zone_id}"
}
# IGW 
output "igw_id" {
  value = "${aws_internet_gateway.igw.id}"
}
# Default rtb
output "default_rtb_id" {
  value = "${aws_default_route_table.vpc_default_rtb.id}"
}
