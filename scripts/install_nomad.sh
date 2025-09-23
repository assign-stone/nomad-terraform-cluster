#!/bin/bash
set -e

NOMAD_VERSION="1.8.0"
cd /tmp

# download and install nomad binary
curl -sSL "https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_linux_amd64.zip" -o nomad.zip
unzip -o nomad.zip
install -m 0755 nomad /usr/local/bin/nomad

# create user/dirs
useradd --system --home /etc/nomad.d --shell /bin/false nomad || true
mkdir -p /etc/nomad.d /opt/nomad
chown -R nomad:nomad /etc/nomad.d /opt/nomad
chmod 700 /etc/nomad.d
