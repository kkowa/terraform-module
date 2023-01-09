resource "random_string" "instance_id" {
  length  = 8
  upper   = false
  special = false
}

resource "random_string" "django_secret_key" {
  count = var.sensitive_config.secret_key == null ? 1 : 0

  length = 50
}

resource "helm_release" "database" {
  count = var.sensitive_config.database_url == null ? 1 : 0

  name             = "${local.common.name}-database"
  repository       = "https://charts.bitnami.com/bitnami"
  chart            = "postgresql"
  version          = "12.1.6"
  atomic           = true
  namespace        = local.namespace
  create_namespace = false

  set {
    name  = "nameOverride"
    value = "database"
  }

  set {
    name  = "auth.postgresPassword"
    value = "password"
  }
}

resource "helm_release" "cache" {
  count = var.sensitive_config.cache_url == null ? 1 : 0

  name             = "${local.common.name}-cache"
  repository       = "https://charts.bitnami.com/bitnami"
  chart            = "redis"
  version          = "17.4.0"
  atomic           = true
  namespace        = local.namespace
  create_namespace = false

  set {
    name  = "nameOverride"
    value = "cache"
  }

  set {
    name  = "architecture"
    value = "standalone"
  }

  set {
    name  = "auth.enabled"
    value = "false"
  }
}

resource "helm_release" "message_broker" {
  count = var.sensitive_config.message_broker_url == null ? 1 : 0

  name             = "${local.common.name}-message-broker"
  repository       = "https://charts.bitnami.com/bitnami"
  chart            = "rabbitmq"
  version          = "11.3.0"
  atomic           = true
  namespace        = local.namespace
  create_namespace = false

  set {
    name  = "nameOverride"
    value = "message-broker"
  }

  set {
    name  = "auth.password"
    value = "password"
  }
}

resource "kubernetes_namespace" "created" {
  count = var.namespace.create ? 1 : 0

  metadata {
    name        = var.namespace.name
    annotations = local.common.annotations
    labels      = local.common.labels
  }
}

# TODO: Attach annotations & labels to existing namespace?
data "kubernetes_namespace" "existing" {
  count = var.namespace.create ? 0 : 1

  metadata {
    name = var.namespace.name
  }
}

resource "kubernetes_service_account" "created" {
  count = var.service_account.create ? 1 : 0

  metadata {
    namespace   = local.namespace
    name        = var.service_account.name
    annotations = local.common.annotations
    labels      = local.common.labels
  }
}

resource "kubernetes_default_service_account" "default" {
  count = var.service_account.create ? 0 : 1

  metadata {
    namespace   = var.service_account.name
    annotations = local.common.annotations
    labels      = local.common.labels
  }
}

resource "kubernetes_config_map" "config" {
  metadata {
    namespace   = local.namespace
    name        = local.common.name
    annotations = local.common.annotations
    labels      = local.common.labels
  }

  data = local.config
}

resource "kubernetes_secret" "sensitive_config" {
  metadata {
    namespace   = local.namespace
    name        = local.common.name
    annotations = local.common.annotations
    labels      = local.common.labels
  }

  type = "Opaque"
  data = local.sensitive_config
}

resource "kubernetes_deployment" "management_server" {
  timeouts {
    create = "5m"
  }

  metadata {
    namespace   = local.namespace
    name        = local.common.name
    annotations = local.common.annotations
    labels      = local.common.labels
  }

  spec {
    replicas = local.components.management_server.replicas

    selector {
      match_labels = local.components.management_server.selector_labels
    }

    template {
      metadata {
        annotations = local.components.management_server.annotations
        labels      = local.components.management_server.labels
      }

      spec {
        service_account_name = local.service_account

        security_context {
          fs_group = 1000

          seccomp_profile {
            type = "RuntimeDefault"
          }
        }

        container {
          name  = "app"
          image = local.image

          security_context {
            capabilities {
              drop = ["ALL"]
            }

            run_as_user                = 10000
            run_as_non_root            = true
            read_only_root_filesystem  = true
            allow_privilege_escalation = false
          }

          resources {
            requests = {
              "cpu"    = "250m"
              "memory" = "256Mi"
            }
            limits = local.components.management_server.resources.limits
          }

          volume_mount {
            name       = "secret"
            mount_path = "/etc/app"
            read_only  = true
          }

          volume_mount {
            name       = "staticfiles"
            mount_path = "/var/app/staticfiles"
          }

          volume_mount {
            name       = "media"
            mount_path = "/var/app/media"
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map.config.metadata[0].name
            }
          }

          dynamic "env" {
            for_each = nonsensitive(keys(kubernetes_secret.sensitive_config.data))

            content {
              name  = "${env.value}_FILE"
              value = "/etc/app/${env.value}"
            }
          }

          port {
            name           = "http"
            protocol       = "TCP"
            container_port = 8000
          }

          liveness_probe {
            initial_delay_seconds = 15
            period_seconds        = 15
            timeout_seconds       = 3
            failure_threshold     = 3

            tcp_socket {
              port = "http"
            }
          }

          readiness_probe {
            initial_delay_seconds = 10
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3

            http_get {
              port = "http"
              path = "/ht/"
            }
          }
        }

        volume {
          name = "secret"

          secret {
            secret_name = kubernetes_secret.sensitive_config.metadata[0].name
          }
        }

        volume {
          name = "staticfiles"

          empty_dir {}
        }

        volume {
          name = "media"

          empty_dir {} # TODO: Later support multi R/W persistent volume and storage buckets in future
        }
      }
    }
  }
}

resource "kubernetes_deployment" "worker" {
  timeouts {
    create = "5m"
  }

  metadata {
    namespace   = local.namespace
    name        = "${local.common.name}-worker"
    annotations = local.common.annotations
    labels      = local.common.labels
  }

  spec {
    replicas = local.components.worker.replicas

    selector {
      match_labels = local.components.worker.selector_labels
    }

    template {
      metadata {
        annotations = local.components.worker.annotations
        labels      = local.components.worker.labels
      }

      spec {
        service_account_name = local.service_account

        security_context {
          fs_group = 1000

          seccomp_profile {
            type = "RuntimeDefault"
          }
        }

        container {
          name  = "management-server"
          image = local.image

          security_context {
            capabilities {
              drop = ["ALL"]
            }

            run_as_user                = 10000
            run_as_non_root            = true
            read_only_root_filesystem  = true
            allow_privilege_escalation = false
          }

          resources {
            requests = {
              "cpu"    = "250m"
              "memory" = "256Mi"
            }
            limits = local.components.worker.resources.limits
          }

          volume_mount {
            name       = "secret"
            mount_path = "/etc/app"
            read_only  = true
          }

          volume_mount {
            name       = "tmpfs"
            mount_path = "/tmp"
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map.config.metadata[0].name
            }
          }

          dynamic "env" {
            for_each = nonsensitive(keys(kubernetes_secret.sensitive_config.data))

            content {
              name  = "${env.value}_FILE"
              value = "/etc/app/${env.value}"
            }
          }

          port {
            name           = "http"
            protocol       = "TCP"
            container_port = 8000
          }

          command = ["start-celery-worker.sh"]

          liveness_probe {
            initial_delay_seconds = 15
            period_seconds        = 15
            timeout_seconds       = 5
            failure_threshold     = 3

            exec {
              command = ["/bin/sh", "-c", "poetry run celery inspect ping --destination celery@$${HOSTNAME}"]
            }
          }
        }

        volume {
          name = "secret"

          secret {
            secret_name = kubernetes_secret.sensitive_config.metadata[0].name
          }
        }

        volume {
          name = "tmpfs"

          empty_dir {}
        }
      }
    }
  }
}

resource "kubernetes_deployment" "periodic_scheduler" {
  timeouts {
    create = "5m"
  }

  metadata {
    namespace   = local.namespace
    name        = "${local.common.name}-periodic-scheduler"
    annotations = local.common.annotations
    labels      = local.common.labels
  }

  spec {
    replicas = local.components.periodic_scheduler.replicas

    selector {
      match_labels = local.components.periodic_scheduler.selector_labels
    }

    template {
      metadata {
        annotations = local.components.periodic_scheduler.annotations
        labels      = local.components.periodic_scheduler.labels
      }

      spec {
        service_account_name = local.service_account

        security_context {
          fs_group = 1000

          seccomp_profile {
            type = "RuntimeDefault"
          }
        }

        container {
          name  = "management-server"
          image = local.image

          security_context {
            capabilities {
              drop = ["ALL"]
            }

            run_as_user                = 10000
            run_as_non_root            = true
            read_only_root_filesystem  = true
            allow_privilege_escalation = false
          }

          resources {
            requests = {
              "cpu"    = "250m"
              "memory" = "256Mi"
            }
            limits = local.components.periodic_scheduler.resources.limits
          }

          volume_mount {
            name       = "secret"
            mount_path = "/etc/app"
            read_only  = true
          }

          volume_mount {
            name       = "tmpfs"
            mount_path = "/tmp"
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map.config.metadata[0].name
            }
          }

          dynamic "env" {
            for_each = nonsensitive(keys(kubernetes_secret.sensitive_config.data))

            content {
              name  = "${env.value}_FILE"
              value = "/etc/app/${env.value}"
            }
          }

          port {
            name           = "http"
            protocol       = "TCP"
            container_port = 8000
          }

          command = ["start-celery-beat.sh"]

          liveness_probe {
            initial_delay_seconds = 15
            period_seconds        = 15
            timeout_seconds       = 5
            failure_threshold     = 3

            exec {
              command = ["/bin/sh", "-c", "poetry run celery -A config.celery_app status --timeout 3 | grep 'celery@.*: OK'"]
            }
          }
        }

        volume {
          name = "secret"

          secret {
            secret_name = kubernetes_secret.sensitive_config.metadata[0].name
          }
        }

        volume {
          name = "tmpfs"

          empty_dir {}
        }
      }
    }
  }
}

# TODO: Ensure this job run every time when change occurs in related things or condition (every apply or changes in server app, etc.)
# TODO: May run other initializer tasks (such as collecting static files, creating superuser, etc.)
resource "kubernetes_job" "init" {
  timeouts {
    create = "3m"
    update = "3m"
  }

  wait_for_completion = true

  metadata {
    namespace   = local.namespace
    name        = "${local.common.name}-init"
    annotations = local.common.annotations
    labels      = local.common.labels
  }

  spec {
    template {
      metadata {
        annotations = local.components.management_server.annotations
        labels      = local.components.management_server.labels
      }

      spec {
        service_account_name = local.service_account

        container {
          name  = "migrate"
          image = local.image

          volume_mount {
            name       = "secret"
            mount_path = "/etc/app"
            read_only  = true
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map.config.metadata[0].name
            }
          }

          dynamic "env" {
            for_each = nonsensitive(keys(kubernetes_secret.sensitive_config.data))

            content {
              name  = "${env.value}_FILE"
              value = "/etc/app/${env.value}"
            }
          }

          command = ["/bin/sh", "-c", "poetry run python manage.py migrate"]

          readiness_probe {
            initial_delay_seconds = 5
            period_seconds        = 15
            failure_threshold     = 10

            exec {
              # TODO: Better way doing db health checks?
              command = [
                "/bin/sh",
                "-c",
                <<-EOT
                  poetry run python <<EOF
                  import os, sys, psycopg2
                  try:
                    conn = psycopg2.connect(os.environ.get("DATABASE_URL"))
                    conn.close()
                    sys.exit(0)
                  except:
                    sys.exit(1)
                  EOF
                EOT
              ]
            }
          }
        }

        volume {
          name = "secret"

          secret {
            secret_name = kubernetes_secret.sensitive_config.metadata[0].name
          }
        }

        restart_policy = "OnFailure"
      }
    }
    backoff_limit = 10
  }
}

resource "kubernetes_service" "default" {
  metadata {
    namespace   = local.namespace
    name        = local.common.name
    annotations = local.common.annotations
    labels      = local.common.labels
  }

  spec {
    type     = var.service.type
    selector = local.components.management_server.selector_labels

    port {
      protocol    = "TCP"
      port        = var.service.port
      target_port = "http"
    }
  }
}
