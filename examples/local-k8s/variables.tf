variable "kubernetes" {
  type = object({
    # Cluster host address.
    host = string

    # Base64 encoded string of client certificate.
    client_certificate = string

    # Base64 encoded string of client key.
    client_key = string
  })
  nullable    = false
  description = <<-EOT
  Kubernetes cluster configuration for providers to access the cluster.

  For local cluster running via Docker Desktop, check file `~/.kube/config`.
  EOT
}

variable "namespace" {
  type        = string
  nullable    = false
  default     = "kkowa"
  description = "The namespace to create resources at."

  validation {
    condition     = var.namespace != "default"
    error_message = "This example module prohibits using default namespace as being used for testing also."
  }
}
