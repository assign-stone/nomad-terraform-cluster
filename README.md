Here’s a **complete solution blueprint with Terraform, scripts, and steps** for your MLOps Engineer test task: **Nomad Cluster Deployment** 🚀

---

# 📌 Architecture Overview

* **Cloud Provider**: AWS (Terraform IaC)
* **Networking**:

  * VPC with public/private subnets
  * Internet Gateway + NAT Gateway
  * Security Groups restricting inbound (SSH disabled, use SSM)
* **Cluster**:

  * 1 × Nomad Server (EC2, private subnet)
  * 2 × Nomad Clients (EC2, private subnet, scalable via `count`)
  * Consul agent alongside Nomad for service discovery
* **Access**:

  * Secure UI access via AWS SSM port forwarding (no public SG exposure)
  * Optionally, reverse proxy with Nginx + BasicAuth + ACM TLS behind ALB
* **Workload**:

  * Sample Nomad Job running a containerized Nginx/Hello-World app
  * App exposed via AWS ALB

---

# 📂 Repository Structure

```
nomad-cluster-terraform/
├── README.md
├── main.tf
├── variables.tf
├── outputs.tf
├── modules/
│   ├── vpc/
│   │   └── vpc.tf
│   ├── nomad-server/
│   │   └── server.tf
│   ├── nomad-client/
│   │   └── client.tf
├── scripts/
│   ├── install_nomad.sh
│   ├── install_consul.sh
│   └── bootstrap.sh
└── jobs/
    └── hello-world.nomad
```

---

# 🛠 Terraform Code Snippets

### **VPC Module (modules/vpc/vpc.tf)**

```hcl
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
}
```

---

### **Nomad Server EC2 (modules/nomad-server/server.tf)**

```hcl
resource "aws_instance" "server" {
  ami           = "ami-xxxxxxxx" # Ubuntu 22.04 LTS
  instance_type = "t3.medium"
  subnet_id     = var.subnet_id
  user_data     = file("${path.module}/../../scripts/bootstrap.sh")

  tags = {
    Name = "nomad-server"
  }
}
```

---

### **Nomad Client EC2 (modules/nomad-client/client.tf)**

```hcl
resource "aws_instance" "clients" {
  count         = var.client_count
  ami           = "ami-xxxxxxxx"
  instance_type = "t3.small"
  subnet_id     = var.subnet_id
  user_data     = file("${path.module}/../../scripts/bootstrap.sh")

  tags = {
    Name = "nomad-client-${count.index}"
  }
}
```

---

# 📜 Scripts

### **scripts/install\_nomad.sh**

```bash
#!/bin/bash
set -e

NOMAD_VERSION=1.8.0
curl -sSL https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_linux_amd64.zip -o /tmp/nomad.zip
unzip /tmp/nomad.zip -d /usr/local/bin/
useradd --system --home /etc/nomad.d --shell /bin/false nomad
mkdir -p /etc/nomad.d
chmod 700 /etc/nomad.d
```

### **scripts/bootstrap.sh**

```bash
#!/bin/bash
set -e
apt-get update -y
apt-get install -y unzip curl jq

# Install Consul & Nomad
bash /tmp/install_consul.sh
bash /tmp/install_nomad.sh

# Systemd service for Nomad
cat <<EOF >/etc/systemd/system/nomad.service
[Unit]
Description=Nomad
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=/usr/local/bin/nomad agent -config=/etc/nomad.d
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

systemctl enable nomad
systemctl start nomad
```

---

# 🚀 Nomad Job (jobs/hello-world.nomad)

```hcl
job "hello-world" {
  datacenters = ["dc1"]

  group "web" {
    count = 1

    task "nginx" {
      driver = "docker"

      config {
        image = "nginx:alpine"
        ports = ["http"]
      }

      resources {
        cpu    = 100
        memory = 128
      }
    }

    network {
      port "http" {
        static = 8080
      }
    }
  }
}
```

---

# 📖 Deployment Steps

1. **Clone repo & init Terraform**

   ```bash
   git clone https://github.com/YOURUSER/nomad-cluster-terraform.git
   cd nomad-cluster-terraform
   terraform init
   terraform apply -auto-approve
   ```

2. **Access Nomad UI (securely)**

   ```bash
   aws ssm start-session --target <server-instance-id> --document-name AWS-StartPortForwardingSession --parameters '{"portNumber":["4646"], "localPortNumber":["4646"]}'
   ```

   👉 Then open [http://localhost:4646](http://localhost:4646)

3. **Deploy hello-world job**

   ```bash
   nomad job run jobs/hello-world.nomad
   ```

4. **Verify app**

   * If using ALB: Visit `http://<alb-dns-name>:8080`
   * If using port forwarding: `curl http://localhost:8080`

---

# 🔒 Security Best Practices

* No SSH exposed; all access via **AWS SSM Session Manager**
* Private subnets for all Nomad nodes
* TLS can be enabled using `nomad auto-encrypt` or `vault` integration
* IAM roles assigned to instances (no hardcoded creds)

---

# 🎁 Bonus Add-ons

* **CI/CD**: Add GitHub Actions workflow (`.github/workflows/terraform.yml`) to auto-deploy
* **Monitoring**: Install Prometheus + Grafana, or enable Nomad’s telemetry to CloudWatch
* **Secrets Management**: Integrate with HashiCorp Vault for app secrets
