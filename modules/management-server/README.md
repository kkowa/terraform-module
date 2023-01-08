# management-server

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
# modules/management-server

Module for [kkowa/management-server](https://github.com/kkowa/management-server) application.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.3.6 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | 2.8.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.16.1 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.4.3 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | 2.8.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 2.16.1 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.4.3 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.cache](https://registry.terraform.io/providers/hashicorp/helm/2.8.0/docs/resources/release) | resource |
| [helm_release.database](https://registry.terraform.io/providers/hashicorp/helm/2.8.0/docs/resources/release) | resource |
| [helm_release.message_broker](https://registry.terraform.io/providers/hashicorp/helm/2.8.0/docs/resources/release) | resource |
| [kubernetes_config_map.config](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_default_service_account.default](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/default_service_account) | resource |
| [kubernetes_deployment.management_server](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/deployment) | resource |
| [kubernetes_deployment.periodic_scheduler](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/deployment) | resource |
| [kubernetes_deployment.worker](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/deployment) | resource |
| [kubernetes_job.init](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/job) | resource |
| [kubernetes_namespace.created](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_secret.sensitive_config](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_service.default](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service) | resource |
| [kubernetes_service_account.created](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_account) | resource |
| [random_string.django_secret_key](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [random_string.instance_id](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [kubernetes_namespace.existing](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/namespace) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_common"></a> [common](#input\_common) | Common configuration that affects overall resources. | <pre>object({<br>    # Name for created resources. Some resources may use this as prefix.<br>    name = optional(string, "kkowa-management-server")<br><br>    # Common annotations for all resources.<br>    annotations = optional(map(string), {})<br><br>    # Common labels for all resources.<br>    labels = optional(map(string), {})<br>  })</pre> | `{}` | no |
| <a name="input_components"></a> [components](#input\_components) | Customizable options for components. | <pre>object({<br>    management_server = object({<br>      # Component-specific annotations, adding to common annotations.<br>      annotations = optional(map(string), {})<br><br>      # Component-specific labels, adding to common labels.<br>      labels = optional(map(string), {})<br><br>      # Number of replicas to be created for component.<br>      replicas = optional(number, 1)<br><br>      # Resources quota<br>      resources = object({<br>        limits = map(string)<br>      })<br>    })<br>    worker = object({<br>      # Component-specific annotations, adding to common annotations.<br>      annotations = optional(map(string), {})<br><br>      # Component-specific labels, adding to common labels.<br>      labels = optional(map(string), {})<br><br>      # Number of replicas to be created for component.<br>      replicas = optional(number, 1)<br><br>      # Resources quota<br>      resources = object({<br>        limits = map(string)<br>      })<br>    })<br>    periodic_scheduler = object({<br>      # Component-specific annotations, adding to common annotations.<br>      annotations = optional(map(string), {})<br><br>      # Component-specific labels, adding to common labels.<br>      labels = optional(map(string), {})<br><br>      # Number of replicas to be created for component.<br>      replicas = optional(number, 1)<br><br>      # Resources quota<br>      resources = object({<br>        limits = map(string)<br>      })<br>    })<br>  })</pre> | <pre>{<br>  "management_server": {<br>    "resources": {<br>      "limits": {<br>        "cpu": "500m",<br>        "memory": "1Gi"<br>      }<br>    }<br>  },<br>  "periodic_scheduler": {<br>    "resources": {<br>      "limits": {<br>        "cpu": "500m",<br>        "memory": "1Gi"<br>      }<br>    }<br>  },<br>  "worker": {<br>    "resources": {<br>      "limits": {<br>        "cpu": "500m",<br>        "memory": "1Gi"<br>      }<br>    }<br>  }<br>}</pre> | no |
| <a name="input_config"></a> [config](#input\_config) | Application configurations. | <pre>object({<br>    # kkowa's crawler gRPC endpoint URL.<br>    crawler_url = string<br>  })</pre> | n/a | yes |
| <a name="input_extra_config"></a> [extra\_config](#input\_extra\_config) | Extra application config to pass. May override existing items if key duplicates. | `map(string)` | `{}` | no |
| <a name="input_extra_sensitive_config"></a> [extra\_sensitive\_config](#input\_extra\_sensitive\_config) | Extra sensitive application config to pass. May override existing items if key duplicates. | `map(string)` | `{}` | no |
| <a name="input_image"></a> [image](#input\_image) | The application image to use to create containers. All pods created by deployment or job uses this. | <pre>object({<br>    # Image's repository.<br>    repository = optional(string, "ghcr.io/kkowa/management-server")<br><br>    # Tag of the image.<br>    tag = optional(string, "main")<br>  })</pre> | `{}` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | The namespace where resources created. | <pre>object({<br>    # Namespace's name to use or create.<br>    name = optional(string, "default")<br><br>    # Whether to create the namespace or not.<br>    create = optional(bool, false)<br>  })</pre> | `{}` | no |
| <a name="input_sensitive_config"></a> [sensitive\_config](#input\_sensitive\_config) | Sensitive application configurations. | <pre>object({<br>    # Django secret key used for cryptographic signing. Automatically generated if not specified.<br>    secret_key = optional(string)<br><br>    # PostgreSQL database URL. If not set, an chart release for this will be created.<br>    database_url = optional(string)<br><br>    # Redis cache URL. If not set, an chart release for this will be created.<br>    cache_url = optional(string)<br><br>    # RabbitMQ message broker URL for Celery. If not set, an chart release for this will be created.<br>    message_broker_url = optional(string)<br>  })</pre> | `{}` | no |
| <a name="input_service"></a> [service](#input\_service) | The service for application. | <pre>object({<br>    type = optional(string, "NodePort")<br>    port = optional(number, 8000)<br>  })</pre> | `{}` | no |
| <a name="input_service_account"></a> [service\_account](#input\_service\_account) | The service account for created workloads. | <pre>object({<br>    # Name of service account to use or create.<br>    name = optional(string, "default")<br><br>    # Whether to create the service account or not.<br>    create = optional(bool, false)<br>  })</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_service"></a> [service](#output\_service) | Application service detail. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
