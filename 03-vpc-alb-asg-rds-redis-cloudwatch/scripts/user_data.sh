#!/bin/bash
yum update -y
yum install -y httpd
cat <<EOF > /var/www/html/index.html
Hello from ASG instance
EOF
systemctl enable httpd
systemctl start httpd

yum install -y amazon-cloudwatch-agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a start

