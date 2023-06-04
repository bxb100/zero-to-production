terraform {
  # using terraform cloud setting
  cloud {
    organization = "xb"

    workspaces {
      name = "zero2prod"
    }
  }
  required_providers {
    # temporary using fork of fly provider, just for test using
    # https://github.com/fly-apps/terraform-provider-fly/pull/106#issuecomment-1501199345
    fly = {
      source  = "floydspace/fly"
      version = "0.2.0"
    }
    neon = {
      source  = "terraform-community-providers/neon"
      version = "0.1.2"
    }
  }
}

variable "app_name" {
  default     = "zero2pro"
  description = "The name of the app, using both neon and fly"
  type        = string
}

# NEON_API_KEY
provider "neon" {}

resource "neon_project" "this" {
  name      = var.app_name
  region_id = "aws-us-west-2"
  branch = {
    name = "main"
  }
}

resource "neon_role" "this" {
  project_id = neon_project.this.id
  branch_id  = neon_project.this.branch.id
  name       = "tf_role"
  lifecycle {
    ignore_changes = all
  }
}

resource "neon_database" "this" {
  name       = "newsletter"
  owner_name = neon_role.this.name
  branch_id  = neon_project.this.branch.id
  project_id = neon_project.this.id
}

# FLY_API_TOKEN
provider "fly" {
  useinternaltunnel    = true
  internaltunnelorg    = "personal"
  internaltunnelregion = "fra"
}

resource "fly_app" "this" {
  name = var.app_name
  org  = "personal"
  secrets = {
    APP_DATABASE__HOST = {
      value = neon_project.this.branch.endpoint.host
    }
    APP_DATABASE__USERNAME = {
      value = neon_role.this.name
    }
    APP_DATABASE__PASSWORD = {
      value = neon_role.this.password
    }
    APP_DATABASE__DATABASE_NAME = {
      value = neon_database.this.name
    }
    DATABASE_URL = {
      value = "postgres://${neon_role.this.name}:${neon_role.this.password}@${neon_project.this.branch.endpoint.host}/${neon_database.this.name}"
    }
  }
  lifecycle {
    ignore_changes = [secrets["APP_DATABASE__PASSWORD"], secrets["DATABASE_URL"]]
  }

  provisioner "local-exec" {
    command = "echo 'DATABASE_URL=${self.secrets["DATABASE_URL"].value}' >> .prod.env"
  }
  provisioner "local-exec" {
    when    = destroy
    command = "sed -i '' '/DATABASE_URL/d' .prod.env"
  }
}

output "postgres_uri" {
  value       = "postgres://${neon_role.this.name}:${neon_role.this.password}@${neon_project.this.branch.endpoint.host}/${neon_database.this.name}"
  description = "the neon password only show once"
  sensitive   = true
  depends_on  = [fly_app.this]
}
