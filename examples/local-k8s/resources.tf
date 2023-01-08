resource "kubernetes_namespace" "current" {
  metadata {
    name = var.namespace
  }
}

module "management_server" {
  source = "../../modules/management-server"
  depends_on = [
    local.namespace
  ]

  namespace = {
    name = local.namespace
  }

  config = {
    crawler_url = ""
  }

  extra_config = {
    DJANGO_SECURE_SSL_REDIRECT = "False"
  }
}

resource "helm_release" "nginx_ingress_controller" {
  # BUG: Facing "502 Bad Gateway" error from NGINX ingress intermittently.
  #      It gets fixed once recreate controller manually or wait for dependent applications to be ready before create.
  depends_on = [module.management_server]

  name             = "nginx-ingress-controller"
  repository       = "https://helm.nginx.com/stable"
  chart            = "nginx-ingress"
  version          = "0.15.2"
  atomic           = true
  namespace        = local.namespace
  create_namespace = false
}

# TODO: TLS support with cert-manager
resource "kubernetes_ingress_v1" "default" {
  depends_on = [helm_release.nginx_ingress_controller]

  metadata {
    namespace = var.namespace
    name      = "default"
  }

  spec {
    ingress_class_name = "nginx"

    rule {
      host = "kkowa-127-0-0-1.nip.io"

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = module.management_server.service.name

              port {
                number = module.management_server.service.port
              }
            }
          }
        }
      }
    }
  }
}
