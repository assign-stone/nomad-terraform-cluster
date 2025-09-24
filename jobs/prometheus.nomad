job "prometheus" {
  datacenters = ["dc1"]

  group "prometheus" {
    count = 1

    network {
      port "web" {
        static = 9090
      }
    }

    task "prometheus" {
      driver = "docker"

      config {
        image = "prom/prometheus:latest"
        ports = ["web"]
        volumes = [
          "/home/ec2-user/prometheus-config/prometheus.yml:/etc/prometheus/prometheus.yml:ro"
        ]
      }

      resources {
        cpu    = 200
        memory = 256
      }
    }
  }
}
