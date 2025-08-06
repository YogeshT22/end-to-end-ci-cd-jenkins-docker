# ---------------------------
# Terraform + Docker Example
# Purpose: Pull NGINX image and run a container locally on port 8888
# ---------------------------

terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker" # Dev Note: this is local Docker provider.
      version = "~> 3.0.1"
    }
  }
}

provider "docker" {}

resource "docker_image" "nginx_image" {
  name         = "nginx:latest"
  keep_locally = false # Dev Note: Set to true if you want to keep the image after destroying the container
}

resource "docker_container" "nginx_container" {
  image = docker_image.nginx_image.image_id
  name  = "terraform-nginx-demo"

  ports {
    internal = 80 # Dev Note: The port inside container
    external = 8888 # Dev Note: The port to expose on the host machine
  }
}
