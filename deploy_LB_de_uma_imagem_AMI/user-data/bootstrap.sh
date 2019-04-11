#!/bin/sh
yum install -y httpd
service httpd start
chkconfig httpd on

echo "Hello my friend !!!" > /var/www/html/index.html