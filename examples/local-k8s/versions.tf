terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.4.3"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.16.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.8.0"
    }
  }
}
