#!/bin/bash
set -e

ROLE="${ROLE}"           # passed from Terraform: server/client
SERVER_IP="${SERVER_IP}" # only needed by client
NOMAD_VERSION="${NOMAD_VERSION}"  # passed from Terraform

# --- Update and install dependencies ---
yum update -y
yum install -y yum-utils shadow-utils docker jq amazon-cloudwatch-agent wget unzip

# --- Enable and start Docker ---
systemctl enable docker
systemctl start docker
usermod -aG docker ec2-user

# --- Add HashiCorp repo and install Nomad ---
yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
yum install -y "nomad-${NOMAD_VERSION}"

# --- Create Nomad user and directories ---
useradd --system --home /etc/nomad.d --shell /bin/false nomad || true
mkdir -p /etc/nomad.d /opt/nomad
chmod 700 /etc/nomad.d
chown -R nomad:nomad /etc/nomad.d /opt/nomad

# --- Nomad configuration ---
if [ "$ROLE" = "server" ]; then
cat <<EOF >/etc/nomad.d/server.hcl
server {
  enabled = true
  bootstrap_expect = 1
}
data_dir = "/opt/nomad"
bind_addr = "0.0.0.0"
telemetry {
  prometheus_metrics = true
}
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

# --- Create Nomad systemd service ---
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

# --- Enable and start Nomad service ---
systemctl daemon-reload
systemctl enable nomad
systemctl start nomad

# --- CloudWatch Agent setup ---
cat <<EOF >/opt/aws/amazon-cloudwatch-agent/bin/config.json
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/lib/docker/containers/*/*.log",
            "log_group_name": "nomad-docker-logs",
            "log_stream_name": "{instance_id}/{container_name}",
            "timezone": "UTC"
          },
          {
            "file_path": "/var/log/messages",
            "log_group_name": "nomad-system-logs",
            "log_stream_name": "{instance_id}/messages",
            "timezone": "UTC"
          }
        ]
      }
    }
  }
}
EOF

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json -s

# --- Node Exporter (optional for metrics) ---
wget https://github.com/prometheus/node_exporter/releases/download/v1.7.0/node_exporter-1.7.0.linux-amd64.tar.gz -P /tmp
tar xvf /tmp/node_exporter-1.7.0.linux-amd64.tar.gz -C /opt/
ln -s /opt/node_exporter-1.7.0.linux-amd64/node_exporter /usr/local/bin/node_exporter

# Create systemd service for Node Exporter
cat <<EOF >/etc/systemd/system/node_exporter.service
[Unit]
Description=Prometheus Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=ec2-user
ExecStart=/usr/local/bin/node_exporter
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable node_exporter
systemctl start node_exporter
