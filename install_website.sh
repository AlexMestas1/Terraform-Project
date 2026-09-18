#!/bin/bash
yum update -y
yum install -y httpd

cat > /var/www/html/index.html << 'HTML'
<!DOCTYPE html>
<html>
<head>
  <title>Terraform Demo Server</title>
  <style>
    body {
      font-family: sans-serif;
      background: #1b1f27;
      color: #eee;
      text-align: center;
      padding-top: 80px;
    }
    h1 { color: #4fd1c7; }
    p { color: #9aa6bf; }
  </style>
</head>
<body>
  <h1>This server was provisioned with Terraform</h1>
  <p>ec2.tf, main.tf, variables.tf, outputs.tf, this page and nothing fancier.</p>
</body>
</html>
HTML

systemctl enable httpd
systemctl start httpd
