resource "azurerm_container_app_environment" "this" {
  name                           = var.name
  location                       = var.rg.location
  resource_group_name            = var.rg.name
  log_analytics_workspace_id     = var.log_analytics_workspace_id
  infrastructure_subnet_id       = var.infrastructure_subnet_id
  internal_load_balancer_enabled = var.internal_load_balancer_enabled
  zone_redundancy_enabled        = var.zone_redundancy_enabled
  tags                           = var.tags

  dynamic "workload_profile" {
    for_each = var.workload_profiles
    content {
      name                  = workload_profile.key
      workload_profile_type = workload_profile.value.workload_profile_type
      maximum_count         = workload_profile.value.maximum_count
      minimum_count         = workload_profile.value.minimum_count
    }
  }

  lifecycle {
    ignore_changes = [
      tags["business_unit"],
      tags["environment"],
      tags["environment_finops"],
      tags["product"],
      tags["subscription_type"]
    ]
  }
}

resource "azurerm_container_app_environment_storage" "this" {
  for_each                     = var.storage_shares
  name                         = coalesce(each.value.name, each.key)
  container_app_environment_id = azurerm_container_app_environment.this.id
  account_name                 = each.value.account_name
  share_name                   = coalesce(each.value.share_name, each.key)
  access_key                   = each.value.access_key
  access_mode                  = each.value.access_mode
}

resource "azurerm_container_app" "this" {
  for_each                     = var.apps
  name                         = each.key
  container_app_environment_id = azurerm_container_app_environment.this.id
  resource_group_name          = azurerm_container_app_environment.this.resource_group_name
  revision_mode                = each.value.revision_mode
  tags                         = each.value.tags

  dynamic "identity" {
    for_each = each.value.identity[*]
    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }

  template {
    max_replicas = each.value.template.max_replicas
    min_replicas = each.value.template.min_replicas

    dynamic "container" {
      for_each = each.value.template.containers
      content {
        name    = coalesce(container.value.name, container.key)
        image   = container.value.image
        cpu     = container.value.cpu
        memory  = container.value.memory
        args    = container.value.args
        command = container.value.command

        dynamic "env" {
          for_each = container.value.env
          content {
            name        = env.key
            secret_name = env.value.secret_name
            value       = env.value.value
          }
        }

        dynamic "liveness_probe" {
          for_each = container.value.liveness_probe[*]
          content {
            transport               = liveness_probe.value.transport
            port                    = liveness_probe.value.port
            path                    = liveness_probe.value.path
            failure_count_threshold = liveness_probe.value.failure_count_threshold
            initial_delay           = liveness_probe.value.initial_delay
            interval_seconds        = liveness_probe.value.interval_seconds
          }
        }

        dynamic "volume_mounts" {
          for_each = container.value.volume_mounts
          content {
            name = volume_mounts.key
            path = volume_mounts.value
          }
        }
      }
    }

    dynamic "volume" {
      for_each = each.value.template.volumes
      content {
        name         = coalesce(volume.value.name, volume.key)
        storage_name = coalesce(volume.value.storage_name, volume.key)
        storage_type = volume.value.storage_type
      }
    }
  }

  dynamic "secret" {
    for_each = each.value.secrets
    content {
      name  = secret.key
      value = secret.value
    }
  }

  dynamic "ingress" {
    for_each = each.value.ingress[*]
    content {
      target_port                = ingress.value.target_port
      exposed_port               = ingress.value.exposed_port
      external_enabled           = ingress.value.external_enabled
      allow_insecure_connections = ingress.value.allow_insecure_connections
      transport                  = ingress.value.transport

      dynamic "custom_domain" {
        for_each = ingress.value.custom_domain[*]
        content {
          name                     = custom_domain.value.name
          certificate_id           = custom_domain.value.certificate_id
          certificate_binding_type = custom_domain.value.certificate_binding_type
        }
      }

      dynamic "traffic_weight" {
        for_each = ingress.value.traffic_weight
        content {
          label           = traffic_weight.key
          percentage      = traffic_weight.value.percentage
          latest_revision = traffic_weight.value.latest_revision
          revision_suffix = traffic_weight.value.revision_suffix
        }
      }
    }
  }

  dynamic "registry" {
    for_each = each.value.registry[*]
    content {
      server               = registry.value.server
      identity             = registry.value.identity
      username             = registry.value.username
      password_secret_name = registry.value.password_secret_name
    }
  }

  lifecycle {
    ignore_changes = [
      tags["business_unit"],
      tags["environment"],
      tags["environment_finops"],
      tags["product"],
      tags["subscription_type"]
    ]
  }
}