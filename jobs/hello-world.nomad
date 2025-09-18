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
