locals {
  common = {
    name = var.common.name
    annotations = merge(
      {
        # No default annotations yet
      },
      var.common.annotations
    )
    labels = merge(
      {
        "app.kubernetes.io/version"    = var.image.tag
        "app.kubernetes.io/component"  = "management-server"
        "app.kubernetes.io/part-of"    = "kkowa"
        "app.kubernetes.io/managed-by" = "Terraform"
      },
      var.common.labels
    )
  }

  namespace = try(
    kubernetes_namespace.created[0].metadata[0].name,
    data.kubernetes_namespace.existing[0].metadata[0].name
  )

  service_account = var.service_account.name

  image = "${var.image.repository}:${var.image.tag}"

  config = merge(
    {
      "DJANGO_SETTINGS_MODULE" = "config.settings.production"
      "DJANGO_ADMIN_URL"       = "admin/"
      "DJANGO_ALLOWED_HOSTS"   = "*"
      "CRAWLER_URL"            = var.config.crawler_url
      "MAILGUN_DOMAIN"         = ""
    },
    var.extra_config
  )

  sensitive_config = merge(
    {
      "DJANGO_SECRET_KEY"  = coalesce(var.sensitive_config.secret_key, random_string.django_secret_key[0].result)
      "DATABASE_URL"       = coalesce(var.sensitive_config.database_url, "postgres://postgres:password@${helm_release.database[0].name}:5432/postgres")
      "CACHE_URL"          = coalesce(var.sensitive_config.cache_url, "redis://${helm_release.cache[0].name}-master:6379")
      "MESSAGE_BROKER_URL" = coalesce(var.sensitive_config.message_broker_url, "amqp://user:password@${helm_release.message_broker[0].name}:5672/")
      "MAILGUN_API_KEY"    = ""
    },
    var.extra_sensitive_config
  )

  # Temporary local value to avoid circular reference.
  _components = {
    management_server = {
      selector_labels = {
        "app.kubernetes.io/name"     = local.common.name
        "app.kubernetes.io/instance" = "${local.common.name}-${random_string.instance_id.result}"
      }
    }
    worker = {
      selector_labels = {
        "app.kubernetes.io/name"     = "${local.common.name}-worker"
        "app.kubernetes.io/instance" = "${local.common.name}-worker-${random_string.instance_id.result}"
      }
    }
    periodic_scheduler = {
      selector_labels = {
        "app.kubernetes.io/name"     = "${local.common.name}-periodic-scheduler"
        "app.kubernetes.io/instance" = "${local.common.name}-periodic-scheduler-${random_string.instance_id.result}"
      }
    }
  }
  components = {
    management_server = {
      annotations = merge(local.common.annotations, var.components.management_server.annotations)
      labels = merge(
        local.common.labels,
        var.components.management_server.labels,
        local._components.management_server.selector_labels
      )
      replicas        = var.components.management_server.replicas
      selector_labels = local._components.management_server.selector_labels
      resources       = var.components.management_server.resources
    }
    worker = {
      annotations = merge(local.common.annotations, var.components.worker.annotations)
      labels = merge(
        local.common.labels,
        var.components.worker.labels,
        local._components.worker.selector_labels
      )
      replicas        = var.components.worker.replicas
      selector_labels = local._components.worker.selector_labels
      resources       = var.components.worker.resources
    }
    periodic_scheduler = {
      annotations = merge(local.common.annotations, var.components.periodic_scheduler.annotations)
      labels = merge(
        local.common.labels,
        var.components.periodic_scheduler.labels,
        local._components.periodic_scheduler.selector_labels
      )
      replicas        = var.components.periodic_scheduler.replicas
      selector_labels = local._components.periodic_scheduler.selector_labels
      resources       = var.components.periodic_scheduler.resources
    }
  }
}
