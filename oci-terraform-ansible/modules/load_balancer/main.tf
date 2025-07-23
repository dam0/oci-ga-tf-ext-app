# Load Balancer Module - Creates a load balancer for Tomcat instances

# Create a load balancer
resource "oci_load_balancer_load_balancer" "lb" {
  compartment_id = var.compartment_id
  display_name   = "${var.name_prefix}-tomcat-lb"
  shape          = var.lb_shape
  subnet_ids     = var.subnet_ids
  is_private     = var.is_private

  dynamic "shape_details" {
    for_each = var.lb_shape == "flexible" ? [1] : []
    content {
      minimum_bandwidth_in_mbps = var.lb_min_shape_bandwidth_mbps
      maximum_bandwidth_in_mbps = var.lb_max_shape_bandwidth_mbps
    }
  }

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

# Create a backend set for Tomcat servers
resource "oci_load_balancer_backend_set" "tomcat_backend_set" {
  load_balancer_id = oci_load_balancer_load_balancer.lb.id
  name             = var.backend_set_name
  policy           = var.backend_policy

  health_checker {
    protocol            = "HTTP"
    port                = var.tomcat_port
    url_path            = var.health_check_url_path
    return_code         = var.health_check_return_code
    interval_ms         = var.health_check_interval_ms
    timeout_in_millis   = var.health_check_timeout_ms
    retries             = var.health_check_retries
  }

  session_persistence_configuration {
    cookie_name      = var.session_cookie_name
    disable_fallback = var.disable_session_fallback
  }
}

# Add backends for each private instance
resource "oci_load_balancer_backend" "tomcat_backends" {
  count            = length(var.backend_servers)
  load_balancer_id = oci_load_balancer_load_balancer.lb.id
  backendset_name  = oci_load_balancer_backend_set.tomcat_backend_set.name
  ip_address       = var.backend_servers[count.index].ip_address
  port             = var.tomcat_port
  backup           = var.backend_servers[count.index].backup
  drain            = var.backend_servers[count.index].drain
  offline          = var.backend_servers[count.index].offline
  weight           = var.backend_servers[count.index].weight
}

# Note: Using existing certificate OCID instead of creating new certificate
# The certificate OCID is provided via variable: var.certificate_ocid

# Create a rule set for HTTP to HTTPS redirect
resource "oci_load_balancer_rule_set" "http_to_https_redirect" {
  load_balancer_id = oci_load_balancer_load_balancer.lb.id
  name             = "${var.name_prefix}-http-to-https-redirect"
  
  items {
    action = "REDIRECT"
    conditions {
      attribute_name  = "PATH"
      attribute_value = "/"
      operator        = "PREFIX_MATCH"
    }
    redirect_uri {
      protocol = "HTTPS"
      port     = 443
      host     = "{host}"
      path     = "{path}"
      query    = "{query}"
    }
    response_code = var.redirect_response_code
  }
}

# Create HTTP listener (port 80) with redirect to HTTPS
resource "oci_load_balancer_listener" "http_listener" {
  load_balancer_id         = oci_load_balancer_load_balancer.lb.id
  name                     = "${var.name_prefix}-http-listener"
  default_backend_set_name = oci_load_balancer_backend_set.tomcat_backend_set.name
  port                     = 80
  protocol                 = "HTTP"
  
  rule_set_names = [oci_load_balancer_rule_set.http_to_https_redirect.name]
  
  connection_configuration {
    idle_timeout_in_seconds = var.connection_idle_timeout
  }
}

# Create HTTPS listener (port 443) using existing certificate OCID
resource "oci_load_balancer_listener" "https_listener" {
  load_balancer_id         = oci_load_balancer_load_balancer.lb.id
  name                     = "${var.name_prefix}-https-listener"
  default_backend_set_name = oci_load_balancer_backend_set.tomcat_backend_set.name
  port                     = 443
  protocol                 = "HTTP"
  
  ssl_configuration {
    certificate_ids         = [var.certificate_ocid]
    verify_peer_certificate = var.ssl_verify_peer_certificate
    verify_depth           = var.ssl_verify_depth
    
    dynamic "trusted_certificate_authority_ids" {
      for_each = var.trusted_ca_ids != null ? [var.trusted_ca_ids] : []
      content {
        trusted_certificate_authority_ids = trusted_certificate_authority_ids.value
      }
    }
  }
  
  connection_configuration {
    idle_timeout_in_seconds = var.connection_idle_timeout
  }
}