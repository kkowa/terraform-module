/**
  * # examples/local-k8s
  *
  * Simple example deploying kkowa to local kubernetes cluster.
  */

terraform {
  backend "local" {}
}

# TODO: Take k8s config file to support all local, devcontainer and github actions CI environments.

provider "kubernetes" {
  config_path    = var.kubernetes.config_path
  config_context = var.kubernetes.config_context
}

provider "helm" {
  kubernetes {
    config_path    = var.kubernetes.config_path
    config_context = var.kubernetes.config_context
  }
}
