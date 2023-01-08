output "service" {
  value = {
    # Name of the service.
    name = kubernetes_service.default.metadata[0].name

    # Type of the service.
    type = kubernetes_service.default.spec[0].type

    # Port of service.
    port = kubernetes_service.default.spec[0].port[0].port
  }
  description = "Application service detail."
}
