terraform {
  required_providers {
    fastly = {
      source  = "fastly/fastly"
      version = "2.2.1"
    }
  }
  required_version = "~> 1.0.0"
}

resource "fastly_service_acl_entries" "entries" {
  for_each       = { for acl in fastly_service_vcl.service.acl : acl.name => acl }
  acl_id         = each.value.acl_id
  service_id     = fastly_service_vcl.service.id
  manage_entries = !contains(var.unmanaged_acls, each.value.name)

  dynamic "entry" {
    for_each = { for entry in local.entries[each.value.name] : entry.ip => entry }

    content {
      ip      = entry.value.ip
      comment = entry.value.comment
      subnet  = entry.value.subnet
    }
  }
}

resource "fastly_service_vcl" "service" {
  default_ttl        = var.default_ttl
  name               = var.service_name
  stale_if_error     = var.stale_if_error
  stale_if_error_ttl = var.stale_if_error_ttl
  default_host       = var.default_host
  version_comment    = var.version_comment

  dynamic "acl" {
    for_each = var.acls
    content {
      name = acl.value.name
    }
  }

  dynamic "backend" {
    for_each = var.backends
    content {
      address               = lookup(backend.value, "address", "")
      auto_loadbalance      = lookup(backend.value, "auto_loadbalance", false)
      between_bytes_timeout = lookup(backend.value, "between_bytes_timeout", 10000)
      connect_timeout       = lookup(backend.value, "connect_timeout", 1000)
      error_threshold       = lookup(backend.value, "error_threshold", 0)
      first_byte_timeout    = lookup(backend.value, "first_byte_timeout", 15000)
      healthcheck           = lookup(backend.value, "healthcheck", null)
      max_conn              = lookup(backend.value, "max_conn", 400)
      name                  = lookup(backend.value, "name", "")
      port                  = lookup(backend.value, "port", 443)
      shield                = lookup(backend.value, "shield", "chi-il-us")
      request_condition     = lookup(backend.value, "request_condition", "")
      ssl_cert_hostname     = lookup(backend.value, "ssl_cert_hostname", "*.food.com")
      ssl_check_cert        = lookup(backend.value, "ssl_check_cert", true)
      ssl_sni_hostname      = lookup(backend.value, "ssl_sni_hostname", "")
      use_ssl               = lookup(backend.value, "use_ssl", true)
      weight                = lookup(backend.value, "weight", 100)
    }
  }

  cache_setting {
    action          = var.action
    cache_condition = var.cache_condition
    name            = var.cach_name
    stale_ttl       = var.stale_ttl
    ttl             = var.ttl
  }

  dynamic "condition" {
    for_each = var.conditions
    content {
      name      = lookup(condition.value, "name", "Cache-Control")
      priority  = lookup(condition.value, "priority", 10)
      statement = lookup(condition.value, "statement", "!beresp.http.Cache-Control ~ \"(public)\"")
      type      = lookup(condition.value, "type", "CACHE")
    }
  }

  dynamic "domain" {
    for_each = var.domains
    content {
      name = domain.value.name
    }
  }

  gzip {
    content_types = var.gzip_content
    extensions    = var.gzip_extensions
    name          = var.gzip_name
  }

  dynamic "snippet" {
    for_each = var.snippets
    content {
      content  = snippet.value.content
      name     = snippet.value.name
      priority = snippet.value.priority
      type     = snippet.value.type
    }
  }

  dynamic "vcl" {
    for_each = var.vcl_configs
    content {
      content = vcl.value.content
      name    = vcl.value.name
      main    = vcl.value.main
    }
  }

  dynamic "dictionary" {
    for_each = var.dictionaries
    content {
      name = dictionary.value.name
    }
  }

  dynamic "logging_bigquery" {
    for_each = var.bigquerylogging_configs
    content {
      dataset    = lookup(logging_bigquery.value, "dataset", "fastly_logging")
      email      = lookup(logging_bigquery.value, "email", "")
      format     = lookup(logging_bigquery.value, "format", file("${path.module}/files/logging/bigquery_lem_format.txt"))
      name       = lookup(logging_bigquery.value, "name", "BigQueryLogging")
      project_id = lookup(logging_bigquery.value, "project_id", "i-gcp-project")
      secret_key = lookup(logging_bigquery.value, "secret_key", "")
      table      = lookup(logging_bigquery.value, "table", "")
    }
  }

  dynamic "logging_kafka" {
    for_each = var.kafkalogging_configs
    content {
      brokers            = lookup(logging_kafka.value, "brokers", "")
      name               = lookup(logging_kafka.value, "name", "")
      topic              = lookup(logging_kafka.value, "topic", "")
      auth_method        = lookup(logging_kafka.value, "auth_method", "")
      compression_codec  = lookup(logging_kafka.value, "compression_codec", "")
      format             = lookup(logging_kafka.value, "format", "")
      format_version     = lookup(logging_kafka.value, "format_version", 2)
      parse_log_keyvals  = lookup(logging_kafka.value, "parse_log_keyvals", true)
      password           = lookup(logging_kafka.value, "password", "")
      request_max_bytes  = lookup(logging_kafka.value, "request_max_bytes", 0)
      required_acks      = lookup(logging_kafka.value, "required_acks", 1)
      response_condition = lookup(logging_kafka.value, "response_condition", "")
      tls_ca_cert        = lookup(logging_kafka.value, "tls_ca_cert", "")
      tls_client_cert    = lookup(logging_kafka.value, "tls_client_cert", "")
      tls_client_key     = lookup(logging_kafka.value, "tls_client_key", "")
      tls_hostname       = lookup(logging_kafka.value, "tls_hostname", "")
      use_tls            = lookup(logging_kafka.value, "use_tls", true)
      user               = lookup(logging_kafka.value, "user", "")
    }
  }

  dynamic "logging_gcs" {
    for_each = var.gcslogging_configs
    content {
      bucket_name        = lookup(logging_gcs.value, "bucket_name", "")
      name               = lookup(logging_gcs.value, "name", "")
      compression_codec  = lookup(logging_gcs.value, "compression_codec", "gzip")
      format             = lookup(logging_gcs.value, "format", "")
      format_version     = lookup(logging_gcs.value, "format_version", 2)
      message_type       = lookup(logging_gcs.value, "message_type", "classic")
      path               = lookup(logging_gcs.value, "path", "")
      period             = lookup(logging_gcs.value, "period", 3600)
      response_condition = lookup(logging_gcs.value, "response_condition", "")
      secret_key         = lookup(logging_gcs.value, "secret_key", "")
      timestamp_format   = lookup(logging_gcs.value, "timestamp_format", "%Y-%m-%dT%H:%M:%S.000")
      user               = lookup(logging_gcs.value, "user", "")
      placement          = lookup(logging_gcs.value, "placement", null)
    }
  }

  dynamic "logging_s3" {
    for_each = var.s3logging_configs
    content {
      bucket_name        = lookup(logging_s3.value, "bucket_name", "")
      name               = lookup(logging_s3.value, "name", "")
      acl                = lookup(logging_s3.value, "acl", "private")
      compression_codec  = lookup(logging_s3.value, "compression_codec", "gzip")
      domain             = lookup(logging_s3.value, "domain", "")
      format_version     = lookup(logging_s3.value, "format_version", 2)
      format             = lookup(logging_s3.value, "format", "")
      message_type       = lookup(logging_s3.value, "message_type", "blank")
      path               = lookup(logging_s3.value, "path", "")
      period             = lookup(logging_s3.value, "period", 15)
      placement          = lookup(logging_s3.value, "placement", null)
      public_key         = lookup(logging_s3.value, "public_key", "")
      redundancy         = lookup(logging_s3.value, "redundancy", "standard")
      response_condition = lookup(logging_s3.value, "response_condition", "")
      s3_access_key      = lookup(logging_s3.value, "s3_access_key", "")
      s3_iam_role        = lookup(logging_s3.value, "s3_iam_role", "")
      s3_secret_key      = lookup(logging_s3.value, "s3_secret_key", "")
      timestamp_format   = lookup(logging_s3.value, "timestamp_format", "%Y-%m-%dT%H:%M:%S.000")
    }
  }

  dynamic "healthcheck" {
    for_each = var.healthchecks
    content {
      check_interval    = lookup(healthcheck.value, "check_interval", 5000)
      expected_response = lookup(healthcheck.value, "expected_response", 200)
      host              = lookup(healthcheck.value, "host", "")
      http_version      = lookup(healthcheck.value, "http_version", "1.1")
      initial           = lookup(healthcheck.value, "initial", 1)
      method            = lookup(healthcheck.value, "method", "GET")
      name              = lookup(healthcheck.value, "name", "origin-health-check")
      path              = lookup(healthcheck.value, "path", "/varnish-health-check")
      threshold         = lookup(healthcheck.value, "threshold", 1)
      timeout           = lookup(healthcheck.value, "timeout", 5000)
      window            = lookup(healthcheck.value, "window", 2)
    }
  }

  dynamic "response_object" {
    for_each = var.response_objects
    content {
      name              = lookup(response_object.value, "name", "")
      status            = lookup(response_object.value, "status", "200")
      response          = lookup(response_object.value, "response", "")
      content_type      = lookup(response_object.value, "content_type", "text/html")
      content           = lookup(response_object.value, "content", "")
      request_condition = lookup(response_object.value, "request_condition", "")
      cache_condition   = lookup(response_object.value, "cache_condition", "")
    }
  }
}
