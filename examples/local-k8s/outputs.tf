output "ingress" {
  value = {
    # HTTP base URL.
    http = "http://${kubernetes_ingress_v1.default.spec[0].rule[0].host}"

    # HTTPS base URL.
    https = "https://${kubernetes_ingress_v1.default.spec[0].rule[0].host}"
  }
  description = "Ingress URLs for access."
}
