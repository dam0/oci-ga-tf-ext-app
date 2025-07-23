# WAF Module - Creates a Web Application Firewall policy for the load balancer

# Create a WAF policy that blocks all traffic by default and allows specific paths
resource "oci_waf_web_app_firewall_policy" "waf_policy" {
  compartment_id = var.compartment_id
  display_name   = "${var.name_prefix}-${var.waf_display_name}"
  
  # Block all traffic by default
  actions {
    name = "DEFAULT_ACTION"
    type = "RETURN_HTTP_RESPONSE"
    
    code = 403
    headers {
      name  = "Content-Type"
      value = "text/plain"
    }
    body {
      text = "Access Denied"
      type = "STATIC_TEXT"
    }
  }
  
  # Create a rule to allow specific paths
  request_access_control {
    default_action_name = "DEFAULT_ACTION"
    
    # Rule to allow specific paths
    rules {
      name               = "ALLOW_SPECIFIC_PATHS"
      condition_language = "JMESPATH"
      condition          = join(" || ", [for path in var.allowed_paths : "request.uri.startsWith('${path}')"])
      action_name        = "ALLOW"
      type               = "ACCESS_CONTROL"
    }
  }
  
  # Define the ALLOW action
  actions {
    name = "ALLOW"
    type = "ALLOW"
  }
}

# Create a WAF and associate it with the load balancer
resource "oci_waf_web_app_firewall" "load_balancer_waf" {
  compartment_id        = var.compartment_id
  web_app_firewall_policy_id = oci_waf_web_app_firewall_policy.waf_policy.id
  display_name          = "${var.name_prefix}-lb-waf"
  
  backend_type = "LOAD_BALANCER"
  load_balancer_id = var.load_balancer_id
}