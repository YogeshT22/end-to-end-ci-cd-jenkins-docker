# This tells Terraform which providers we need. A provider is like a plugin
# that allows Terraform to talk to a specific API (like Docker, AWS, etc.).
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.1"
    }
  }
}

# This configures the Docker provider. Since we are using a local Docker Desktop,
# the provider can connect automatically, so we don't need any special config here.
provider "docker" {}

# This is a RESOURCE block. It describes a piece of infrastructure we want to manage.
# In this case, it's a Docker image.
resource "docker_image" "nginx_image" {
  # We are telling Terraform: "Please ensure an image named 'nginx:latest' exists locally."
  # Terraform will pull it if it doesn't.
  name         = "nginx:latest"
  keep_locally = false # Set to true if you want to keep the image after destroying the container
}

# This is another RESOURCE block, this time for a Docker container.
# This resource DEPENDS on the docker_image resource above.
resource "docker_container" "nginx_container" {
  # We are telling Terraform: "Please run a container using the image we just defined."
  image = docker_image.nginx_image.image_id
  name  = "terraform-nginx-demo"

  # This defines the port mapping for the container.
  ports {
    internal = 80 # The port inside the container
    external = 8888 # The port to expose on the host machine
  }
}
