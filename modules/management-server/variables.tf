variable "common" {
  type = object({
    # Name for created resources. Some resources may use this as prefix.
    name = optional(string, "kkowa-management-server")

    # Common annotations for all resources.
    annotations = optional(map(string), {})

    # Common labels for all resources.
    labels = optional(map(string), {})
  })
  nullable    = false
  default     = {}
  description = "Common configuration that affects overall resources."
}

variable "namespace" {
  type = object({
    # Namespace's name to use or create.
    name = optional(string, "default")

    # Whether to create the namespace or not.
    create = optional(bool, false)
  })
  nullable    = false
  default     = {}
  description = "The namespace where resources created."

  validation {
    condition     = !(var.namespace.name == "default" && var.namespace.create)
    error_message = "`.name` must be specified other than \"default\" if `.create` set `true`."
  }
}

variable "service_account" {
  type = object({
    # Name of service account to use or create.
    name = optional(string, "default")

    # Whether to create the service account or not.
    create = optional(bool, false)
  })
  nullable    = false
  default     = {}
  description = "The service account for created workloads."

  validation {
    condition     = !(var.service_account.name == "default" && var.service_account.create)
    error_message = "`.name` must be set other than \"default\" if `.create` set `true`."
  }
}

# TODO: Should use version tag(e.g. v1 or v1.3 or v1.3.2) in future
# TODO: Pull secrets support
variable "image" {
  type = object({
    # Image's repository.
    repository = optional(string, "ghcr.io/kkowa/management-server")

    # Tag of the image.
    tag = optional(string, "main")
  })
  nullable    = false
  default     = {}
  description = "The application image to use to create containers. All pods created by deployment or job uses this."
}

variable "config" {
  type = object({
    # kkowa's crawler gRPC endpoint URL.
    crawler_url = string
  })
  nullable    = false
  description = "Application configurations."
}

variable "extra_config" {
  type        = map(string)
  nullable    = false
  default     = {}
  description = "Extra application config to pass. May override existing items if key duplicates."
}

variable "sensitive_config" {
  type = object({
    # Django secret key used for cryptographic signing. Automatically generated if not specified.
    secret_key = optional(string)

    # PostgreSQL database URL. If not set, an chart release for this will be created.
    database_url = optional(string)

    # Redis cache URL. If not set, an chart release for this will be created.
    cache_url = optional(string)

    # RabbitMQ message broker URL for Celery. If not set, an chart release for this will be created.
    message_broker_url = optional(string)
  })
  nullable    = false
  sensitive   = true
  default     = {}
  description = "Sensitive application configurations."
}

variable "extra_sensitive_config" {
  type        = map(string)
  nullable    = false
  default     = {}
  description = "Extra sensitive application config to pass. May override existing items if key duplicates."
}

variable "components" {
  type = object({
    management_server = object({
      # Component-specific annotations, adding to common annotations.
      annotations = optional(map(string), {})

      # Component-specific labels, adding to common labels.
      labels = optional(map(string), {})

      # Number of replicas to be created for component.
      replicas = optional(number, 1)

      # Resources quota
      resources = object({
        limits = map(string)
      })
    })
    worker = object({
      # Component-specific annotations, adding to common annotations.
      annotations = optional(map(string), {})

      # Component-specific labels, adding to common labels.
      labels = optional(map(string), {})

      # Number of replicas to be created for component.
      replicas = optional(number, 1)

      # Resources quota
      resources = object({
        limits = map(string)
      })
    })
    periodic_scheduler = object({
      # Component-specific annotations, adding to common annotations.
      annotations = optional(map(string), {})

      # Component-specific labels, adding to common labels.
      labels = optional(map(string), {})

      # Number of replicas to be created for component.
      replicas = optional(number, 1)

      # Resources quota
      resources = object({
        limits = map(string)
      })
    })
  })
  nullable    = false
  description = "Customizable options for components."
  default = {
    management_server = {
      resources = {
        limits = {
          "cpu"    = "500m"
          "memory" = "1Gi"
        }
      }
    }
    worker = {
      resources = {
        limits = {
          "cpu"    = "500m"
          "memory" = "1Gi"
        }
      }
    }
    periodic_scheduler = {
      resources = {
        limits = {
          "cpu"    = "500m"
          "memory" = "1Gi"
        }
      }
    }
  }

  validation {
    condition = (
      var.components.management_server.replicas >= 1
      && var.components.worker.replicas >= 1
      && var.components.periodic_scheduler.replicas >= 1
    )
    error_message = "`.*.replicas` must be greater than 0."
  }
}

variable "service" {
  type = object({
    type = optional(string, "NodePort")
    port = optional(number, 8000)
  })
  nullable    = false
  default     = {}
  description = "The service for application."
}
