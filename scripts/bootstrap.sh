#!/bin/bash
set -e

ROLE="${ROLE}"           # passed from Terraform: server/client
SERVER_IP="${SERVER_IP}" # only needed by client
NOMAD_VERSION="${NOMAD_VERSION}"  # passed from Terraform

# Update and install dependencies
yum update -y
yum install -y yum-utils shadow-utils docker jq

# Enable and start Docker
systemctl enable docker
systemctl start docker
usermod -aG docker ec2-user

# Add HashiCorp repo and install Nomad
yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
yum install -y "nomad-${NOMAD_VERSION}"

# Create Nomad user and directories
useradd --system --home /etc/nomad.d --shell /bin/false nomad || true
mkdir -p /etc/nomad.d
chmod 700 /etc/nomad.d
mkdir -p /opt/nomad
chown -R nomad:nomad /etc/nomad.d /opt/nomad

# Create Nomad config based on role
if [ "$ROLE" = "server" ]; then
cat <<EOF >/etc/nomad.d/server.hcl
server {
  enabled = true
  bootstrap_expect = 1
}
data_dir = "/opt/nomad"
bind_addr = "0.0.0.0"
EOF
else
cat <<EOF >/etc/nomad.d/client.hcl
client {
  enabled = true
  servers = ["${SERVER_IP}:4647"]
}
data_dir = "/opt/nomad"
bind_addr = "0.0.0.0"
EOF
fi

# Create Nomad systemd service
cat <<EOF >/etc/systemd/system/nomad.service
[Unit]
Description=Nomad
Documentation=https://nomadproject.io/docs/
Wants=network-online.target
After=network-online.target

[Service]
User=nomad
Group=nomad
ExecStart=/usr/bin/nomad agent -config=/etc/nomad.d
ExecReload=/bin/kill -HUP \$MAINPID
KillSignal=SIGINT
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

# Enable and start Nomad service
systemctl daemon-reload
systemctl enable nomad
systemctl start nomad
