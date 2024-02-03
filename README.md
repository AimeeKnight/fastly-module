# fastly-service
Fastly service 0.36.0 terraform module

Requires terraform 1.0.0

# Example usage

```
terraform {
  backend "gcs" {}
  required_providers {
    fastly = {
      source  = "fastly/fastly"
      version = "2.2.1"
    }
  }
  required_version = "~> 1.0.0"
}

data "google_secret_manager_secret_version" "api-token" {
  secret  = "fastly-api"
  project = "i-gcp-project"
}

data "google_secret_manager_secret_version" "bigquery-logging-email" {
  secret  = "fastly-bigquery-logging-email"
  project = "i-gcp-project"
}

data "google_secret_manager_secret_version" "bigquery-logging-key" {
  secret  = "fastly-bigquery-logging-key"
  project = "i-gcp-project"
}

provider "fastly" {
  api_key = data.google_secret_manager_secret_version.api-token.secret_data
}

module "stage2_us_fastly_service" {
  source       = "git@github.com:path-to-tf-modules/fastly-service.git?ref=release/1.0"

  service_name = "Foo | www2.stage.us.foo.com"

  domains = [
    { name = "www2.stage.us.foo.com" },
  ]
  
  unmanaged_acls = [] # OPTIONAL to create unmanaged acl, list the names of the acls you want to manage outside terraform, if empty or not defined creates standard managed by terraform acls

  acls = [
    {
      name = "us_override"
      entries = [
        {
          ip      = "2a03:fc02:3::"
          comment = "JIRA-2787"
          subnet  = 48
        },
        {
          ip      = "32a03:fc02:4::"
          comment = "JIRA-2787"
          subnet  = 48
        }
      ]
    },
    {
      name = "mx_override"
      entries = [
        {
          ip      = "42a03:fc02:5::"
          comment = "JIRA-2787"
          subnet  = 48
        },
        {
          ip      = "532a03:fc02:6::"
          comment = "JIRA-2787"
          subnet  = 48
        }
      ]
    },
  ]

  backends = [
    {
      address           = "origin-usc1.stage.us.foo.com"
      auto_loadbalance  = true
      healthcheck       = "intl-origin-health-check"
      name              = "origin-usc1.stage.us.foo.com"
      ssl_cert_hostname = "*.stage.us.foo.com"
      ssl_sni_hostname  = "origin-usc1.stage.us.foo.com"
      weight            = 50
    }
  ]

  snippets = [
    {
      content  = templatefile("${path.module}/../files/vcl_snippets/apex_to_www.tpl", { apex = "stage.us.foo.com" })
      name     = "apex_to_www"
      priority = 10
      type     = "recv"
    }
  ]

  healthchecks = [
    {
      host = "stage.us.foo.com"
      name = "intl-origin-health-check"
    }
  ]

  conditions = [
    {
      name      = "Foo Domain"
      priority  = 10
      statement = "req.http.host == \"foo.com\""
      type      = "REQUEST"
    }
  ]
}

```
