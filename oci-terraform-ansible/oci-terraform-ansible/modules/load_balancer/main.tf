# Load Balancer Module - Creates a load balancer for Tomcat instances

# Create a load balancer
resource "oci_load_balancer_load_balancer" "lb" {
  compartment_id             = var.compartment_id
  display_name               = "${var.name_prefix}-tomcat-lb"
  shape                      = var.lb_shape
  subnet_ids                 = var.subnet_ids
  is_private                 = var.is_private
  network_security_group_ids = var.nsg_ids

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

# TEMPORARILY COMMENTED OUT - HTTP listener and rule set causing backend set conflicts
# These resources are missing from Terraform state and causing conflicts when trying to create them

# # Create a rule set for HTTP to HTTPS redirect
# resource "oci_load_balancer_rule_set" "http_to_https_redirect" {
#   load_balancer_id = oci_load_balancer_load_balancer.lb.id
#   name             = "${replace(var.name_prefix, "-", "_")}_http_to_https_redirect"
#   
#   items {
#     action = "REDIRECT"
#     conditions {
#       attribute_name  = "PATH"
#       attribute_value = "/"
#       operator        = "PREFIX_MATCH"
#     }
#     redirect_uri {
#       protocol = "HTTPS"
#       port     = 443
#       host     = "{host}"
#       path     = "{path}"
#       query    = "{query}"
#     }
#     response_code = var.redirect_response_code
#   }
# }

# # Create HTTP listener (port 80) with redirect to HTTPS
# resource "oci_load_balancer_listener" "http_listener" {
#   load_balancer_id         = oci_load_balancer_load_balancer.lb.id
#   name                     = "${replace(var.name_prefix, "-", "_")}_http_listener"
#   default_backend_set_name = oci_load_balancer_backend_set.tomcat_backend_set.name
#   port                     = 80
#   protocol                 = "HTTP"
#   
#   rule_set_names = [oci_load_balancer_rule_set.http_to_https_redirect.name]
#   
#   connection_configuration {
#     idle_timeout_in_seconds = var.connection_idle_timeout
#   }
# }

# Create HTTPS listener (port 443) using existing certificate OCID
resource "oci_load_balancer_listener" "https_listener" {
  load_balancer_id         = oci_load_balancer_load_balancer.lb.id
  name                     = "${replace(var.name_prefix, "-", "_")}_https_listener"
  default_backend_set_name = oci_load_balancer_backend_set.tomcat_backend_set.name
  port                     = 443
  protocol                 = "HTTP"
  
  ssl_configuration {
    certificate_ids                    = [var.certificate_ocid]
    verify_peer_certificate           = var.ssl_verify_peer_certificate
    verify_depth                      = var.ssl_verify_depth
    trusted_certificate_authority_ids = var.trusted_ca_ids
  }
  
  connection_configuration {
    idle_timeout_in_seconds = var.connection_idle_timeout
  }
}

# Web Application Firewall Policy
resource "oci_waf_web_app_firewall_policy" "tomcat_waf_policy" {
  count          = var.enable_waf ? 1 : 0
  compartment_id = var.compartment_id
  display_name   = "${var.name_prefix}-tomcat-waf-policy"
  
  # Actions - Define what to do when rules match
  actions {
    name = "ALLOW_MARINE_DATA"
    type = "ALLOW"
  }
  
  actions {
    name = "BLOCK_DEFAULT"
    type = "RETURN_HTTP_RESPONSE"
    code = var.waf_block_response_code
    headers {
      name  = "Content-Type"
      value = "text/plain"
    }
    body {
      type = "STATIC_TEXT"
      text = var.waf_block_response_message
    }
  }
  
  # Request Access Control Rules
  request_access_control {
    default_action_name = "BLOCK_DEFAULT"
    
    # Rule to allow access to marine data register path
    rules {
      name                = "allow-marine-data-register"
      type                = "ACCESS_CONTROL"
      action_name         = "ALLOW_MARINE_DATA"
      condition_language  = "JMESPATH"
      condition           = "i_starts_with(http.request.url.path, '/ords/r/marinedataregister')"
    }
    
    # Rule to allow health checks to root path
    rules {
      name                = "allow-health-checks"
      type                = "ACCESS_CONTROL"
      action_name         = "ALLOW_MARINE_DATA"
      condition_language  = "JMESPATH"
      condition           = "http.request.url.path == '/'"
    }
  }
  
  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

# Web Application Firewall - Associate with Load Balancer
resource "oci_waf_web_app_firewall" "tomcat_waf" {
  count                      = var.enable_waf ? 1 : 0
  compartment_id             = var.compartment_id
  backend_type              = "LOAD_BALANCER"
  load_balancer_id          = oci_load_balancer_load_balancer.lb.id
  web_app_firewall_policy_id = oci_waf_web_app_firewall_policy.tomcat_waf_policy[0].id
  display_name              = "${var.name_prefix}-tomcat-waf"
  
  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
  
  depends_on = [
    oci_load_balancer_load_balancer.lb,
    oci_waf_web_app_firewall_policy.tomcat_waf_policy
  ]
}