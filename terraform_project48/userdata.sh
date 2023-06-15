
!/bin/bash
yum update -y
yum install -y httpd
systemctl enable httpd
 systemctl start httpd
echo "Hello from Terraform! Welcome to Ivan Minang Website" > /var/www/html/index.html