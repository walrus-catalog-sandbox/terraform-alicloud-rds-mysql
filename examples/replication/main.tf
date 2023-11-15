terraform {
  required_version = ">= 1.0"

  required_providers {
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.1"
    }
    alicloud = {
      source  = "aliyun/alicloud"
      version = ">= 1.212.0"
    }
  }
}

provider "alicloud" {}

locals {
  category       = "HighAvailability"
  engine         = "MySQL"
  engine_version = "8.0"
  resources = {
    class          = "rds.mysql.s2.large"
    readonly_class = "rds.mysql.s2.large"
  }
  storage = {
    class = "local_ssd"
  }
}

data "alicloud_db_zones" "selected" {
  category                 = local.category
  engine                   = local.engine
  engine_version           = local.engine_version
  db_instance_class        = local.resources.class
  db_instance_storage_type = local.storage.class

  lifecycle {
    postcondition {
      condition     = length(toset(flatten([self.ids]))) > 1
      error_message = "Failed to get Avaialbe Zones"
    }
  }
}

# create vpc.

resource "alicloud_vpc" "example" {
  vpc_name    = "example"
  cidr_block  = "10.0.0.0/16"
  description = "example"
}

resource "alicloud_vswitch" "example" {
  for_each = {
    for i, c in data.alicloud_db_zones.selected.ids : c => cidrsubnet(alicloud_vpc.example.cidr_block, 8, i)
  }

  vpc_id      = alicloud_vpc.example.id
  zone_id     = each.key
  cidr_block  = each.value
  description = "example"
}

# create private dns.

data "alicloud_pvtz_service" "selected" {
  enable = "On"
}

resource "alicloud_pvtz_zone" "example" {
  zone_name = "my-dev-dns"

  depends_on = [data.alicloud_pvtz_service.selected]
}

resource "alicloud_pvtz_zone_attachment" "example" {
  zone_id = alicloud_pvtz_zone.example.id
  vpc_ids = [alicloud_vpc.example.id]
}

# create mysql service.

module "this" {
  source = "../.."

  infrastructure = {
    vpc_id        = alicloud_vpc.example.id
    domain_suffix = alicloud_pvtz_zone.example.zone_name
  }

  architecture                  = "replication"
  replication_readonly_replicas = 3
  resources                     = local.resources
  storage                       = local.storage

  depends_on = [alicloud_pvtz_zone.example]
}

output "context" {
  value = module.this.context
}

output "selector" {
  value = module.this.selector
}

output "endpoint_internal" {
  value = module.this.endpoint_internal
}

output "endpoint_internal_readonly" {
  value = module.this.endpoint_internal_readonly
}

output "database" {
  value = module.this.database
}

output "username" {
  value = module.this.username
}

output "password" {
  value = nonsensitive(module.this.password)
}
