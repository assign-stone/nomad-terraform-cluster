#!/bin/bash
set -e

ROLE="${role}"

yum update -y
yum install -y unzip curl jq

yum install -y docker
systemctl enable docker
systemctl start docker
usermod -aG docker ec2-user

# Install Nomad
bash /tmp/install_nomad.sh

if [ "$ROLE" = "server" ]; then
  cat <<EOF >/etc/systemd/system/nomad.service
[Unit]
Description=Nomad Server
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=/usr/local/bin/nomad agent -server -bootstrap-expect=1 -bind=0.0.0.0 -data-dir=/opt/nomad -config=/etc/nomad.d
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
else
  cat <<EOF >/etc/systemd/system/nomad.service
[Unit]
Description=Nomad Client
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=/usr/local/bin/nomad agent -client -bind=0.0.0.0 -data-dir=/opt/nomad -config=/etc/nomad.d
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
fi

mkdir -p /opt/nomad
systemctl daemon-reload
systemctl enable nomad
systemctl start nomad
