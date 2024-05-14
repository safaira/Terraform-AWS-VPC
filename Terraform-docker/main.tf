terraform {
  required_providers{
    docker = {
      source = "kreuzwerker/docker"
      version = "~> 3.0.2"
    }
  }
}

provider "docker" {}

resource "docker_image" "nginx" {
  name = "nginx:latest"
  keep_locally = false
}

resource "docker_container" "nginx" {
  image = docker_image.nginx.name
  name = "nginx-tf-ctr"
  ports {
    internal = 80 
    external = 80   
  }
}

# to run this file
# run
# terraform init - to install provider
# terraform validate - to check .tf file configuration 
# terraform plan 
# terraform apply - to execute file
# terraform state
