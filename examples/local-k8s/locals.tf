locals {
  namespace = kubernetes_namespace.current.metadata[0].name
}
