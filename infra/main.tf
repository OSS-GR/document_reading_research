terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.0"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

# Create a docker network for Weaviate
resource "docker_network" "weaviate_network" {
  name = "weaviate_network"
}

# Pull the Weaviate image
resource "docker_image" "weaviate" {
  name = "semitechnologies/weaviate:latest"
}

# Create a Docker volume for Weaviate data
resource "docker_volume" "weaviate_data" {
  name = "weaviate_data"
}

# Create the Weaviate container
resource "docker_container" "weaviate" {
  name  = "weaviate"
  image = docker_image.weaviate.image_id

  networks_advanced {
    name = docker_network.weaviate_network.name
  }

  env = [
    "QUERY_DEFAULTS_LIMIT=25",
    "AUTHENTICATION_ANONYMOUS_ACCESS_ENABLED=true",
    "DEFAULT_VECTORIZER_MODULE=none",
    "CLUSTER_HOSTNAME=node1",
  ]

  ports {
    internal = 8080
    external = 8080
  }

  ports {
    internal = 50051
    external = 50051
  }

  healthcheck {
    test         = ["CMD", "curl", "-f", "http://localhost:8080/v1/.well-known/ready"]
    interval     = "30s"
    timeout      = "10s"
    retries      = 3
    start_period = "30s"
  }

  volumes {
      volume_name    = docker_volume.weaviate_data.name
      container_path = "/var/lib/weaviate"
  }
restart = "unless-stopped"
}

# Output the Weaviate endpoint
output "weaviate_endpoint" {
  value = "http://localhost:8080"
}