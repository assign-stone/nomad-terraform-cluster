job "node-exporter" {
  datacenters = ["dc1"]

  group "node-exporter" {
    count = 1
    type  = "system" # runs on all eligible nodes

    network {
      port "metrics" {
        static = 9100
      }
    }

    task "node-exporter" {
      driver = "docker"

      config {
        image = "prom/node-exporter:latest"
        ports = ["metrics"]
        args  = ["--path.rootfs=/host"]
        volumes = [
          "/:/host:ro,rslave"
        ]
      }

      resources {
        cpu    = 100
        memory = 128
      }
    }
  }
}
