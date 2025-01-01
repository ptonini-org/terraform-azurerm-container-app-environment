variable "name" {}

variable "rg" {
  type = object({
    name     = string
    location = string
  })
}

variable "infrastructure_subnet_id" {
  default = null
}

variable "internal_load_balancer_enabled" {
  default = null
}

variable "zone_redundancy_enabled" {
  default = null
}

variable "log_analytics_workspace_id" {
  default = null
}

variable "workload_profiles" {
  type = map(object({
    workload_profile_type = string
    maximum_count         = number
    minimum_count         = number
  }))
  default  = {}
  nullable = false
}

variable "storage_shares" {
  type = map(object({
    name         = optional(string)
    share_name   = optional(string)
    account_name = string
    access_key   = string
    access_mode  = optional(string, "ReadWrite")
  }))
  default  = {}
  nullable = false
}

variable "apps" {
  type = map(object({
    revision_mode         = optional(string, "Single")
    workload_profile_name = optional(string)
    template = object({
      max_replicas = optional(number, 1)
      min_replicas = optional(number, 1)
      containers = map(object({
        name    = optional(string)
        image   = string
        cpu     = optional(string, "0.25")
        memory  = optional(string, "0.5Gi")
        args    = optional(list(string))
        command = optional(list(string))
        env = optional(map(object({
          secret_name = optional(string)
          value       = optional(string)
        })))
        liveness_probe = optional(object({
          transport               = optional(string, "HTTP")
          port                    = number
          path                    = optional(string)
          failure_count_threshold = optional(number)
          initial_delay           = optional(number)
          interval_seconds        = optional(number)
        }))
        volume_mounts = optional(map(string), {})
      }))
      volumes = optional(map(object({
        name         = optional(string)
        storage_name = optional(string)
        storage_type = string
      })), {})
    })
    secrets = optional(map(string), {})
    identity = optional(object({
      type         = optional(string, "SystemAssigned")
      identity_ids = optional(set(string))
    }), {})
    ingress = optional(object({
      target_port                = number
      exposed_port               = optional(number)
      allow_insecure_connections = optional(bool)
      external_enabled           = optional(bool)
      transport                  = optional(string)
      custom_domain = optional(object({
        name                     = string
        certificate_id           = string
        certificate_binding_type = optional(string)
      }))
      traffic_weight = optional(map(object({
        percentage      = number
        latest_revision = optional(bool, true)
        revision_suffix = optional(string)
      })), { default = { percentage = 100 } })
    }))
    registry = optional(object({
      server               = string
      identity             = optional(string)
      username             = optional(string)
      password_secret_name = optional(string)
    }))
    tags = optional(map(string))
  }))
  default  = {}
  nullable = false
}

variable "tags" {
  type     = map(string)
  default  = {}
  nullable = false
}