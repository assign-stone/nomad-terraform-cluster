#!/bin/bash
set -e

yum update -y
yum install -y unzip curl jq

yum install -y docker
systemctl enable docker
systemctl start docker
usermod -aG docker ec2-user

# Install Nomad
bash /tmp/install_nomad.sh

# Create Nomad systemd service
cat <<EOF >/etc/systemd/system/nomad.service
[Unit]
Description=Nomad
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=/usr/local/bin/nomad agent -dev
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable nomad
systemctl start nomad
