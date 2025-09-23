job "hello-world" {
  datacenters = ["dc1"]

  group "web" {
    count = 1

    network {
      port "http" {
        to     = 80      # map container port 80
        static = 8080    # expose on host port 8080
      }
    }

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
  }
}
avh-ddzp-qao
