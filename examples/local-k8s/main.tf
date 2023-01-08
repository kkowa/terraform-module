/**
  * # examples/local-k8s
  *
  * Simple example deploying kkowa to local kubernetes cluster.
  */

terraform {
  backend "local" {}
}

provider "kubernetes" {
  host               = var.kubernetes.host
  insecure           = true
  client_certificate = base64decode(var.kubernetes.client_certificate)
  client_key         = base64decode(var.kubernetes.client_key)
}

provider "helm" {
  kubernetes {
    host               = var.kubernetes.host
    insecure           = true
    client_certificate = base64decode(var.kubernetes.client_certificate)
    client_key         = base64decode(var.kubernetes.client_key)
  }
}
