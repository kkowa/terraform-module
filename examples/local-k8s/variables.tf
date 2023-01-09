variable "kubernetes" {
  type = object({
    # Path to configuration file.
    config_path = optional(string)

    # Context to use.
    config_context = optional(string)
  })
  nullable    = false
  default     = {}
  description = <<-EOT
    Kubernetes cluster configuration for providers to access the cluster.

    For local cluster running via Docker Desktop, an example for tfvars file could be:

    ```hcl
    kubernetes = {
      config_path    = "~/.kube/config"
      config_context = "docker-desktop"
    }
    ```

    Above configuration can also be set via environment variables, each `KUBE_CONFIG_PATH` and `KUBE_CTX`.
    This variable is for testing purpose, and as an example.
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
