#!/bin/bash
# stop on the first error and log everything, so a failed boot can be
# debugged from /var/log/user-data.log instead of guessing
set -euxo pipefail
exec > >(tee -a /var/log/user-data.log) 2>&1

dnf update -y
dnf install -y httpd

# the instance requires IMDSv2, so asking the metadata service for anything
# means getting a short lived session token first. a plain GET returns 401
TOKEN=$(curl -fsS -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 300")
INSTANCE_ID=$(curl -fsS -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/instance-id)
AZ=$(curl -fsS -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/placement/availability-zone)

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
    .meta { font-family: monospace; font-size: 0.9em; }
  </style>
</head>
<body>
  <h1>This server was provisioned with Terraform</h1>
  <p>ec2.tf, main.tf, variables.tf, outputs.tf, this page and nothing fancier.</p>
  <p class="meta">instance __INSTANCE_ID__ in __AZ__</p>
</body>
</html>
HTML

sed -i "s/__INSTANCE_ID__/$INSTANCE_ID/; s/__AZ__/$AZ/" /var/www/html/index.html

systemctl enable --now httpd

# fail the script, and so the log, if apache isn't actually answering
curl -fsS --retry 10 --retry-connrefused --retry-delay 2 http://localhost/ > /dev/null
echo "httpd is serving the demo page"
