# local-k8s

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
# examples/local-k8s

Simple example deploying kkowa to local kubernetes cluster.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.3.6 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 2.8.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.16.1 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.4.3 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | 2.8.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 2.16.1 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_management_server"></a> [management\_server](#module\_management\_server) | ../../modules/management-server | n/a |

## Resources

| Name | Type |
|------|------|
| [helm_release.nginx_ingress_controller](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_ingress_v1.default](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/ingress_v1) | resource |
| [kubernetes_namespace.current](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_kubernetes"></a> [kubernetes](#input\_kubernetes) | Kubernetes cluster configuration for providers to access the cluster.<br><br>For local cluster running via Docker Desktop, check file `~/.kube/config`. | <pre>object({<br>    # Cluster host address.<br>    host = string<br><br>    # Base64 encoded string of client certificate.<br>    client_certificate = string<br><br>    # Base64 encoded string of client key.<br>    client_key = string<br>  })</pre> | n/a | yes |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | The namespace to create resources at. | `string` | `"kkowa"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ingress"></a> [ingress](#output\_ingress) | Ingress URLs for access. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
